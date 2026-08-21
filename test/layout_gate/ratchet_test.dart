@Tags(['layout-gate'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'incident.dart';
import 'ratchet.dart';

/// The ratchet's oracle (#1341).
///
/// Tagged `layout-gate` and **not** `overflow`: that second tag is the
/// pre-commit selector for the four sweeps, and a suite that pumps no cells does
/// not belong in it — the same line `dart_test.yaml` draws for the probe
/// self-tests (`overflow_probe_test.dart`, `overflow_baseline_test.dart`), which
/// every sweep's verdict also rests on.
///
/// The whole point of #1341 splitting the ratchet out of the card port is that
/// these cases need no sweep: the allowlist is now a pure function of a JSON
/// document and a list of incidents, so a dead entry can be *proved* to be
/// reported in milliseconds instead of inferred from a 1,898-cell run.
void main() {
  group('loading', () {
    test('the committed fixture parses, and its allowlist is empty', () {
      // Deliberately reads the real file rather than a literal: the claim every
      // ticket in this epic leans on is that *the committed bytes* hold no
      // exemptions ("zero tolerance is already fact"), and a copy of them in
      // this test would keep passing after someone added an entry. It also
      // means the fixture's schema is validated on every gate run, not only
      // when a sweep happens to read it.
      final ratchet = OverflowRatchet.fromFixture();
      expect(ratchet.isEmpty, isTrue);
      expect(ratchet.entryCount, 0);
      expect(ratchet.isAllowlisted('lib/page/anything.dart:1', 'en'), isFalse);
      // And the bytes themselves, so a re-key that quietly widened the schema
      // cannot pass by writing a second empty map under a new name.
      final raw =
          jsonDecode(File(kKnownOverflowsFixturePath).readAsStringSync())
              as Map<String, Object?>;
      expect(raw.keys.toSet(), {'tracking', 'allowlist'});
    });

    test('an empty allowlist exempts nothing at all', () {
      final ratchet = OverflowRatchet.fromJsonString('{}');
      expect(ratchet.isEmpty, isTrue);
      expect(
        ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'en'),
        hasLength(1),
        reason: 'nothing is exempt, so the incident blocks the cell',
      );
    });

    test('a site key with a locale list loads', () {
      final ratchet = OverflowRatchet.fromJson({
        'tracking': {'lib/x.dart:9': 'legend fix #1145'},
        'allowlist': {
          'lib/x.dart:9': ['de', 'fi'],
          'ui_kit_library/lib/src/y.dart:12': ['*'],
        },
      });
      expect(ratchet.entryCount, 2);
      expect(ratchet.isAllowlisted('lib/x.dart:9', 'de'), isTrue);
      expect(ratchet.isAllowlisted('lib/x.dart:9', 'en'), isFalse);
      expect(
        ratchet.isAllowlisted('ui_kit_library/lib/src/y.dart:12', 'en'),
        isTrue,
        reason: '"*" means every locale',
      );
    });

    test('a legacy coordinate-shaped allowlist key is rejected, not ignored',
        () {
      // The failure mode this exists to prevent: a `card|width|tab` key simply
      // does not match any site, so a silent reader would answer "not
      // allowlisted" for every cell and the stale exemption would be invisible
      // — while the dead-entry sweep, which only looks at keys it understands,
      // would never mention it either.
      expect(
        () => OverflowRatchet.fromJson({
          'allowlist': {
            'lan_info|min|0': ['*'],
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('lan_info|min|0'), contains('file:line')),
        )),
      );
    });

    test('a legacy key with an @profile suffix is rejected too', () {
      expect(
        () => OverflowRatchet.fromJson({
          'allowlist': {
            'wifi_performance|min|2@triband': ['tr'],
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>()
            .having((e) => e.message, 'message', contains('@triband'))),
      );
    });

    test('an @ inside a real path is a site, not a coordinate', () {
      // The `@profile` suffix above makes `@` look like a coordinate marker, and
      // it is not: it is legal in a directory name, and the reliable tell for
      // the old grammar is the pipe. A key that is a genuine path has to load.
      final ratchet = OverflowRatchet.fromJson({
        'allowlist': {
          'lib/page/a@b/foo_card.dart:47': ['de'],
        },
      });
      expect(
          ratchet.isAllowlisted('lib/page/a@b/foo_card.dart:47', 'de'), isTrue);
    });

    test('a key with whitespace is rejected, and told why', () {
      // A hand-indented JSON key reads as correct and joins to nothing, so the
      // message names the character rather than blaming the author — and it must
      // not accuse the key of being a leftover coordinate.
      expect(
        () => OverflowRatchet.fromJson({
          'allowlist': {
            'lib/page/foo card.dart:47': ['de'],
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('whitespace'), isNot(contains('pre-#1341'))),
        )),
      );
    });

    test('an absolute key is rejected as unmatchable, not as mistyped', () {
      // The mistake an operator makes by copying a path out of a failure
      // message. Since #1356 an incident whose path stayed absolute has no site
      // at all (`_isMachineIndependentPath`), so this key cannot match an
      // incident on the machine that wrote it either — which is what the message
      // has to say. Both spellings: POSIX, and the Windows drive that reaches
      // the ratchet as `C:/…`.
      for (final key in [
        '/Users/dev/work/app/lib/foo_card.dart:47',
        'C:/src/app/lib/foo_card.dart:47',
      ]) {
        expect(
          () => OverflowRatchet.fromJson({
            'allowlist': {
              key: ['de'],
            },
          }),
          throwsA(isA<OverflowRatchetFormatException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('absolute'),
              contains('#1356'),
              isNot(contains('pre-#1341')),
            ),
          )),
          reason: '"$key" carries the machine it was captured on',
        );
      }
    });

    test('a bare card id in "tracking" is rejected', () {
      // `tracking` was card-keyed until #1341. A leftover card-id note is the
      // same hazard as a leftover coordinate key: it looks like documentation
      // and points at nothing.
      expect(
        () => OverflowRatchet.fromJson({
          'tracking': {'network_health': 'legend fix #1145'},
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('network_health'), contains('tracking')),
        )),
      );
    });

    test('a path with no line, or a line of 0, is rejected', () {
      for (final key in ['lib/x.dart', 'lib/x.dart:0', 'lib/x.dart:abc']) {
        expect(
          () => OverflowRatchet.fromJson({
            'allowlist': {
              key: ['de'],
            },
          }),
          throwsA(isA<OverflowRatchetFormatException>()),
          reason: '"$key" is not a file:line site',
        );
      }
    });

    test('an unknown top-level key is rejected', () {
      // A typo'd `allow_list` would leave the real allowlist empty, which reads
      // as zero tolerance — safe for the gate, silent about the entries the
      // author believed they had written.
      expect(
        () => OverflowRatchet.fromJson({'allow_list': <String, Object?>{}}),
        throwsA(isA<OverflowRatchetFormatException>()
            .having((e) => e.message, 'message', contains('allow_list'))),
      );
    });

    test('an empty locale list is rejected', () {
      expect(
        () => OverflowRatchet.fromJson({
          'allowlist': {'lib/x.dart:9': <String>[]},
        }),
        throwsA(isA<OverflowRatchetFormatException>()),
        reason: 'an entry that exempts no locale exempts nothing, so it can '
            'only ever read as an exemption that is not one',
      );
    });

    test('"*" mixed with explicit tags is rejected', () {
      expect(
        () => OverflowRatchet.fromJson({
          'allowlist': {
            'lib/x.dart:9': ['*', 'de'],
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>()
            .having((e) => e.message, 'message', contains('*'))),
      );
    });

    test('a non-string locale tag is rejected', () {
      expect(
        () => OverflowRatchet.fromJson({
          'allowlist': {
            'lib/x.dart:9': [1],
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>()),
      );
    });

    test('unreadable JSON is rejected as a ratchet error', () {
      expect(
        () => OverflowRatchet.fromJsonString('{not json'),
        throwsA(isA<OverflowRatchetFormatException>()),
      );
    });

    test('a missing fixture fails closed rather than throwing', () {
      final ratchet = OverflowRatchet.fromFixture('test/fixtures/_absent.json');
      expect(ratchet.isEmpty, isTrue);
      expect(ratchet.isAllowlisted('lib/x.dart:9', 'de'), isFalse);
      expect(ratchet.deadEntryFailure(localesCovered: const {'en'}), isNull,
          reason: 'nothing is exempt, so nothing can be a dead exemption');
    });
  });

  group('tracking notes', () {
    final ratchet = OverflowRatchet.fromJson({
      'tracking': {'lib/x.dart:9': 'legend fix #1145'},
      'allowlist': {
        'lib/x.dart:9': ['de'],
      },
    });

    test('a note is looked up by site', () {
      expect(ratchet.trackingNote('lib/x.dart:9'), 'legend fix #1145');
    });

    test('an unnoted site and a null site both read as untracked', () {
      expect(ratchet.trackingNote('lib/other.dart:1'), kUntrackedNote);
      expect(ratchet.trackingNote(null), kUntrackedNote);
    });
  });

  group('consulting', () {
    test('an allowlisted location passes', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      expect(
        ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'de'),
        isEmpty,
        reason: 'no blocking incident means the cell is tolerated',
      );
    });

    test('a non-allowlisted overflow fails', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      final blocking = ratchet.consultCell(
        [_incident(site: 'lib/other.dart:3')],
        'de',
      );
      expect(blocking, hasLength(1));
      expect(blocking.single.site, 'lib/other.dart:3');
    });

    test('an allowlisted site in an unlisted locale fails', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      expect(
        ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'fi'),
        hasLength(1),
      );
    });

    test('one exempt plus one not blocks the cell, and names only the latter',
        () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      final blocking = ratchet.consultCell([
        _incident(site: 'lib/x.dart:9'),
        _incident(site: 'lib/y.dart:4'),
      ], 'de');
      expect(blocking.map((i) => i.site), ['lib/y.dart:4'],
          reason: 'the cell is only tolerated when *every* incident in it is '
              'exempt, and the message must point at the one that is not');
    });

    test('an incident with no resolvable location can never be exempted', () {
      // Deliberate consequence of the key choice, and the safe direction: an
      // unresolved location is not a key, so a `"*"` on every site in the
      // fixture still cannot cover it.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['*']
      });
      expect(ratchet.isAllowlisted(null, 'de'), isFalse);
      expect(
        ratchet.consultCell([_incident(site: null)], 'de'),
        hasLength(1),
      );
    });
  });

  group('dead entries', () {
    test('a dead entry is reported, with the site and how to remove it', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      final failure = ratchet.deadEntryFailure(localesCovered: const {'de'});
      expect(
        failure,
        allOf(
          isNotNull,
          contains('lib/x.dart:9'),
          contains(kKnownOverflowsFixturePath),
        ),
      );
    });

    test('a live entry is not reported', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'de');
      expect(ratchet.deadEntryFailure(localesCovered: const {'de'}), isNull);
    });

    test('a site that overflows in one cell only stays live for the whole run',
        () {
      // The reason the verdict cannot be taken per cell, stated as a test: this
      // is one entry, one clean cell and one overflowing cell, and the old
      // per-cell check would have failed the clean one as a dead exemption.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      ratchet.consultCell(const [], 'de'); // a clean cell
      ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'de');
      ratchet.consultCell(const [], 'de'); // another clean cell
      expect(ratchet.deadEntryFailure(localesCovered: const {'de'}), isNull);
    });

    test('a listed locale nothing overflowed in is reported on its own', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de', 'fi']
      });
      ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'de');
      final failure =
          ratchet.deadEntryFailure(localesCovered: const {'de', 'fi'});
      expect(failure, isNotNull);
      expect(failure, contains('"fi"'));
      expect(failure, isNot(contains('"de"')),
          reason: 'de still overflows there, so only fi is dead');
    });

    test('an over-broad "*" is reported with the tags that did overflow', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['*']
      });
      ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'de');
      final failure = ratchet.deadEntryFailure(
        localesCovered: const {'de', 'fi', 'en'},
      );
      expect(failure, isNotNull);
      expect(failure, contains('lib/x.dart:9'));
      expect(failure, contains('de'),
          reason: 'the replacement list the operator has to write');
    });

    test('a "*" seen in every covered locale is live', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['*']
      });
      for (final tag in ['de', 'fi']) {
        ratchet.consultCell([_incident(site: 'lib/x.dart:9')], tag);
      }
      expect(
        ratchet.deadEntryFailure(localesCovered: const {'de', 'fi'}),
        isNull,
      );
    });

    test('a filtered run reports no dead entries at all', () {
      // The guard that makes the global verdict safe: a run that measured a
      // subset cannot distinguish "fixed" from "not measured", and reporting a
      // live entry as dead would send someone to delete a real exemption.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      expect(
        ratchet.deadEntryFailure(
          localesCovered: const {'de'},
          coverageGaps: const ['--dart-define=LOCALE=de limited the run'],
        ),
        isNull,
      );
    });

    test('a filtered run says so, but only when something is exempt', () {
      const gaps = ['--dart-define=LOCALE=de limited the run'];
      final withEntries = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      expect(withEntries.coverageSkipNote(gaps),
          allOf(isNotNull, contains('LOCALE=de')));
      expect(withEntries.coverageSkipNote(const []), isNull);
      expect(
        OverflowRatchet.fromJson({}).coverageSkipNote(gaps),
        isNull,
        reason: 'an empty allowlist has no closing direction to skip, so a '
            'green filtered run stays silent',
      );
    });

    test('recording an unresolved location creates no liveness', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      });
      ratchet.consultCell([_incident(site: null)], 'de');
      expect(ratchet.deadEntryFailure(localesCovered: const {'de'}), isNotNull,
          reason: 'a null site cannot keep any entry alive');
    });
  });
}

/// A ratchet holding [allowlist], with a tracking note for every entry.
///
/// Named after the real fixture, because every message the ratchet produces
/// quotes its own [OverflowRatchet.source] — an operator has to be told which
/// file to edit, and a test that accepted `<in-memory allowlist>` there would
/// not notice that going missing.
OverflowRatchet _ratchetFor(Map<String, List<String>> allowlist) =>
    OverflowRatchet.fromJson(
      {
        'tracking': {for (final site in allowlist.keys) site: 'tracked #0000'},
        'allowlist': allowlist,
      },
      source: kKnownOverflowsFixturePath,
    );

/// A significant incident at [site], or one whose location did not resolve.
OverflowIncident _incident({required String? site}) {
  final parts = site?.split(':');
  return OverflowIncident(
    pixels: 41.0,
    side: 'right',
    message: 'A RenderFlex overflowed by 41 pixels on the right.',
    file: parts?.first,
    line: parts == null ? null : int.parse(parts.last),
  );
}
