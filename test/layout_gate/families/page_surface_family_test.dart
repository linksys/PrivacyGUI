@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_active_leases_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_server_info_card.dart';
import 'package:privacy_gui/page/wifi_settings/views/components/wifi_network_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../util/dashboard/dashboard_card_probe.dart'
    show kMinSupportedScreenWidth;
import '../sweep.dart';
import 'page_surface_cases.dart';
import 'page_surface_family.dart';

/// The content box ui_kit grants a page at [screen] — the quantity the sweep's
/// widths are chosen against.
///
/// Calls `AppLayoutConfig.margin` rather than restating the six margins, for the
/// reason `stats_section_probe.dart:41` gives: a copy of production's numbers is a
/// second source of truth that goes stale without failing.
double _contentWidth(double screen) =>
    screen - AppLayoutConfig.margin(screen) * 2;

/// The page family's oracle (#1349).
///
/// `layout-gate` and **not** `overflow`, like the three oracles before it
/// (`ratchet_test.dart`, `sweep_test.dart`, `dashboard_card_gate_test.dart`): the
/// `overflow` tag means "pumps cells and asserts zero overflow", and this file
/// asserts things *about* a sweep. The arithmetic in the skill doc — `--tags
/// overflow` measures exactly what naming the sweep files measures — is what would
/// break if this joined the pre-commit selector.
///
/// ## What this file is for, and why the sweep cannot do its job
///
/// `page_surface_overflow_test.dart` is green when two pages fit. It is *also*
/// green when two pages never render: `PageSurfaceCase.requires` is what stands
/// between those, and a list is deletable in silence. That is #1364/#1366 stated
/// once more — three separate premises were emptied and 102, 1,368 and 80 tests
/// respectively stayed green — with the difference that this family was written
/// after the lesson, so the premise is a value from the first line. A value is only
/// enforceable if something pins it, and nothing in the sweep can: the sweep reads
/// the lists, so a sweep assertion over them would be the lists agreeing with
/// themselves.
///
/// So the three things pinned here are the three the sweep structurally cannot:
///
/// 1. **Each case's premise, by name.** Emptying or shrinking `requires` fails
///    here, at the list, not later at a page nobody noticed had stopped rendering.
/// 2. **That the premise is an assertion rather than coverage** — the one test
///    that pumps. A loader is measured: zero overflow, and red anyway.
/// 3. **That `kPageSweepWidths` is what its doc claims** — every width at which
///    the content box narrows, computed from ui_kit rather than read from the
///    table in the family's header, which is prose and cannot fail.
void main() {
  group('the pilot swept two pages, and which two is a decision', () {
    test('kPageSurfaceCases holds exactly the two pages #1349 scoped', () {
      expect(
        kPageSurfaceCases.map((c) => c.id),
        ['dhcp', 'wifi_settings'],
        reason: 'the pilot is two pages by design — a plain form page and a '
            'provider-heavy one, bracketing the cost range §1.2 records. A third '
            'case here is not a bigger pilot, it is a graduated gate: §8 wants the '
            'cost number and the recommendation in §11 revisited first, and the '
            'page it adds has to be at zero before it arrives.',
      );
    });

    test('every case has a distinct id, since the id is the sweep name', () {
      expect(
        kPageSurfaceCases.map((c) => c.id).toSet(),
        hasLength(kPageSurfaceCases.length),
        reason: 'the id becomes `page.<id>`, which namespaces the coverage '
            'baseline. Two cases sharing one would collide every cell of both.',
      );
    });
  });

  group('each case carries its premise as a value', () {
    // The generic half: whatever the cases are, none of them may be premise-free.
    // Written over the list rather than per case so a case added without a premise
    // fails here instead of sweeping 208 green cells over a spinner.
    for (final page in kPageSurfaceCases) {
      test('page.${page.id} requires at least one widget of the loaded page',
          () {
        expect(
          page.requires,
          isNotEmpty,
          reason: 'both pilot pages open with `if (isLoading) return '
              'AppLoader()`. A loader is a centred box that cannot overflow at '
              'any width in any locale, so an empty `requires` does not turn the '
              'sweep red — it turns 208 cells green over nothing.',
        );
      });

      test('page.${page.id} forbids the loading path outright', () {
        expect(
          page.forbids,
          contains(AppLoader),
          reason: '`requires` already excludes a loader by implication; naming '
              'it here is what makes the failure say "this page is still '
              'loading" rather than "a card is missing".',
        );
      });
    }

    // The specific half: the lists themselves, by name. This is the assertion that
    // fails when a `requires` is quietly narrowed to one cheap widget — which is
    // the shape #1366 found, where the premise was still present and no longer
    // said anything.
    test('page.dhcp requires all three of its cards, not just the first', () {
      expect(
        kDhcpPageCase.requires,
        containsAll(<Type>[
          UspDhcpServerInfoCard,
          UspDhcpActiveLeasesCard,
          UspDhcpReservationsDetailCard,
        ]),
        reason: 'the three cards are three independent presentations fed by '
            'three different providers. Requiring only one leaves the other two '
            'free to fall back to a spinner while this sweep reports a clean '
            'page — and the reservations card is the one #1349 found overflowing '
            'at 320px and 601px, so dropping it drops the regression test for '
            'the fix that shipped with this sweep.',
      );
    });

    test('page.wifi_settings requires the card its widths actually stress', () {
      expect(
        kWifiSettingsPageCase.requires,
        contains(WifiNetworkCard),
        reason: 'quick-setup-off renders four of these, one per band, and they '
            'are the page content that responds to width. A premise naming only '
            'the page shell would hold against a shell with no cards in it.',
      );
    });
  });

  group('the premise is an assertion, not coverage', () {
    // One cell, pumped. The distinction cf91cddc named — a hook that opens the
    // surface runs without ever being able to fail — is only observable by
    // measuring a cell that *should* fail, so this is the one test here that pays
    // for a pump. It costs a `settleIgnoringAnimations` timeout, because a loader
    // animates forever and that is the point of it.
    testWidgets('a page that never left its loader is measured, and fails',
        (tester) async {
      // Deliberately not one of the two real cases: this is the tree a drifted
      // fixture produces, and it has to be constructible without a drifted
      // fixture. `requires` is dhcp's, so the failure names a real card.
      final stuckOnLoader = PageSurfaceCase(
        id: 'loader_only',
        view: () => const Center(child: AppLoader()),
        overrides: () => const [],
        requires: kDhcpPageCase.requires,
        forbids: kDhcpPageCase.forbids,
      );
      final family = PageSurfaceFamily(stuckOnLoader);
      final cell = family.enumerateCells().first;

      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: cell,
      );

      // Both halves matter, and the first is why the second is needed at all.
      expect(
        verdict.significant,
        isEmpty,
        reason:
            'a loader fits at 320px in every locale — which is exactly why a '
            'sweep that only asked "did a RenderFlex overflow" would call this '
            'cell clean and move on',
      );
      expect(
        verdict.error,
        isNotNull,
        reason:
            'the premise is what turns a clean-but-meaningless cell red. If '
            'this passes with a null error, `onCellSettled` has stopped '
            'asserting and both real sweeps are green over whatever renders.',
      );
      expect(
        verdict.error.toString(),
        contains('other than the loaded page'),
        reason: 'the failure has to say what went wrong with the fixture, not '
            'just that something did',
      );
    });

    testWidgets('a page that did render its premise is clean', (tester) async {
      // The control. Without it, the test above is satisfied by an `onCellSettled`
      // that throws unconditionally — which would fail every real cell, but only
      // after someone ran the real sweeps.
      final rendersItsPremise = PageSurfaceCase(
        id: 'premise_met',
        view: () => const Placeholder(),
        overrides: () => const [],
        requires: const [Placeholder],
        forbids: const [AppLoader],
      );
      final family = PageSurfaceFamily(rendersItsPremise);

      final verdict = await measureOverflowCell(
        tester,
        family: family,
        cell: family.enumerateCells().first,
      );

      expect(verdict.error, isNull, reason: verdict.summary);
      expect(verdict.significant, isEmpty);
    });
  });

  group('kPageSweepWidths is derived from ui_kit, not sampled', () {
    test('content narrows at every width the sweep calls a step-up', () {
      for (final width in const [601.0, 1241.0, 1441.0, 1681.0]) {
        expect(
          _contentWidth(width),
          lessThan(_contentWidth(width - 1)),
          reason: '$width is in the sweep because the page gets a *narrower* '
              'content box there than one pixel earlier. If ui_kit\'s margins '
              'changed, this width no longer means what the family\'s header '
              'table says and the list has to be re-derived.',
        );
        expect(kPageSweepWidths, contains(width));
      }
    });

    test('no step-up is missing from the list', () {
      // Enumerated, not sampled — #1225's lesson applied to a different axis. A
      // width list that missed a step-up would be a sweep whose worst case is
      // outside it, and no test of the widths it *does* hold could say so.
      final missed = <double>[];
      for (var width = kMinSupportedScreenWidth + 1; width <= 2560; width++) {
        final narrows = _contentWidth(width) < _contentWidth(width - 1);
        if (narrows && !kPageSweepWidths.contains(width)) missed.add(width);
      }
      expect(
        missed,
        isEmpty,
        reason: 'ui_kit narrows the content box at these widths and the sweep '
            'does not visit them, so each is a pinch the gate cannot see. Add '
            'them to kPageSweepWidths and re-pin both cell counts (each width '
            'is 26 cells per page).',
      );
    });

    test('the two coordinates golden CI shares are in the list', () {
      // §8's join key is `file:line`, but the join is only *checkable* where both
      // sides measured the same screen. 480 and 1280 are the golden pipeline's
      // phone and desktop widths; dropping either leaves "the gate found what CI
      // missed" an unfalsifiable claim.
      expect(kPageSweepWidths, containsAll(<double>[480, 1280]));
    });

    test('the product floor is the floor the card sweep enumerates from', () {
      expect(
        kPageSweepWidths.first,
        kMinSupportedScreenWidth,
        reason: '320px is a product commitment (density design §2.3), not a '
            'number this family chose. Reading it from the card probe is what '
            'keeps the two sweeps agreeing about where the product ends.',
      );
    });
  });

  group('each page pins its own cell count', () {
    // The pins live in the suite, as `runOverflowSweep` requires. What is checkable
    // here is the arithmetic behind them: the suite says 208 twice, and 208 is
    // 8 widths × 26 locales — so a locale added to the app fails the suite's pin
    // and this test says why.
    test('208 is 8 widths x 26 locales, for both pages', () {
      expect(
        kPageSweepWidths.length * AppLocalizations.supportedLocales.length,
        208,
        reason: 'the two pins in page_surface_overflow_test.dart are this '
            'product spelled as a literal. If the app ships another locale, both '
            'pins move together — and that is a coverage change worth an '
            'explicit edit, which is why the pin is a literal in the first place.',
      );
      for (final page in kPageSurfaceCases) {
        expect(PageSurfaceFamily(page).enumerateCells(), hasLength(208));
      }
    });

    test('every cell measures the width its axis names', () {
      // The axis value is a string in the cell id and a double in the surface;
      // they are written from the same loop variable today, and a cell whose id
      // disagreed with its viewport would file every finding under the wrong
      // coordinate.
      for (final page in kPageSurfaceCases) {
        final family = PageSurfaceFamily(page);
        for (final cell in family.enumerateCells()) {
          expect(
            cell.axes['screen_px'],
            cell.surfaceSize.width.toStringAsFixed(0),
            reason: '${overflowSweepCellId(family, cell)} was laid out at '
                '${cell.surfaceSize.width}px',
          );
          expect(cell.surfaceSize.height, kPageSweepHeight);
        }
      }
    });
  });
}
