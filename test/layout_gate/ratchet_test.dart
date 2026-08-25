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
/// pre-commit selector for the five sweeps, and a suite that pumps no cells does
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
      expect(
        ratchet.isAllowlisted('lib/page/anything.dart:1', 'en', pixels: 41.0),
        isFalse,
      );
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

    test('a site key with a locale list and a ceiling loads', () {
      final ratchet = OverflowRatchet.fromJson({
        'tracking': {
          'lib/x.dart:9': 'legend fix #1145',
          'ui_kit_library/lib/src/y.dart:12': 'upstream #1146',
        },
        'allowlist': {
          'lib/x.dart:9': {
            'locales': ['de', 'fi'],
            'maxOverflowPx': 41,
          },
          'ui_kit_library/lib/src/y.dart:12': {
            'locales': ['*'],
            'maxOverflowPx': 25.6,
          },
        },
      });
      expect(ratchet.entryCount, 2);
      expect(ratchet.isAllowlisted('lib/x.dart:9', 'de', pixels: 41), isTrue);
      expect(ratchet.isAllowlisted('lib/x.dart:9', 'en', pixels: 41), isFalse);
      expect(
        ratchet.isAllowlisted('ui_kit_library/lib/src/y.dart:12', 'en',
            pixels: 25.6),
        isTrue,
        reason: '"*" means every locale',
      );
      expect(
          ratchet
              .exemptionFor('ui_kit_library/lib/src/y.dart:12')!
              .maxOverflowPx,
          25.6,
          reason:
              'an integral JSON number and a fractional one both read as px');
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
            'lan_info|min|0': {
              'locales': ['*'],
              'maxOverflowPx': 41
            },
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
            'wifi_performance|min|2@triband': {
              'locales': ['tr'],
              'maxOverflowPx': 41
            },
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
        'tracking': {'lib/page/a@b/foo_card.dart:47': 'tracked #0000'},
        'allowlist': {
          'lib/page/a@b/foo_card.dart:47': {
            'locales': ['de'],
            'maxOverflowPx': 41
          },
        },
      });
      expect(
        ratchet.isAllowlisted('lib/page/a@b/foo_card.dart:47', 'de',
            pixels: 41.0),
        isTrue,
      );
    });

    test('a key with whitespace is rejected, and told why', () {
      // A hand-indented JSON key reads as correct and joins to nothing, so the
      // message names the character rather than blaming the author — and it must
      // not accuse the key of being a leftover coordinate.
      expect(
        () => OverflowRatchet.fromJson({
          'allowlist': {
            'lib/page/foo card.dart:47': {
              'locales': ['de'],
              'maxOverflowPx': 41
            },
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
              key: {
                'locales': ['de'],
                'maxOverflowPx': 41
              },
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

    test('every key an incident can offer is a key this fixture accepts', () {
      // The two definitions of "absolute" have to be the same definition. This
      // side is `_absolutePattern` (`^([/\\]|[A-Za-z]:)`); the other is
      // `_isMachineIndependentPath` in `incident.dart`, which withholds
      // `OverflowIncident.site` for exactly the paths this rejects. They
      // disagreed on one input: a leading backslash, which the incident admitted
      // and this refused. The gate's failure message would then tell the operator
      // to paste `"\src\lib\page\x.dart:12"` into `known_overflows.json` and the
      // fixture would refuse the value the gate had just handed out, with nothing
      // on either side explaining the contradiction.
      //
      // Asserted as a round trip rather than by comparing the two regexes,
      // because the contract is about the keys that actually flow between them,
      // not about how each spells its test.
      const absolute = [
        '/src/lib/page/x.dart',
        r'\src\lib\page\x.dart',
        'C:/src/lib/page/x.dart',
        r'C:\src\lib\page\x.dart',
        '/C:/src/lib/page/x.dart',
      ];
      for (final path in absolute) {
        expect(overflowSiteKey(path, 12), isNull,
            reason: '"$path" must never become a key at all');
      }

      const relative = [
        'lib/page/x.dart',
        'packages/ui_kit_library/lib/x.dart'
      ];
      for (final path in relative) {
        final key = overflowSiteKey(path, 12);
        expect(key, isNotNull);
        expect(
          () => OverflowRatchet.fromJson({
            // Both sections, because an exemption without its note is a separate
            // (and correct) rejection — the property under test is only that the
            // *key* is admissible.
            'tracking': {key!: 'deferred by #1369'},
            'allowlist': {
              key: {
                'locales': ['de'],
                'maxOverflowPx': 41,
              },
            },
          }),
          returnsNormally,
          reason: 'the gate told the operator to paste "$key"',
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

    test('a tracking note with no allowlist entry is rejected', () {
      // The dead entry one level up, and the one shape no other check can see: a
      // note is never consulted unless something exempted the site, so this
      // survives a whole green run while telling every reader of the fixture
      // that the gate is deferring a defect it is not.
      expect(
        () => OverflowRatchet.fromJson({
          'tracking': {
            'lib/x.dart:9': 'legend fix #1145',
            'lib/gone.dart:3': 'fixed in #1200, note left behind',
          },
          'allowlist': {
            'lib/x.dart:9': {
              'locales': ['de'],
              'maxOverflowPx': 41
            },
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('lib/gone.dart:3'),
            contains('Delete the note'),
            isNot(contains('lib/x.dart:9')),
          ),
        )),
        reason: 'only the unpaired site is named — the paired one is not the '
            'operator\'s problem',
      );
    });

    test('an allowlist entry with no tracking note is rejected', () {
      // The other direction: it loads today and prints kUntrackedNote, which
      // leaves nobody able to tell deferred debt from an accidentally committed
      // exemption. Rejecting it is why that constant is not a ticket number.
      expect(
        () => OverflowRatchet.fromJson({
          'tracking': {'lib/x.dart:9': 'legend fix #1145'},
          'allowlist': {
            'lib/x.dart:9': {
              'locales': ['de'],
              'maxOverflowPx': 41
            },
            'lib/new.dart:7': {
              'locales': ['*'],
              'maxOverflowPx': 41
            },
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('lib/new.dart:7'), contains('"tracking"')),
        )),
      );
    });

    test('a malformed key is diagnosed as malformed, not as unpaired', () {
      // Ordering, as a test: the symmetry check runs last precisely so an
      // operator holding a pre-#1341 coordinate is told *that*, rather than
      // being sent to add a tracking note for a key that can never match.
      expect(
        () => OverflowRatchet.fromJson({
          'allowlist': {
            'lan_info|min|0': {
              'locales': ['*'],
              'maxOverflowPx': 41
            },
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('file:line'), isNot(contains('same sites'))),
        )),
      );
    });

    test('a path with no line, or a line of 0, is rejected', () {
      for (final key in ['lib/x.dart', 'lib/x.dart:0', 'lib/x.dart:abc']) {
        expect(
          () => OverflowRatchet.fromJson({
            'allowlist': {
              key: {
                'locales': ['de'],
                'maxOverflowPx': 41
              },
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
          'allowlist': {
            'lib/x.dart:9': {'locales': <String>[], 'maxOverflowPx': 41},
          },
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
            'lib/x.dart:9': {
              'locales': ['*', 'de'],
              'maxOverflowPx': 41
            },
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
            'lib/x.dart:9': {
              'locales': [1],
              'maxOverflowPx': 41
            },
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>()),
      );
    });

    test('a bare locale list is rejected, and the object is spelled out', () {
      // The pre-#1356 value shape. Every closed ticket in this epic quotes it, so
      // the message names it as the old shape and prints the entry to write —
      // with the operator's own tags already in it.
      expect(
        () => OverflowRatchet.fromJson({
          'tracking': {'lib/x.dart:9': 'legend fix #1145'},
          'allowlist': {
            'lib/x.dart:9': ['de', 'fi'],
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('pre-#1356'),
            contains('"locales": ["de","fi"]'),
            contains('maxOverflowPx'),
          ),
        )),
      );
    });

    test('an entry with no ceiling is rejected', () {
      expect(
        () => OverflowRatchet.fromJson({
          'tracking': {'lib/x.dart:9': 'legend fix #1145'},
          'allowlist': {
            'lib/x.dart:9': {
              'locales': ['de'],
            },
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('maxOverflowPx'), contains('any size')),
        )),
        reason: 'a site key covers every cell that reaches the line, so an '
            'entry with no magnitude is unbounded in the direction that matters',
      );
    });

    test('a misspelled entry field is named, not ignored', () {
      // The silent version of the case above: `maxPx` would leave the entry
      // looking bounded in the fixture and unbounded to the gate.
      expect(
        () => OverflowRatchet.fromJson({
          'tracking': {'lib/x.dart:9': 'legend fix #1145'},
          'allowlist': {
            'lib/x.dart:9': {
              'locales': ['de'],
              'maxPx': 41,
            },
          },
        }),
        throwsA(isA<OverflowRatchetFormatException>().having(
          (e) => e.message,
          'message',
          allOf(contains('"maxPx"'), contains('reads as bounded')),
        )),
      );
    });

    test('a ceiling that is not a finite, positive number is rejected', () {
      for (final (ceiling, expected) in <(Object, String)>[
        ('41', 'non-numeric'),
        (double.infinity, 'infinite'),
        (double.nan, 'infinite'),
        (0, 'exempts nothing'),
        (-41, 'exempts nothing'),
      ]) {
        expect(
          () => OverflowRatchet.fromJson({
            'tracking': {'lib/x.dart:9': 'legend fix #1145'},
            'allowlist': {
              'lib/x.dart:9': {
                'locales': ['de'],
                'maxOverflowPx': ceiling,
              },
            },
          }),
          throwsA(isA<OverflowRatchetFormatException>()
              .having((e) => e.message, 'message', contains(expected))),
          reason: 'a ceiling of $ceiling is not a magnitude an incident can be '
              'measured against',
        );
      }
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
      expect(
        ratchet.isAllowlisted('lib/x.dart:9', 'de', pixels: 41.0),
        isFalse,
      );
      expect(ratchet.deadEntryFailure(localesCovered: const {'en'}), isNull,
          reason: 'nothing is exempt, so nothing can be a dead exemption');
    });
  });

  group('tracking notes', () {
    final ratchet = OverflowRatchet.fromJson({
      'tracking': {'lib/x.dart:9': 'legend fix #1145'},
      'allowlist': {
        'lib/x.dart:9': {
          'locales': ['de'],
          'maxOverflowPx': 41
        },
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

    test('an exempt site overflowing past its ceiling blocks the cell', () {
      // #1356's finding, as a test: one `file:line` is rendered by every cell
      // that reaches the line, so the entry written for +26px would otherwise
      // absorb a +400px clipped row somewhere else entirely and report it as this
      // ticket's known debt.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      }, maxOverflowPx: 26);
      final blocking = ratchet.consultCell(
        [_incident(site: 'lib/x.dart:9', pixels: 400)],
        'de',
      );
      expect(blocking, hasLength(1));
      expect(
        ratchet.ceilingBreaches(blocking, 'de').single.pixels,
        400,
        reason: 'classified as a breach, not as an unlisted site — the entry '
            'already names "de", so "add the tag" would be wrong advice',
      );
    });

    test('an unlisted site is not classified as a ceiling breach', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      }, maxOverflowPx: 26);
      final blocking = ratchet.consultCell([
        _incident(site: 'lib/other.dart:3', pixels: 400),
        _incident(site: null, pixels: 400),
        _incident(site: 'lib/x.dart:9', pixels: 400),
      ], 'de');
      expect(blocking, hasLength(3));
      expect(
        ratchet.ceilingBreaches(blocking, 'de').map((i) => i.site),
        ['lib/x.dart:9'],
        reason:
            'a site nothing exempts and an incident with no site at all both '
            'need an entry, not a larger number in one',
      );
    });

    test('an allowlisted site in an unlisted locale is not a breach either',
        () {
      // Both bounds fail at once, and the classification has to pick the one the
      // operator can act on: "de" is not listed, so the locale list is the edit.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['fi']
      }, maxOverflowPx: 26);
      final blocking = ratchet.consultCell(
        [_incident(site: 'lib/x.dart:9', pixels: 400)],
        'de',
      );
      expect(blocking, hasLength(1));
      expect(ratchet.ceilingBreaches(blocking, 'de'), isEmpty);
    });

    test('the shaping tolerance is allowed on top of the ceiling, and no more',
        () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      }, maxOverflowPx: 26);
      expect(
        ratchet.consultCell(
          [_incident(site: 'lib/x.dart:9', pixels: 26 + kOverflowTolerancePx)],
          'de',
        ),
        isEmpty,
        reason: 'the same noise floor the rest of the gate uses: a sub-pixel '
            'rasterizer difference must not fail an exemption written at the '
            'magnitude that was measured',
      );
      expect(
        ratchet.consultCell(
          [
            _incident(
                site: 'lib/x.dart:9', pixels: 26 + kOverflowTolerancePx + 0.1)
          ],
          'de',
        ),
        hasLength(1),
        reason: 'past the floor it is a measurable regression',
      );
    });

    test('an unparseable overflow is never exempt, whatever the ceiling', () {
      // `unparseablePixels` is infinity precisely so it survives every threshold,
      // and no valid entry can name an infinite ceiling — so the incident whose
      // magnitude nobody knows always blocks.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['*']
      }, maxOverflowPx: 4000);
      expect(
        ratchet.consultCell([
          _incident(
              site: 'lib/x.dart:9', pixels: OverflowIncident.unparseablePixels)
        ], 'de'),
        hasLength(1),
      );
    });

    test('an incident with no resolvable location can never be exempted', () {
      // Deliberate consequence of the key choice, and the safe direction: an
      // unresolved location is not a key, so a `"*"` on every site in the
      // fixture still cannot cover it.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['*']
      });
      expect(ratchet.isAllowlisted(null, 'de', pixels: 41.0), isFalse);
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

    test(
        'an over-broad "*" is caught by which locales are missing, not how many',
        () {
      // The two sets are not one vocabulary: `localesCovered` is what the sweep
      // declares, `_observed` is what it was handed. Counting made an
      // undeclared observation cancel out a covered locale that never
      // overflowed, so this entry — structural in name, text-dependent in fact —
      // passed on arithmetic alone.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['*']
      });
      ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'de');
      ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'zz');
      final failure =
          ratchet.deadEntryFailure(localesCovered: const {'de', 'fi'});
      expect(failure, isNotNull,
          reason: '2 observed tags for 2 covered locales, and yet nothing ever '
              'overflowed in fi');
      expect(failure, contains('"fi"'));
      expect(failure, contains('Replace "*" with: de'),
          reason: 'the replacement quotes only covered tags — a listed tag the '
              'sweep does not run is rejected by the check above it');
    });

    test('a "*" observed only outside the covered set names the contradiction',
        () {
      // Reachable only from a sweep whose locale list and `localesCovered`
      // disagree, which is a bug in the sweep rather than in the fixture — so the
      // message must not hand over an empty replacement list and call it advice.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['*']
      });
      ratchet.consultCell([_incident(site: 'lib/x.dart:9')], 'zz');
      final failure =
          ratchet.deadEntryFailure(localesCovered: const {'de', 'fi'});
      expect(
        failure,
        allOf(
          isNotNull,
          contains('"zz"'),
          contains('disagree'),
          isNot(contains('Replace "*" with')),
        ),
      );
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

    test('a ceiling the defect no longer reaches is reported, with the number',
        () {
      // The ratchet's own metaphor applied to the magnitude: a partial fix that
      // leaves the allowance where it was has pre-approved the regression back to
      // it, and nothing else in the run would ever mention that.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      }, maxOverflowPx: 400);
      ratchet.consultCell([_incident(site: 'lib/x.dart:9', pixels: 26)], 'de');
      final failure = ratchet.deadEntryFailure(localesCovered: const {'de'});
      expect(
        failure,
        allOf(
          isNotNull,
          contains('400.0px'),
          contains('26.0px'),
          contains('"maxOverflowPx" to 26.0'),
        ),
        reason: 'the entry stays live as an exemption, so the complaint has to '
            'be about the number, and it has to hand over the number to write',
      );
    });

    test('a ceiling within the tolerance of the worst overflow is live', () {
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      }, maxOverflowPx: 26);
      ratchet.consultCell(
        [_incident(site: 'lib/x.dart:9', pixels: 26 - kOverflowTolerancePx)],
        'de',
      );
      expect(
        ratchet.deadEntryFailure(localesCovered: const {'de'}),
        isNull,
        reason: 'the same slack the check itself grants, or every run at the '
            'noise floor would demand a fixture edit',
      );
    });

    test('a loose ceiling is reported even where the run failed on the locale',
        () {
      // The two directions are independent, and a run that already failed still
      // has to state everything it learned: this locale is not listed *and* the
      // allowance is far above anything measured. (A breach cannot coexist with a
      // loose ceiling at one site by construction — breaching means the worst
      // measurement is above the allowance.)
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['fi']
      }, maxOverflowPx: 400);
      ratchet.consultCell([_incident(site: 'lib/x.dart:9', pixels: 26)], 'de');
      final failure =
          ratchet.deadEntryFailure(localesCovered: const {'de', 'fi'});
      expect(failure, contains('"maxOverflowPx" to 26.0'));
      expect(failure, contains('"fi"'),
          reason: 'the locale complaint is not swallowed by the ceiling one');
    });

    test('an unparseable measurement is not evidence a ceiling is too loose',
        () {
      // `unparseablePixels` is infinity, so it can never be *below* an allowance
      // and must never be read as "the defect shrank". The cell it came from
      // failed on the breach; the fixture is not asked to change.
      final ratchet = _ratchetFor({
        'lib/x.dart:9': ['de']
      }, maxOverflowPx: 400);
      ratchet.consultCell([
        _incident(
            site: 'lib/x.dart:9', pixels: OverflowIncident.unparseablePixels)
      ], 'de');
      expect(
        ratchet.deadEntryFailure(localesCovered: const {'de'}),
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

/// A ratchet exempting [allowlist]'s locales at each site, up to [maxOverflowPx],
/// with a tracking note for every entry.
///
/// Named after the real fixture, because every message the ratchet produces
/// quotes its own [OverflowRatchet.source] — an operator has to be told which
/// file to edit, and a test that accepted `<in-memory allowlist>` there would
/// not notice that going missing.
///
/// The default ceiling is [_incidentPx] exactly, so a case that is about locales
/// is not silently also about magnitude: every incident [_incident] builds sits
/// right on the allowance. Cases that *are* about magnitude pass their own.
OverflowRatchet _ratchetFor(
  Map<String, List<String>> allowlist, {
  double maxOverflowPx = _incidentPx,
}) =>
    OverflowRatchet.fromJson(
      {
        'tracking': {for (final site in allowlist.keys) site: 'tracked #0000'},
        'allowlist': {
          for (final entry in allowlist.entries)
            entry.key: {
              'locales': entry.value,
              'maxOverflowPx': maxOverflowPx,
            },
        },
      },
      source: kKnownOverflowsFixturePath,
    );

/// The magnitude [_incident] reports, and [_ratchetFor]'s default ceiling.
const double _incidentPx = 41.0;

/// A significant incident at [site], or one whose location did not resolve.
OverflowIncident _incident(
    {required String? site, double pixels = _incidentPx}) {
  final parts = site?.split(':');
  return OverflowIncident(
    pixels: pixels,
    side: 'right',
    message: 'A RenderFlex overflowed by $pixels pixels on the right.',
    file: parts?.first,
    line: parts == null ? null : int.parse(parts.last),
  );
}
