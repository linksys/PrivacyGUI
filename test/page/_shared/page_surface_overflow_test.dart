@Tags(['layout-gate', 'overflow'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';

import '../../layout_gate/collector.dart';
import '../../layout_gate/families/page_surface_cases.dart';
import '../../layout_gate/families/page_surface_family.dart';
import '../../layout_gate/locale_tag.dart';
import '../../layout_gate/surface.dart';
import '../../layout_gate/sweep.dart';
import '../../util/app_test_fonts.dart';
import '../../util/dashboard/text_readability_probe.dart';

/// The overflow gate's page sweep — the #1349 pilot.
///
/// Two whole pages × 8 screen widths × 26 locales, declared through the shared
/// runner. Everything about *which* cells exist and *how* one is hosted lives in
/// `test/layout_gate/families/page_surface_family.dart`; which two pages, and why
/// those two, lives in `page_surface_cases.dart`. This file is the declaration and
/// the two pins.
///
/// ## Why the pins are literals
///
/// `8 × 26 = 208` is the enumeration restating itself. The literal is what stands
/// between "the pilot deliberately swept 8 widths" and "someone dropped four
/// widths and the suite stayed green in half the time" — the same argument
/// `sweep.dart`'s header makes for every other pin in this family, and the reason
/// `expectedCellCount` is required rather than defaulted.
///
/// ## Where this file sits in the gate
///
/// `layout-gate` makes it PR-blocking (`run_tests.sh` excludes `golden||loc||ui`
/// and neither of those is here). `overflow` puts it in the pre-commit selector,
/// which it earns by pumping cells and asserting zero overflow — and which is the
/// tag whose cost this pilot measured. See §11 of
/// `doc/testing/overflow_gate_architecture.md` for the measurement and the
/// recommendation it supports.
///
/// ## Why `test/page/_shared/`, which §11.1 excludes as a *surface*
///
/// Two different `_shared`s, and the collision is worth stating because it reads
/// as a contradiction. §11.1 excludes **`lib/page/_shared/`** — production
/// components carrying golden-CI debt, which §8's graduation rule keeps out of a
/// local probe until they are fixed. This is **`test/page/_shared/`**, the repo's
/// existing location for a suite no single page owns (`test/page/_shared/utils/`
/// is the same convention), and it is where §3.1's "suites stay next to the code
/// under test" lands when the code under test is *two* pages and will be more.
/// Nothing in `lib/page/_shared/` is swept here.
///
/// It is deliberately the all-pages bucket: pages graduate one at a time (§11.3),
/// and a per-page suite file would put the shared `loadAppFonts` setup and the
/// readability guard below into as many copies as there are pages. The registry
/// consequence is recorded in `tool/overflow_baseline.sh` — one baseline id
/// (`page`) holds every family in this file, the way `card` holds three.
void main() {
  final localizationsByTag = <String, AppLocalizations>{};

  setUpAll(() async {
    // Real fonts. Under Ahem every glyph is an identical box, so every width this
    // sweep measures would be fiction (rule 7 of the skill's new-probe section).
    await loadAppFonts();

    for (final locale in AppLocalizations.supportedLocales) {
      localizationsByTag[localeTag(locale)] =
          await AppLocalizations.delegate.load(locale);
    }
  });

  // 8 widths × 26 locales. Both pages sweep the same axis, so both pins are the
  // same number — which is a fact about the axis, not a copy: a page that ever
  // needs its own width list changes only its own pin.
  runOverflowSweep(
    family: PageSurfaceFamily(kDhcpPageCase),
    expectedCellCount: 208,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kWifiSettingsPageCase),
    expectedCellCount: 208,
  );

  // The readability assertion rule 4 of the skill requires beside an overflow
  // assertion, aimed at the one site this pilot changed. It names no cell, so the
  // committed `page` baseline stays 416 rows and `overflow_baselines.md` §5's "17
  // of 17 collector calls name a cell" stays true: this test does not install the
  // collector at all, because its oracle is not "did a RenderFlex overflow".
  group('readability at the site the pilot fixed', () {
    /// How many lines the reservations title may wrap onto before the wrap stops
    /// being the better trade.
    ///
    /// One line of headroom over the deepest coordinate measured (`ar`, four lines
    /// at both widths — the counts beside the `wrapped` assertion below were
    /// re-measured against this ceiling and still hold), which is the whole design:
    /// tight enough that a real regression trips it, loose enough that a one-line
    /// drift from an ARB edit does not send someone to a fixture they did not
    /// break. It is not a design token — nothing in the app enforces it — so
    /// raising it is a deliberate act with the new number recorded here.
    const kTitleLineCeiling = 5;

    testWidgets('the reservations title stays whole where the Flexible wraps',
        (tester) async {
      final failures = <String>[];
      final wrapped = <String>[];

      // The two widths the defect appeared at, and the reason the pair is needed:
      // 601px is where the page's two-column band hands this card a *narrower*
      // box than 320px's one-column band does (+141px against +113px), so the
      // narrower screen is not the worse case for this site.
      for (final width in const [320.0, 601.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          // Its own key per pump, invariant 1's other half: a tree pumped outside
          // `runOverflowSweep` needs a fresh subtree or its own test.
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('dhcp-title-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kDhcpPageCase.view(),
              locale: locale,
              overrides: kDhcpPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final label = localizationsByTag[tag]!.dhcpReservations;
          // Scoped to the card, not `find.text` alone: the same string is the
          // page's own section heading in some locales, and a bare literal finder
          // would measure whichever came first in tree order.
          final title = find.descendant(
            of: find.byType(UspDhcpReservationsDetailCard),
            matching: find.text(label),
          );
          if (title.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the title resolved to '
                '${title.evaluate().length} widgets, so nothing was measured');
            continue;
          }

          // Both verdicts, for the reason the chrome sweep records: a mid-word
          // break drops nothing, so `didExceedMaxLines` is blind to it, and an
          // ellipsis leaves every surviving token fitting, so `hasSplitToken` is
          // blind to that.
          final paragraph = tester.paragraphOf(title);
          final lines = tester.textLineCount(title);
          if (lines > 1) wrapped.add('$tag@${width.toInt()}px:${lines}L');
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on '
              '$lines line(s), widest token '
              '${tester.widestTokenWidth(title).toStringAsFixed(1)}px, whole '
              'string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px'
              ' — "$label"';
          // The third verdict, and the one that bounds the dimension the fix
          // actually moved. `lines` was measured into `wrapped` and then only
          // checked for being non-empty, so a wrap of any depth passed: `ar`
          // takes four lines today, and an ARB edit, a font-fallback change or a
          // fixture change that pushed it to twelve — pushing the rest of the card
          // off the visible surface — would leave `failures` empty and this suite
          // green. A wrap is the better trade than an overflow only up to a point,
          // and this is the point.
          if (lines > kTitleLineCeiling) {
            failures.add('$tag @${width.toInt()}px: wrapped onto $lines lines, '
                'past the $kTitleLineCeiling-line ceiling — $numbers');
          }
          if (tester.isTextClipped(title)) {
            failures.add('$tag @${width.toInt()}px: ellipsized — $numbers');
          } else if (tester.hasSplitToken(title)) {
            failures
                .add('$tag @${width.toInt()}px: broken mid-word — $numbers');
          }
        }
      }

      // The premise, as a value rather than a hope — #1364/#1366 one layer down.
      // If no locale wraps at either width, every assertion above passed against a
      // title that fitted on one line, which is a test that cannot fail: the trade
      // the `Flexible` made would be unmeasured and this suite would report it as
      // covered. Kept as a *list* so a failure names what the coverage was.
      //
      // 16 of the 52 coordinates wrap today: `ar` onto four lines at both widths,
      // and `el` `ja` `ko` `ru` `th` `zh` `zh_TW` onto two — `ru` onto *three* at
      // 601px, which is the narrower-content-at-a-wider-screen step showing up in
      // the readability data as well as in the overflow data.
      //
      // The floor only. [kTitleLineCeiling] is the other end, checked per
      // coordinate above: this list being non-empty says the wrap was measured, and
      // says nothing about how deep it went.
      expect(
        wrapped,
        isNotEmpty,
        reason:
            'no locale wrapped this title at 320px or 601px, so nothing here '
            'measured the wrap the #1349 fix introduced — the fixture, the widths '
            'or the string lengths have drifted',
      );

      expect(
        failures,
        isEmpty,
        reason:
            'the #1349 fix traded an overflow for a wrap, and a wrap is only '
            'the better trade while the title stays readable:\n'
            '${failures.join('\n')}',
      );
    });
  });
}
