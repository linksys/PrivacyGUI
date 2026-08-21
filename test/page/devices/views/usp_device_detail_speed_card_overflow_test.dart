@Tags(['dashboard-card'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';
import 'package:privacy_gui/util/network_utils.dart';

import '../../../golden_test/golden_framework/mocks/mock_devices.dart';
import '../../../golden_test/page/devices/fixtures/devices_test_data.dart';
import '../../../util/app_test_fonts.dart';
import '../../../util/detail_view_probe.dart';
import '../../../util/overflow_probe.dart';

/// Overflow tests for [DetailSpeedCard]'s caption row (#1302).
///
/// ## Why this file exists
///
/// The card's caption was built as
/// `Row(children: [Icon(size: 16), AppGap.xs(), AppText.labelSmall(label)])`, so
/// the caption carried no flex constraint and sized itself to its natural width.
/// Two of these cards sit in a `Row` of `Expanded`s on the device-detail page, so
/// each gets half the card's width and the caption has nowhere to go: `fr` needs
/// 192dp for `Débit descendant (Download)` where the row has 181dp at a 480px
/// screen and 172dp at 1280px.
///
/// The #1183 overflow gate never sees this: it sweeps `UspWidgetSpecs.all`, which
/// is the dashboard's card registry, and neither detail page is in it. The
/// golden suite renders the row but does not fail on it — an overflowing layout
/// is baked into the baseline PNG and compares clean forever after — so without
/// this file the fix is guarded by nothing that blocks a PR.
///
/// Tagged `dashboard-card` so it does block one: `run_tests.sh` excludes
/// `golden||loc||ui`, and a `ui`-tagged regression test would gate nothing.
///
/// The card is shared with the node-detail page's backhaul throughput row, which
/// pumps it at its own widths — see `usp_node_detail_backhaul_overflow_test.dart`
/// for the caption on the tile above it.
///
/// ## Mutation ledger
///
/// Every group here was shown to fail under a mutation of the code it guards; an
/// overflow test that cannot fail is worse than none, because it reports the
/// shape as pinned.
///
///   | mutation                                        | what failed              |
///   |-------------------------------------------------|--------------------------|
///   | caption's `Expanded` removed (the pre-fix shape) | clean rows: fr +11px@480, +20px@1280, +30px@1241, +91px@320 |
///   | `maxLines: 1` + ellipsis dropped, `Expanded` kept | matching heights: fr@480 [106, 90], pl@320 [90, 106] |
///   | value given `maxLines: 1` + ellipsis             | value stays whole (both cards) |
void main() {
  setUpAll(() async {
    // Real fonts: text widths — and therefore overflow — are meaningless under
    // the Ahem block font.
    await loadAppFonts();
  });

  /// The golden suite's Wi-Fi device. It carries both a downlink and an uplink
  /// rate, which is what makes the page render two speed cards side by side; a
  /// fixture with one rate would render a single full-width card that cannot
  /// overflow, and this whole file would pass vacuously.
  final detail = wifiDetailNoReservation;

  /// Pumps the real device-detail page once at [screenWidth] and returns the
  /// RenderFlex overflows beyond the gate's own tolerance.
  Future<List<OverflowIncident>> overflowsAt({
    required WidgetTester tester,
    required double screenWidth,
    required String tag,
  }) =>
      probeViewOverflow(
        tester,
        view: UspDeviceDetailView(mac: detail.device!.mac),
        overrides: deviceDetailOverrides(detail: detail),
        screenWidth: screenWidth,
        locale: localeForTag(tag),
      );

  /// The widths that carry signal, measured by sweeping all 26 locales against
  /// the pre-fix shape:
  ///
  /// - **1241px** — the D1 desktop-large pinch: the 200px page margins open just
  ///   above 1240px, so a 1241px screen lays the row out *narrower* than a
  ///   1240px one. Worst desktop case (fr +30px).
  /// - **1280px** — the golden suite's desktop coordinate, where #1302 was
  ///   reported (fr +20px).
  /// - **480px** — the golden suite's phone coordinate (fr +11px).
  /// - **320px** — the framework's narrowest supported screen and the absolute
  ///   worst case (fr +91px, and the only width where `fr_CA`, `pl` and `tr`
  ///   overflow at all).
  const widths = <double>[1241.0, 1280.0, 480.0, 320.0];

  group('speed card caption row is clean (#1302)', () {
    // Every locale that overflowed the pre-fix shape anywhere in the sweep. If
    // the row were clean in English but not in these, the fix would rely on
    // English being short.
    //
    // Deliberately the full cross-product, not only the cells that break: the
    // load-bearing ones are the ledger's (fr at all four widths, and fr_CA / pl
    // / tr at 320px), while the rest are the locales closest to breaking, held
    // against a translation growing later. Each cell costs ~40ms.
    for (final tag in ['fr', 'fr_CA', 'pl', 'tr']) {
      for (final width in widths) {
        testWidgets(
          'no overflow at ${width.toStringAsFixed(0)}px in $tag',
          (tester) async {
            final overflows = await overflowsAt(
              tester: tester,
              screenWidth: width,
              tag: tag,
            );
            expect(
              overflows,
              isEmpty,
              reason: 'the speed card caption overflows in $tag at '
                  '${width.toStringAsFixed(0)}px: ${overflows.join(', ')}',
            );
          },
        );
      }
    }
  });

  group('sibling speed cards keep matching heights (#1302)', () {
    // Why the caption ellipsizes on one line instead of wrapping. The two cards
    // are independent `Expanded`s in a `Row`, so a caption that wraps makes only
    // *its* card taller and the pair stops lining up — in `fr` at 480px the
    // wrapped card measured 106dp against its sibling's 90dp. The row cannot fix
    // that for them: `Row` stretches children to its own height, and its height
    // is the tallest child's.
    //
    // These two coordinates are the ones where a wrapping caption actually
    // diverges. `fr` at 320px is not among them: there both captions wrap, so
    // both cards grow to 122dp and stay equal — a real property of that width,
    // not a gap in the matrix.
    for (final (tag, width) in [('fr', 480.0), ('pl', 320.0)]) {
      testWidgets(
        'both cards are the same height in $tag at ${width.toStringAsFixed(0)}px',
        (tester) async {
          await overflowsAt(tester: tester, screenWidth: width, tag: tag);

          final cards = find.byType(DetailSpeedCard);
          expect(
            cards,
            findsNWidgets(2),
            reason: 'the fixture must render both cards — with one card there '
                'is no sibling to line up with and this test would be vacuous',
          );
          final heights = cards
              .evaluate()
              .map((e) => tester.getSize(find.byWidget(e.widget)).height)
              .toSet();
          expect(
            heights,
            hasLength(1),
            reason: 'the two speed cards have different heights in $tag at '
                '${width.toStringAsFixed(0)}px ($heights) — a caption is '
                'wrapping instead of ellipsizing on one line',
          );
        },
      );
    }
  });

  group('speed values stay whole (#1302)', () {
    // The caption may shorten because the number below it carries the reading;
    // that argument only holds while the number itself is never shortened. An
    // ellipsis lands mid-value, and `400 Mbps` clipped to `4… Mbps` misreports
    // the link in a way a missing value does not.
    //
    // Located by the exact formatted strings, derived from the same fixture the
    // page is pumped with, and searched only inside a `DetailSpeedCard`: the
    // page shows the same rates elsewhere, so an unscoped `find.text` would stay
    // satisfied with both cards' values deleted.
    for (final kind in ['downlink', 'uplink']) {
      testWidgets('the $kind value is not clipped', (tester) async {
        final device = detail.device!;
        final kbps =
            kind == 'downlink' ? device.downlinkRate : device.uplinkRate;
        expect(
          kbps,
          isNotNull,
          reason: 'the fixture must carry a $kind rate — the page renders a '
              'speed card only when it does',
        );
        final (:value, unit: _) = NetworkUtils.formatSpeedWithUnit(kbps!);

        await overflowsAt(tester: tester, screenWidth: 320.0, tag: 'fr');

        final finder = find.descendant(
          of: find.byType(DetailSpeedCard),
          matching: find.text(value),
        );
        expect(
          finder,
          findsOneWidget,
          reason: 'the $kind value ($value) must survive the degradation',
        );

        final text = tester.widget<Text>(finder);
        expect(
          text.overflow,
          isNot(TextOverflow.ellipsis),
          reason: 'the $kind value must never ellipsize: an ellipsis lands '
              'mid-number',
        );
        expect(
          text.maxLines,
          isNull,
          reason: 'the $kind value must not be line-capped',
        );
      });
    }
  });
}
