@Tags(['layout-gate'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Deliberately the *only* import: since #1338 the parser, the tolerance and the
// predicate live in `test/layout_gate/incident.dart`, and since #1340 the
// collector and the surface primitive live in `collector.dart` and `surface.dart`
// beside it — `overflow_probe.dart` is now a re-export shim and nothing else.
// Every symbol used below therefore doubles as proof that the old path still
// resolves it, which is what the ~22 untouched importers depend on.
import 'overflow_probe.dart';

/// Tests for the overflow gate's own measuring instrument (#1248).
///
/// ## Why this file exists
///
/// Every #1183 ticket's acceptance criterion is "the gate passes". That makes
/// [OverflowIncident] and [runWithOverflowCollection] the only witnesses the
/// whole epic has, and an instrument that under-reports cannot be caught by the
/// tests that use it: the gate goes green either because a card is clean or
/// because the probe stopped seeing it, and those two outcomes are
/// indistinguishable from the outside.
///
/// So the properties under test here are not "the probe reports overflows" —
/// every gate test already covers that by failing when a card breaks. They are
/// the three ways the probe can go **quiet**:
///
///   1. it swallows a `FlutterError` that was not an overflow, so a real error
///      raised during a pump never fails anything;
///   2. it reports a number that a `pixels > tolerance` filter discards, which
///      turns an overflow into silence rather than into a lower reading;
///   3. it leaves someone else's `FlutterError.onError` installed, so later
///      tests report into a dead handler.
///
/// ## The fourth property, added by #1338
///
/// The parser now also carries the incident's `file:line`, and it is not
/// decoration: it is the ratchet key that survives a layout being rearranged
/// where a coordinate key does not, and it is the column that joins golden CI's
/// advisory findings to this gate's verdicts. A fourth way to go quiet follows —
/// **the location silently stops resolving**, and every incident becomes
/// unjoinable while every existing assertion here stays green. Hence the
/// `source location` group below, and hence the real-overflow test that asserts
/// the file *and the line the `Row` was written on*: a hand-written dump alone
/// would keep passing after an SDK change to the block Flutter emits.
///
/// The reverse risk is the reason the location is allowed to be absent. A
/// diagnostic that throws or fails when it cannot resolve a path would turn the
/// instrument into a source of failures of its own — so an unresolvable dump
/// yields a null `file`, and the incident stays usable.
///
/// ## The fifth property, added by #1340
///
/// The instrument now also owns the **viewport it measures in**
/// (`test/layout_gate/surface.dart`), and that is a fifth way to go quiet, of the
/// worst kind: a width left installed by one test is still installed when the
/// next one pumps, so the next measurement is taken at a viewport nobody chose
/// and reports a clean layout for it. Before #1340 the chrome suite reset the
/// surface in a private teardown and the card path reset nothing at all, which is
/// why the `layout surface` group below spends most of its assertions on the
/// *restore* rather than on the set.
///
/// Those tests are **ordered and read as one story**: each one asserts on what
/// the test before it left behind, because "the surface was put back" is only
/// observable from the next test in the file. Running one of them alone fails on
/// the captured baseline, and that is the honest failure — there is nothing to
/// compare against.
///
/// ## Mutation ledger
///
/// Each fix is pinned by a test that was shown to fail with the fix reverted —
/// a silent-pass test guarding against silent passes would be self-defeating.
///
///   | mutation                                  | what failed                       |
///   |-------------------------------------------|-----------------------------------|
///   | predicate back to `contains('overflowed')` | rejects unrelated errors (1),     |
///   |                                            | forwards non-overflows (1)        |
///   | unparseable fallback back to `pixels: 0`   | unparseable survives tolerance (1)|
///   | `allMatches` + max back to `firstMatch`    | worst side of several (1)         |
///   | `finally` restore removed                  | restores handler when throwing (1)|
///   | location search not anchored on the widget | ignores a creator chain that      |
///   | block (#1338)                               | precedes the widget block (1)     |
///   | run-directory strip disabled (#1338)        | 7 source-location cases plus the  |
///   |                                             | real-overflow file:line (8)       |
///   | percent-decode guard removed (#1338)        | literal percent sign (1)          |
///   | `setSurfaceSize` dropped (#1340)            | sets all three properties (1)     |
///   | `physicalSize` dropped (#1340)              | sets all three properties, plus   |
///   |                                             | restored afterwards and           |
///   |                                             | collectOverflow (3)               |
///   | `devicePixelRatio` dropped (#1340)          | sets all three properties (1)     |
///   | restore never registered (#1340)            | restored afterwards, that restore |
///   |                                             | ran too, card path leaves nothing |
///   |                                             | behind (3)                        |
///   | `identical` dedupe removed, so every call   | restored exactly once (1)         |
///   | registers (#1340)                            |                                   |
///   | teardown stops clearing the marker (#1340)  | registered again by the next test |
///   |                                             | — caught by the second variant (1)|
///
/// The three "dropped" rows are why the primitive sets all three properties
/// rather than the one the sweeps happen to read: each is individually load-bearing
/// for some assertion in this file, so a later narrowing cannot pass here.
///
/// The real-message test is not in the ledger: it has no mutation in this repo
/// because the code it guards is Flutter's, not ours. It fails when an SDK
/// upgrade changes the wording out from under [isOverflowError].
void main() {
  /// A Flutter overflow report as the SDK writes it today
  /// (`debug_overflow_indicator.dart:261`: `A $runtimeType overflowed by
  /// $overflowText.`). Used where a test needs a specific pixel value or side
  /// combination that is awkward to provoke with a real widget; the shape itself
  /// is verified against a real overflow below.
  String reportOf(String overflowText) =>
      'A RenderFlex overflowed by $overflowText.';

  group('isOverflowError', () {
    test('accepts the SDK\'s overflow report', () {
      expect(isOverflowError(reportOf('41 pixels on the right')), isTrue);
      expect(
        isOverflowError(
            reportOf('0.500 pixels on the bottom and 41 pixels on the right')),
        isTrue,
      );
    });

    test('rejects unrelated errors that merely use the word', () {
      // The reason the predicate is two markers instead of one substring. An
      // error caught here is an error that never fails its test, so the cost of
      // being too generous is a silent pass, while the cost of being too strict
      // is a spurious failure that names itself.
      for (final unrelated in [
        'Bad state: receive buffer overflowed',
        'The stack overflowed while resolving the theme',
        'RangeError: index overflowed the list length',
      ]) {
        expect(
          isOverflowError(unrelated),
          isFalse,
          reason: '"$unrelated" is not a layout overflow — swallowing it would '
              'stop it failing the test it happened in',
        );
      }
    });
  });

  group('kOverflowTolerancePx', () {
    test('is still 2.0 and still reachable through the probe path', () {
      // Two claims in one line, and the second is the one #1338 could have
      // broken. The number is shared (#1270) so five satellite suites cannot
      // drift apart from the gate; moving its declaration into
      // `test/layout_gate/incident.dart` without the re-export would have made
      // every one of those `> kOverflowTolerancePx` filters a compile error, and
      // moving it *with* a different value would have changed every verdict in
      // the family at once.
      expect(kOverflowTolerancePx, 2.0);
      expect(
        OverflowIncident.unparseablePixels,
        greaterThan(kOverflowTolerancePx),
        reason: 'the unparseable marker exists to survive this filter',
      );
    });
  });

  group('OverflowIncident.parse', () {
    test('reads the pixel count and side', () {
      final incident =
          OverflowIncident.parse(reportOf('41 pixels on the right'));
      expect(incident.pixels, 41);
      expect(incident.side, 'right');
    });

    test('reports the worst side when one report names several', () {
      // Flutter emits sides in the fixed order left, top, bottom, right, so the
      // *first* clause of a two-sided report is the one nearer the top of that
      // list — not the largest. Reading only the first turned a 41px right
      // overflow into a sub-tolerance bottom reading, and the gate's
      // `pixels > 2.0` filter then dropped it entirely.
      final incident = OverflowIncident.parse(
        reportOf('0.500 pixels on the bottom and 41 pixels on the right'),
      );
      expect(incident.pixels, 41);
      expect(incident.side, 'right');
      expect(
        [incident].where((i) => i.pixels > 2.0),
        isNotEmpty,
        reason: 'the gate filters on a 2px tolerance, so a two-sided report '
            'whose worst side is 41px must survive it',
      );

      // `_formatPixels` writes one decimal in (1, 10] and three significant
      // digits at or below 1.0, so the sub-tolerance clause reaches the parser in
      // more than one shape. Both must lose to the 41px clause.
      final oneDecimal = OverflowIncident.parse(
        reportOf('0.5 pixels on the bottom and 41 pixels on the right'),
      );
      expect(oneDecimal.pixels, 41);
      expect(oneDecimal.side, 'right');
    });

    test('parses sub-pixel counts written in exponent form', () {
      // `_formatPixels` uses `toStringAsPrecision(3)` below 1px, which switches
      // to exponent notation for very small values. `1.00e-7` read as `1.00`
      // overstates by seven orders of magnitude — harmless against a 2px
      // tolerance, but it makes the reports lie.
      expect(
        OverflowIncident.parse(reportOf('1.00e-7 pixels on the right')).pixels,
        closeTo(1e-7, 1e-12),
      );
    });

    test('an unparseable report survives every tolerance filter', () {
      // The failure this prevents: an SDK change to the number format leaves the
      // regex matching nothing. With a `0` fallback the incident is recorded and
      // then discarded by every `pixels > tolerance` filter in the gate, so the
      // gate reads clean at the exact moment it stopped being able to measure.
      final incident = OverflowIncident.parse(
        reportOf('a whole bunch of pixels on the right'),
      );
      expect(incident.side, 'unknown');
      for (final tolerance in [0.0, 2.0, 1e9]) {
        expect(
          [incident].where((i) => i.pixels > tolerance),
          isNotEmpty,
          reason: 'an unreadable overflow report must not be filtered out by a '
              '${tolerance}px tolerance — silence here is indistinguishable '
              'from a clean layout',
        );
      }
    });

    test('keeps the first line as the message and the details as the log', () {
      final incident = OverflowIncident.parse(
        '${reportOf('41 pixels on the right')}\nThe edge of the RenderFlex...',
        fullLog: 'full details',
      );
      expect(incident.message, reportOf('41 pixels on the right'));
      expect(incident.fullLog, 'full details');
    });

    test('refuses a malformed amount instead of reading part of it', () {
      // Ported from the golden parser #1339 deleted, which spelled the number as
      // `\d+(?:\.\d+)?` and so matched nothing here. This one spells it `[\d.]+`
      // — deliberately looser, to reach the exponent form above — so `1.2.3`
      // *matches* and the rejection has to come from `double.tryParse` instead.
      // Same outcome, different mechanism, which is exactly the kind of thing
      // that stops being obvious once the two parsers are one.
      final incident = OverflowIncident.parse(
        reportOf('1.2.3 pixels on the right'),
      );

      expect(incident.pixelsText, isNull);
      expect(incident.pixels, OverflowIncident.unparseablePixels,
          reason:
              'a number nobody can read is louder than a wrong one: a badge '
              'reading "1.2.3px" sorts as 0 and hides the overflow');
      expect(incident.side, 'unknown');
    });
  });

  group('OverflowIncident.pixelsText', () {
    // The field exists for one caller — the golden framework's advisory record,
    // whose `pixels` is a String that reaches a report badge and a site key
    // verbatim. Re-rendering the double there would rewrite user-visible text
    // for every record, because Flutter picks its precision from the unrounded
    // value and no mirror of that choice is round-trip safe (#1339).
    test('carries the clause exactly as Flutter spelled it', () {
      // Every shape `_formatPixels` can emit, against what the parsed double
      // renders as: no decimals above 10px, one decimal in (1, 10], three
      // significant digits at or below 1px, exponent notation for the very
      // small. Three of the four disagree, and `18` → `18.0` is the one that
      // would have rewritten all 16 records in
      // `test/fixtures/golden_overflow_warnings.json`.
      const spellings = {
        '18': '18.0',
        '0.500': '0.5',
        '1.00e-7': '1e-7',
        '5.5':
            '5.5', // the one that round-trips, kept so the list is the format
      };

      for (final entry in spellings.entries) {
        final incident =
            OverflowIncident.parse(reportOf('${entry.key} pixels on the top'));

        expect(incident.pixelsText, entry.key);
        expect('${incident.pixels}', entry.value,
            reason: 'if the double now renders as something else, the gap this '
                'field bridges has moved and the golden report will churn');
      }
    });

    test('is the worst clause, not the first', () {
      // The one sanctioned behavioural difference between the two parsers, in the
      // field that carries it: the deleted copy took the first clause.
      final incident = OverflowIncident.parse(
        reportOf('10.0 pixels on the bottom and 41 pixels on the right'),
      );

      expect(incident.pixelsText, '41');
      expect(incident.side, 'right');
    });

    test('is null exactly when the amount is unparseable', () {
      // The contract the advisory caller opts out through: one null check, and
      // it cannot disagree with the loud default about *whether* the message was
      // read — only about what to do next.
      final unreadable =
          OverflowIncident.parse(reportOf('lots of pixels on the right'));
      expect(unreadable.pixelsText, isNull);
      expect(unreadable.pixels, OverflowIncident.unparseablePixels);

      final readable = OverflowIncident.parse(reportOf('41 pixels on the top'));
      expect(readable.pixelsText, isNotNull);
      expect(readable.pixels, lessThan(OverflowIncident.unparseablePixels));
    });
  });

  group('OverflowIncident source location', () {
    /// The shape `FlutterErrorDetails.toString()` writes for an overflow, cut
    /// down to the two parts the parser reads. Hand-written so a specific path
    /// shape can be exercised — the shape itself is checked against a real
    /// Flutter overflow in the last group of this file, which is what stops these
    /// tests from only agreeing with themselves.
    String dumpFor(String creationLocation) => '''
══╡ EXCEPTION CAUGHT BY RENDERING LIBRARY ╞══════════════════════
The following assertion was thrown during layout:
A RenderFlex overflowed by 41 pixels on the right.

The relevant error-causing widget was:
  Row
  $creationLocation

The overflowing RenderFlex has an orientation of Axis.horizontal.
''';

    OverflowIncident incidentAt(
      String creationLocation, {
      required String runDirectory,
    }) =>
        OverflowIncident.parse(
          'A RenderFlex overflowed by 41 pixels on the right.',
          fullLog: dumpFor(creationLocation),
          runDirectory: runDirectory,
        );

    test('reports the widget, the file:line and the join key', () {
      // The whole reason the field exists: `site` is what the ratchet keys on
      // and what joins this gate's verdicts to golden CI's advisory findings. A
      // coordinate-keyed allowlist invalidates wholesale the moment a layout is
      // rearranged; a source-location key survives it.
      final incident = incidentAt(
        'Row:file:///Users/dev/work/PrivacyGUI/lib/page/admin/x.dart:120:14',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.widget, 'Row');
      expect(incident.file, 'lib/page/admin/x.dart');
      expect(incident.line, 120);
      expect(incident.site, 'lib/page/admin/x.dart:120');
      expect(incident.pixels, 41, reason: 'the measurement is untouched by it');
    });

    test('strips a run directory that is not named after the repo', () {
      // golden-ci clones the app into "app" under its own workspace, so no path
      // segment is ever "/PrivacyGUI/". Matching on the directory name would
      // leak the whole CI workspace path into the join key and make the two
      // sides unjoinable.
      final incident = incidentAt(
        'Column:file:///home/runner/work/PrivacyGUI-golden-ci/'
        'PrivacyGUI-golden-ci/app/lib/page/admin/x.dart:7:3',
        runDirectory:
            '/home/runner/work/PrivacyGUI-golden-ci/PrivacyGUI-golden-ci/app',
      );

      expect(incident.file, 'lib/page/admin/x.dart');
      expect(incident.widget, 'Column');
    });

    test('collapses a pub-cache git dependency to package-relative form', () {
      // A widget built inside a git dependency reports a pub-cache path carrying
      // the resolved commit SHA, which differs per machine and per dependency
      // bump — so the raw path is the one thing a join key must not be.
      final incident = incidentAt(
        'Row:file:///Users/dev/.pub-cache/git/privacyGUI-UI-kit-'
        '628f62fd51c9dd39b127843d41fcb4c9c07c937f/lib/src/molecules/buttons/'
        'app_button.dart:447:13',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file,
          'privacyGUI-UI-kit/lib/src/molecules/buttons/app_button.dart');
      expect(incident.line, 447);
      expect(incident.file, isNot(startsWith('/')),
          reason: 'no absolute path may reach the ratchet or the report');
    });

    test('collapses a hosted pub-cache dependency, registry segment and all',
        () {
      final incident = incidentAt(
        'Wrap:file:///Users/dev/.pub-cache/hosted/pub.dev/some_pkg-1.2.3/'
        'lib/src/thing.dart:88:5',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file, 'some_pkg/lib/src/thing.dart');
      expect(incident.line, 88);
    });

    test('decodes a percent-encoded home directory before comparing', () {
      // Flutter records creation locations as URIs, so a space in the
      // developer's home directory arrives as `%20`. Compared raw against the
      // run directory it never matches, and the untouched absolute path — user
      // account name included — becomes the key.
      final incident = incidentAt(
        'Row:file:///Users/John%20Smith/dev/PrivacyGUI/lib/page/admin/x.dart'
        ':12:5',
        runDirectory: '/Users/John Smith/dev/PrivacyGUI',
      );

      expect(incident.file, 'lib/page/admin/x.dart');
    });

    test('collapses a pub-cache path that is itself percent-encoded', () {
      // Ported from the golden parser #1339 deleted, and the one case of its 27
      // that nothing here covered even indirectly: the space and the pub-cache
      // collapse were each tested alone, never together. They interact through
      // ordering — the decode has to happen *before* the `/.pub-cache/git/`
      // marker is looked for, or a developer whose home directory has a space in
      // it gets the SHA-carrying absolute path as a key.
      final incident = incidentAt(
        'Row:file:///Users/John%20Smith/.pub-cache/git/privacyGUI-UI-kit-'
        '628f62fd51c9dd39b127843d41fcb4c9c07c937f/lib/src/x.dart:12:5',
        runDirectory: '/Users/John Smith/dev/PrivacyGUI',
      );

      expect(incident.file, 'privacyGUI-UI-kit/lib/src/x.dart');
      expect(incident.site, 'privacyGUI-UI-kit/lib/src/x.dart:12');
    });

    test('decodes a non-ASCII run directory', () {
      // Ported from the golden parser #1339 deleted. Not the same case as the
      // space above: `%20` is one byte and CJK is three per character, so a
      // decoder that worked byte-wise or gave up outside ASCII would pass that
      // test and fail this one. Cheap to keep, and the developers whose home
      // directory is not ASCII are the ones who would never see the gate work.
      final incident = incidentAt(
        'Row:file:///Users/dev/%E4%B8%AD%E6%96%87/PrivacyGUI/lib/x.dart:12:5',
        runDirectory: '/Users/dev/中文/PrivacyGUI',
      );

      expect(incident.file, 'lib/x.dart');
      expect(incident.site, 'lib/x.dart:12');
    });

    test('leaves a path carrying a literal percent sign alone', () {
      // A bare '%' is not valid percent-encoding, and decoding throws on it.
      // This runs inside `FlutterError.onError`, so a throw would turn a
      // diagnostic into a test failure — the path must fall through untouched.
      final incident = incidentAt(
        'Row:file:///Users/dev/100%/x.dart:12:5',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file, '/Users/dev/100%/x.dart');
      expect(incident.line, 12);
    });

    test('leaves a path whose escapes are hex but not UTF-8 alone', () {
      // The other way `Uri.decodeFull` refuses, and the one the guard used to
      // miss: `%zz` is malformed hex and throws ArgumentError, while `%C3` alone
      // is well-formed hex whose bytes are an incomplete UTF-8 sequence and
      // throws FormatException ("Missing extension byte"). Only the first was
      // caught, so a checkout under a directory like this turned a golden that
      // merely *reported* an overflow into a failing test —
      // `buildOverflowRecord` calls the dump normaliser outside its own guards
      // on the strength of this function not throwing.
      //
      // Same premise as the test above — a raw, unencoded `%` reaching the parser
      // in the dump — so this is exactly as reachable as that case, and differs
      // only in which exception the decoder picks.
      final incident = incidentAt(
        'Row:file:///Users/dev/a%C3b/x.dart:12:5',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file, '/Users/dev/a%C3b/x.dart');
      expect(incident.line, 12);
      expect(incident.pixels, 41.0,
          reason:
              'an undecodable path costs the location, never the measurement');
    });

    test('returns a path that matches nothing unchanged', () {
      // Better a long path than none: an unrecognised location is still a lead,
      // and dropping it would leave the incident unjoinable for no gain.
      final incident = incidentAt(
        'Row:file:///opt/elsewhere/x.dart:9:1',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      expect(incident.file, '/opt/elsewhere/x.dart');
    });

    test('withholds the join key for a path that stayed absolute', () {
      // The other half of the test above, and the reason it is not a
      // contradiction: what a person reads and what gets committed are different
      // audiences. `file` keeps the long path because it is the only lead;
      // `site` refuses it because a key carrying `/Users/dev` makes
      // `overflow_baseline.sh capture` machine-dependent and makes a fixture
      // entry work on exactly one checkout.
      //
      // Both shapes that reach here uncollapsed, neither hypothetical: a cache
      // relocated with PUB_CACHE, and a dependency mounted by `path:` from
      // outside the checkout.
      final relocatedCache = incidentAt(
        'Row:file:///opt/pubcache/hosted/pub.dev/some_pkg-1.2.3/lib/x.dart:9:1',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );
      final pathOverride = incidentAt(
        'Row:file:///Users/dev/clones/ui_kit_library/lib/src/row.dart:88:7',
        runDirectory: '/Users/dev/work/PrivacyGUI',
      );

      for (final incident in [relocatedCache, pathOverride]) {
        expect(incident.file, startsWith('/'),
            reason: 'the lead survives for the person reading the failure');
        expect(incident.line, isNotNull);
        expect(incident.site, isNull,
            reason: 'an absolute path is not a key any other machine can use');
      }
      // And the measurement is untouched by any of it.
      expect(relocatedCache.pixels, 41);
    });

    test('resolves a Windows creation location, drive letter and all', () {
      // `file:///C:/…` is the shape Flutter reports on Windows. Until #1356 the
      // path group could not span the drive colon, so the pattern failed
      // outright and *every* incident on Windows came back with no location —
      // and a null site can never be exempted (`ratchet.dart:272`), so a
      // populated allowlist blocked the whole gate on that platform.
      //
      // Three things differ from POSIX at once and all three are handled here:
      // the leading slash the URI puts before the drive, the drive case, and the
      // backslashes `Directory.current.path` uses.
      final incident = incidentAt(
        r'Row:file:///c:/src/app/lib/page/admin/x.dart:120:14',
        runDirectory: r'C:\src\app',
      );

      expect(incident.widget, 'Row');
      expect(incident.file, 'lib/page/admin/x.dart');
      expect(incident.line, 120);
      expect(incident.site, 'lib/page/admin/x.dart:120',
          reason: 'the key must be the same string a POSIX run produces');
    });

    test('a Windows path outside the checkout keeps its drive out of the key',
        () {
      final incident = incidentAt(
        r'Row:file:///D:/pubcache/hosted/pub.dev/some_pkg-1.2.3/lib/x.dart:9:1',
        runDirectory: r'C:\src\app',
      );

      expect(incident.file, startsWith('D:'));
      expect(incident.site, isNull);
    });

    test('anchors the search inside the error-causing-widget block', () {
      // The deep dump the golden runner reads (`toStringDeep()`, which #1339
      // will feed through this parser) also carries a `creator:` chain whose
      // entries match the same pattern, and the two blocks' relative order is a
      // Flutter implementation detail. An unanchored search reports whichever
      // came first, which is a plausible-looking wrong file.
      const dump = '''
Exception caught by rendering library
   A RenderFlex overflowed by 41 pixels on the right.

   The relevant error-causing widget was:
     Row
     Row:file:///repo/lib/page/dhcp/leases_card.dart:101:12

   The specific RenderFlex in question is: RenderFlex#9e273 OVERFLOWING:
     creator: Column:file:///repo/lib/page/other/wrong.dart:7:3
''';

      final incident = OverflowIncident.parse(
        'A RenderFlex overflowed by 41 pixels on the right.',
        fullLog: dump,
        runDirectory: '/repo',
      );

      expect(incident.site, 'lib/page/dhcp/leases_card.dart:101');
    });

    test('ignores a creator chain that precedes the widget block', () {
      const dump = '''
Exception caught by rendering library
   The specific RenderFlex in question is: RenderFlex#9e273 OVERFLOWING:
     creator: Column:file:///repo/lib/page/other/wrong.dart:7:3

   The relevant error-causing widget was:
     Row
     Row:file:///repo/lib/page/dhcp/leases_card.dart:101:12
''';

      final incident = OverflowIncident.parse(
        'A RenderFlex overflowed by 41 pixels on the right.',
        fullLog: dump,
        runDirectory: '/repo',
      );

      expect(incident.site, 'lib/page/dhcp/leases_card.dart:101');
      expect(incident.widget, 'Row');
    });

    test('a dump with no resolvable location still yields a usable incident',
        () {
      // Creation tracking can be off, the culprit can live inside
      // packages/flutter, and Flutter can reword the block. None of those is a
      // reason to fail a test or to lose the measurement: ~120 of the golden
      // pipeline's coordinates resolved no location at all and the amount was
      // still the whole finding.
      final incident = OverflowIncident.parse(
        'A RenderFlex overflowed by 41 pixels on the right.',
        fullLog: 'A RenderFlex overflowed by 41 pixels on the right.\n'
            'No creation location anywhere in here.',
        runDirectory: '/repo',
      );

      expect(incident.file, isNull);
      expect(incident.line, isNull);
      expect(incident.widget, isNull);
      expect(incident.site, isNull,
          reason:
              'an unjoinable incident says so, rather than inventing a key');
      expect(incident.pixels, 41);
      expect(incident.side, 'right');
      expect(incident.toString(), isNotEmpty);
    });

    test('reads the location even when the pixel count is unreadable', () {
      // The two extractions are independent on purpose. This is the case that
      // most needs a location: the parser has stopped understanding Flutter's
      // number format, and `file:line` is the only thing left pointing at what
      // to look at.
      final incident = incidentAt(
        'Row:file:///repo/lib/page/admin/x.dart:120:14',
        runDirectory: '/repo',
      );
      final unreadable = OverflowIncident.parse(
        'A RenderFlex overflowed by a whole bunch of pixels on the right.',
        fullLog: incident.fullLog,
        runDirectory: '/repo',
      );

      expect(unreadable.pixels, double.infinity);
      expect(unreadable.side, 'unknown');
      expect(unreadable.site, 'lib/page/admin/x.dart:120');
    });

    test('defaults the run directory to the process working directory', () {
      // The 22 existing call sites pass no run directory and must keep
      // compiling, so the default has to be right rather than merely present:
      // under `flutter test` the process cwd is the app root, which is what the
      // reported paths are relative to.
      final incident = incidentAt(
        'Row:file://${Directory.current.path}/lib/page/admin/x.dart:120:14',
        runDirectory: Directory.current.path,
      );
      final defaulted = OverflowIncident.parse(
        'A RenderFlex overflowed by 41 pixels on the right.',
        fullLog: incident.fullLog,
      );

      expect(defaulted.file, 'lib/page/admin/x.dart');
      expect(defaulted.file, incident.file);
    });
  });

  group('the dump transforms', () {
    // Hosted in `incident.dart` since #1339 although only the golden report's
    // record calls them, because they are transforms of the same string, need the
    // same normalisation rules, and hosting them is what keeps the location
    // regex private — exporting a regex is how the second parser gets written
    // next time. These cases came with them from the deleted copy.
    group('normalizeOverflowDumpPaths', () {
      test('rewrites every location in the dump, not just the culprit\'s', () {
        // The difference from `parse`, which reads one location: a dump kept
        // whole names a creation location for every widget in the creator chain,
        // and each one carries the directory the run happened in. Left in, a
        // report built on CI embeds the runner's workspace.
        const dump = '''
The relevant error-causing widget was:
  Row:file:///repo/lib/page/dhcp/leases_card.dart:101:12
  creator: Column:file:///repo/lib/page/dhcp/dhcp_view.dart:7:3
  creator: Padding:file:///Users/dev/.pub-cache/git/privacyGUI-UI-kit-628f62fd51c9dd39b127843d41fcb4c9c07c937f/lib/src/x.dart:9:1
''';

        final normalized =
            normalizeOverflowDumpPaths(dump, runDirectory: '/repo');

        expect(
            normalized, contains('Row:lib/page/dhcp/leases_card.dart:101:12'));
        expect(normalized, contains('Column:lib/page/dhcp/dhcp_view.dart:7:3'));
        expect(normalized,
            contains('Padding:privacyGUI-UI-kit/lib/src/x.dart:9:1'));
        expect(normalized, isNot(contains('file://')),
            reason: 'the scheme goes with the absolute path — pre-#1339 '
                'behaviour, kept because the stored corpus is compared verbatim');
        expect(normalized, isNot(contains('/Users/dev')));
      });

      test('leaves everything that is not a location alone', () {
        // The geometry is what explains an overflow, and a transform that reached
        // it would corrupt the only useful part of the dump.
        const line =
            '     constraints: BoxConstraints(w=398.0, 0.0<=h<=Infinity)';

        expect(normalizeOverflowDumpPaths(line, runDirectory: '/repo'), line);
      });
    });

    group('stripOverflowObjectIds', () {
      test('removes the object hash Flutter appends to render object names',
          () {
        // The id is a per-object allocation detail: the same overflow reported in
        // 24 goldens carried 24 different ids, so nothing downstream could tell
        // that one culprit explained them all, and the recorded JSON changed on
        // every run.
        expect(
          stripOverflowObjectIds(
            'The specific RenderFlex in question is: '
            'RenderFlex#4195b relayoutBoundary=up14 OVERFLOWING:',
          ),
          'The specific RenderFlex in question is: '
          'RenderFlex relayoutBoundary=up14 OVERFLOWING:',
        );
      });

      test('removes ids from the creator chain', () {
        expect(
          stripOverflowObjectIds(
              'creator: Row ← RepaintBoundary-[GlobalKey#18e2d] ← Column'),
          'creator: Row ← RepaintBoundary-[GlobalKey] ← Column',
        );
      });

      test('leaves the geometry that explains the overflow intact', () {
        // Sibling rows legitimately differ here, and that difference is the
        // diagnostic — it must survive.
        const line = '     size: Size(398.0, 532.0)';

        expect(stripOverflowObjectIds(line), line);
      });

      test('leaves text that merely looks like an id alone', () {
        // Only a '#' directly following an identifier is an object id.
        expect(stripOverflowObjectIds('Reservation #12345 for host'),
            'Reservation #12345 for host');
      });
    });
  });

  group('OverflowIncident.toString', () {
    // Pinned because this string is the only output a person reads that #1338
    // changed, and nothing else in the suite would notice it changing: the
    // sweeps render it into their failure messages
    // (`dashboard_card_overflow_test.dart:478,721,866,876`) and the report
    // generator into its Markdown detail line and HTML badge
    // (`dashboard_overflow_report_generator.dart:125,380`), while #1337's
    // baselines serialize `px`, `side` and the source columns and never this.
    test('appends the site when the location resolved', () {
      const incident = OverflowIncident(
        pixels: 41.0,
        side: 'right',
        message: 'A RenderFlex overflowed by 41 pixels on the right.',
        file: 'lib/page/dhcp/leases_card.dart',
        line: 101,
        widget: 'Row',
      );

      expect(incident.toString(),
          '+41.0px right at lib/page/dhcp/leases_card.dart:101');
    });

    test('says amount and side alone when it did not', () {
      const incident = OverflowIncident(
        pixels: 41.0,
        side: 'right',
        message: 'A RenderFlex overflowed by 41 pixels on the right.',
      );

      expect(incident.toString(), '+41.0px right',
          reason: 'no trailing " at " with nothing after it');
    });

    test('treats a file without a line as no join key at all', () {
      // Unreachable through `parse`, which sets the two together — but the const
      // constructor is public, and `lib/x.dart:null` would read as a resolved
      // key while joining to nothing.
      const half = OverflowIncident(
        pixels: 41.0,
        side: 'right',
        message: 'A RenderFlex overflowed by 41 pixels on the right.',
        file: 'lib/page/dhcp/leases_card.dart',
      );

      expect(half.site, isNull);
      expect(half.toString(), '+41.0px right');
    });
  });

  group('runWithOverflowCollection', () {
    /// Runs [body] with [FlutterError.onError] pointed at a list, and returns
    /// what that list caught. Stands in for the test binding's own handler: what
    /// matters is whether the probe hands an error onward, not who receives it.
    Future<List<String>> forwardedBy(
      Future<void> Function(List<OverflowIncident> sink) body,
    ) async {
      final forwarded = <String>[];
      final saved = FlutterError.onError;
      FlutterError.onError =
          (details) => forwarded.add(details.exception.toString());
      try {
        await runWithOverflowCollection((sink) async {
          await body(sink);
          return null;
        });
      } finally {
        FlutterError.onError = saved;
      }
      return forwarded;
    }

    test('collects overflow reports instead of forwarding them', () async {
      List<OverflowIncident>? collected;
      final forwarded = await forwardedBy((sink) async {
        FlutterError.reportError(FlutterErrorDetails(
          exception: FlutterError(reportOf('41 pixels on the right')),
        ));
        collected = List.of(sink);
      });
      expect(forwarded, isEmpty);
      expect(collected, hasLength(1));
      expect(collected!.single.pixels, 41);
    });

    test('forwards errors that are not overflows', () async {
      // Without this, any exception thrown during a pump — a provider blowing
      // up, a null in a builder — is absorbed by the probe and the card is
      // recorded as laying out cleanly.
      List<OverflowIncident>? collected;
      final forwarded = await forwardedBy((sink) async {
        FlutterError.reportError(FlutterErrorDetails(
          exception: StateError('receive buffer overflowed'),
        ));
        collected = List.of(sink);
      });
      expect(
        forwarded,
        hasLength(1),
        reason: 'a non-overflow error must reach the handler that fails the '
            'test; the probe is not entitled to consume it',
      );
      expect(collected, isEmpty);
    });

    test('restores the previous handler when body throws', () async {
      final saved = FlutterError.onError;
      void sentinel(FlutterErrorDetails details) {}
      FlutterError.onError = sentinel;
      try {
        await expectLater(
          runWithOverflowCollection<void>(
              (sink) async => throw StateError('x')),
          throwsStateError,
        );
        expect(
          FlutterError.onError,
          same(sentinel),
          reason:
              'a probe that leaks its handler on the error path leaves every '
              'later test reporting into the probe of a finished one',
        );
      } finally {
        FlutterError.onError = saved;
      }
    });
  });

  group('the layout surface', () {
    // #1340's own verification signal. Setting the viewport is the easy half and
    // every sweep would have caught a mistake in it; putting it back is the half
    // nothing observed, which is why it appears here rather than in a sweep.

    /// What a test sees before anything has touched the viewport.
    ///
    /// Captured by the first test of this group and compared against by the
    /// others. Read rather than written as literals: the defaults under
    /// `flutter test` (800×600 logical, 2400×1800 physical, ratio 3.0 at the time
    /// of writing) belong to the SDK, and pinning them here would make these
    /// tests fail for a reason that has nothing to do with #1340. What has to
    /// hold is not which numbers they are, but that they are the same afterwards.
    ({Size layout, Size physical, double ratio})? pristine;

    /// The viewport as the widget tree sees it.
    ///
    /// `layout` is measured rather than read, because it is the one of the three
    /// that has no getter: `setSurfaceSize` keeps its value private and reaches
    /// the tree as the root render view's logical constraints
    /// (`binding.dart:1468`). A root child that expands into whatever it is given
    /// therefore *is* the reading.
    Future<({Size layout, Size physical, double ratio})> viewportOf(
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const SizedBox.expand());
      return (
        layout: tester.getSize(find.byType(SizedBox)),
        physical: tester.view.physicalSize,
        ratio: tester.view.devicePixelRatio,
      );
    }

    testWidgets('sets all three properties of the viewport', (tester) async {
      pristine = await viewportOf(tester);

      // The last hand-written surface dance in the gate family, kept for one
      // purpose: dirtying all three with values nothing else would produce means
      // a primitive that sets only one or two of them cannot pass by inheriting
      // a default that happened to be right.
      await tester.binding.setSurfaceSize(const Size(1111, 2222));
      tester.view.physicalSize = const Size(3333, 4444);
      tester.view.devicePixelRatio = 2.5;

      await setLayoutSurface(tester, const Size(640, 480));
      final viewport = await viewportOf(tester);

      expect(
        viewport.layout,
        const Size(640, 480),
        reason: 'the tree has to be laid out at the size asked for — this is '
            'the property every width in every sweep is measured against',
      );
      expect(
        viewport.physical,
        const Size(640, 480),
        reason: 'anything reading View.of(context) rather than MediaQuery has '
            'to see the same viewport, or two probes on one page disagree '
            'about how wide it is',
      );
      expect(
        viewport.ratio,
        1.0,
        reason: 'logical and physical pixels have to be the same number: the '
            'widths the sweeps enumerate and kOverflowTolerancePx are both '
            'logical, and physicalConstraints is derived as '
            'logicalConstraints × devicePixelRatio',
      );
      expect(
        viewport.physical.width / viewport.ratio,
        viewport.layout.width,
        reason: 'which is what ratio 1.0 buys — one unit for the whole gate, '
            'not two that happen to agree at some widths',
      );
    });

    /// What the observer teardown registered by the sweep-shaped test below saw.
    ///
    /// Read by the test after it. This is how "one restore, not 78" is asserted
    /// on an observable consequence instead of on a private counter.
    final observedByTearDown = <Size>[];

    testWidgets('is set many times in one test, the way a sweep does',
        (tester) async {
      expect(pristine, isNotNull,
          reason:
              'this group is ordered; the first test captures the baseline');

      // Not a stress test — this is the real shape. The chrome header sweep pumps
      // 3 modes × 26 locales inside one testWidgets, so one test sets the surface
      // 78 times, and a teardown registered per call would pile up 78 async
      // teardowns to do work that is idempotent after the first.
      await setLayoutSurface(tester, const Size(320, 800));

      // Registered between the first call and the other 77, which is what makes
      // the "one restore" claim observable from outside the primitive.
      // Tear-downs run last-registered-first (`Invoker.runTearDowns` pops with
      // `removeLast()`), so:
      //   * one restore, registered by the call above → this observer runs
      //     first and reads the viewport still set to the last size below;
      //   * one restore per call → the 77 registered after this one all run
      //     before it, each resetting, and this observer reads the default.
      // The next test reads which of the two happened.
      addTearDown(() => observedByTearDown.add(tester.view.physicalSize));

      for (var i = 1; i < 78; i++) {
        await setLayoutSurface(tester, Size((320 + i).toDouble(), 800));
      }

      expect((await viewportOf(tester)).layout, const Size(397, 800),
          reason: 'the last call wins while the test is still running');
    });

    testWidgets('is restored afterwards, and restored exactly once',
        (tester) async {
      final viewport = await viewportOf(tester);

      // The assertion a leaking width fails, and the reason this test exists at
      // all: nothing in the SDK puts either half back between tests.
      // `setSurfaceSize`'s own doc comment tells the caller to `addTearDown` the
      // reset, and no binding hook calls `TestFlutterView.reset()` — so a width
      // set and not cleared is still installed here.
      expect(viewport.layout, pristine!.layout,
          reason: 'a width leaking out of the test above would make this test '
              'measure a viewport nobody chose, and say nothing about it');
      expect(viewport.physical, pristine!.physical);
      expect(viewport.ratio, pristine!.ratio);

      expect(observedByTearDown, hasLength(1),
          reason: 'the observer itself is registered once');
      expect(
        observedByTearDown.single,
        const Size(397, 800),
        reason: 'the 78 calls in the test above must have registered ONE '
            'restore. The observer was registered after the first of them and '
            'tear-downs run last-registered-first, so a second registration '
            'would have restored the viewport before the observer read it and '
            'this would be ${pristine!.physical} instead.',
      );
    });

    testWidgets(
      'is registered again by the next test that sets it',
      (tester) async {
        // The dedupe must not outlive the test that armed it. If it did, this
        // call would skip registration and the width below would reach the test
        // after this one — the leak, reintroduced by the fix for the pile-up.
        await setLayoutSurface(tester, const Size(191, 1000));
        expect((await viewportOf(tester)).layout, const Size(191, 1000));
      },
      // Two variants of ONE declaration, because that is the only way to get two
      // tests that share a `WidgetTester` instance: `testWidgets` builds the
      // tester per declaration, outside the variant loop
      // (`widget_tester.dart:164`). That makes this pair the executed mutation
      // for the teardown's own `_restoreRegisteredFor = null` — drop that line
      // and the second variant finds the marker still pointing at its tester,
      // skips registration, and leaves 191×1000 installed for the next test.
      variant: ValueVariant<int>(const {1, 2}),
    );

    testWidgets('and that restore ran too', (tester) async {
      final viewport = await viewportOf(tester);
      expect(viewport.layout, pristine!.layout,
          reason: 'a 191px width still installed here means the marker leaked '
              'out of the test above and its restore was never registered');
      expect(viewport.physical, pristine!.physical);
      expect(viewport.ratio, pristine!.ratio);
    });

    testWidgets('collectOverflow sets it through the same primitive',
        (tester) async {
      // AC 2's "and now also covers the card path". `collectOverflow` and
      // `probeCardOverflow` are the two entry points the card family measures
      // through, and since #1340 both reach the viewport through
      // `setLayoutSurface` and nothing else — so this and the test after it are
      // the card path's first reset, not a second copy of one.
      final incidents = await collectOverflow(
        tester,
        const SizedBox.expand(),
        surfaceSize: const Size(191, 400),
      );

      expect(incidents, isEmpty, reason: 'a box that expands cannot overflow');
      expect(tester.view.physicalSize, const Size(191, 400),
          reason:
              'the surface stays set while the test runs; only the teardown '
              'puts it back');
    });

    testWidgets('and the card path leaves nothing behind', (tester) async {
      final viewport = await viewportOf(tester);
      // Before #1340 this was the one place the two frameworks genuinely
      // differed on: the chrome suite reset the surface in `_resetSurfaceAfter`
      // and the card path reset nothing, so a card-sized viewport outlived the
      // test that asked for it and whatever ran next measured in it.
      expect(viewport.layout, pristine!.layout,
          reason: 'a 191×400 viewport still installed here is the neighbouring '
              'test measuring a card box instead of a screen');
      expect(viewport.physical, pristine!.physical);
      expect(viewport.ratio, pristine!.ratio);
    });
  });

  group('against a real overflow', () {
    // The three tests above use a hand-written copy of the SDK's message, so on
    // their own they would keep passing after an SDK upgrade renamed the very
    // thing they parse. These pump a Row that genuinely does not fit and read
    // whatever Flutter actually says, which is what couples the parser to the
    // SDK rather than to this file's own string.
    //
    // No `loadAppFonts()`: the overflow here is a fixed-width box against a
    // fixed-width parent, so it is arithmetic, not text measurement.
    Future<String> rawReportFrom(WidgetTester tester, Widget child) async {
      final captured = <String>[];
      final saved = FlutterError.onError;
      FlutterError.onError =
          (details) => captured.add(details.exceptionAsString());
      try {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 100, child: child),
            ),
          ),
        );
      } finally {
        FlutterError.onError = saved;
      }
      expect(captured, hasLength(1),
          reason: 'expected exactly one report from this pump, got $captured');
      return captured.single;
    }

    testWidgets('the SDK message still satisfies the predicate and parser',
        (tester) async {
      final raw = await rawReportFrom(
        tester,
        Row(children: const [SizedBox(width: 400, height: 10)]),
      );

      expect(
        isOverflowError(raw),
        isTrue,
        reason: 'Flutter now reports overflow as "$raw", which '
            '`isOverflowError` no longer recognises — every gate test is '
            'silently passing. Update the predicate and the parser together.',
      );
      final incident = OverflowIncident.parse(raw);
      expect(incident.side, 'right');
      expect(incident.pixels, closeTo(300, 1),
          reason: 'a 400px child in a 100px Row overflows by 300px, so a '
              'reading far from that means the parser picked up the wrong '
              'number from "$raw"');
    });

    testWidgets('collectOverflow measures the same overflow end to end',
        (tester) async {
      final overflows = await collectOverflow(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: Row(children: const [SizedBox(width: 400, height: 10)]),
            ),
          ),
        ),
        surfaceSize: const Size(800, 600),
      );
      expect(overflows, hasLength(1));
      expect(overflows.single.pixels, closeTo(300, 1));
      expect(overflows.single.side, 'right');
    });

    /// The 1-based line in this file on which the marked `Row` below is built.
    ///
    /// Found by reading this file rather than written as a literal, because a
    /// literal turns the assertion into a lie the first time anyone inserts a
    /// line above it — and the lie is invisible, since `line` would still be *a*
    /// plausible number.
    int lineOfMarkedRow() {
      // Split so this line is not itself a candidate match.
      const marker = '// LOAD-BEARING' '-ROW';
      final source =
          File('test/util/overflow_probe_test.dart').readAsLinesSync();
      final markerIndex = source.indexWhere((l) => l.contains(marker));
      expect(markerIndex, isNonNegative,
          reason: 'the marked Row went missing from this file');
      // `dart format` is entitled to move a trailing comment onto its own line
      // underneath the call it annotates, so walk up to the nearest `Row(`
      // instead of assuming the two share a line.
      for (var i = markerIndex; i >= 0; i--) {
        if (source[i].contains('Row(')) return i + 1;
      }
      fail('no `Row(` at or above the marker in this file');
    }

    testWidgets('resolves file:line from a real Flutter overflow',
        (tester) async {
      // The load-bearing test of #1338. The hand-written dumps above pin the
      // path shapes; this one pins that Flutter still *emits* a resolvable
      // location, that `details.toString()` — the string the collector passes as
      // `fullLog` — still carries it, and that the run directory really is
      // stripped on a real absolute path rather than only on a fabricated one.
      // Measured on Flutter 3.44: `exceptionAsString()` carries the one-line
      // message alone, `toString()` carries the error-causing-widget block, and
      // `toDiagnosticsNode().toStringDeep()` adds only the creator chain.
      final expectedLine = lineOfMarkedRow();

      final overflows = await collectOverflow(
        tester,
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: Row(
                // LOAD-BEARING-ROW
                children: const [SizedBox(width: 400, height: 10)],
              ),
            ),
          ),
        ),
        surfaceSize: const Size(800, 600),
      );

      expect(overflows, hasLength(1));
      final incident = overflows.single;

      expect(
        incident.file,
        'test/util/overflow_probe_test.dart',
        reason: 'the location must arrive normalised and repo-relative — an '
            'absolute path is different bytes on every machine, so it cannot be '
            'a ratchet key or a join column. Got "${incident.file}".',
      );
      expect(
        incident.line,
        expectedLine,
        reason: 'the location must name the widget Flutter blamed, not some '
            'ancestor from the creator chain',
      );
      expect(incident.widget, 'Row');
      expect(incident.site, 'test/util/overflow_probe_test.dart:$expectedLine');
      expect(incident.pixels, closeTo(300, 1));
      expect(incident.side, 'right');
    });
  });
}
