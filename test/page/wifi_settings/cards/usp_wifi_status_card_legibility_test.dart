@Tags(['layout-gate'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_status_card.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../util/app_test_fonts.dart';

/// Row-legibility regression for [UspWifiStatusCard] (#1251, T13b).
///
/// The Channel row and the AP row used `context.colWidth(2)` / `colWidth(1)` to
/// size fixed columns. That helper is screen-derived: inside the dashboard card
/// the grid shrinks to 260.5px (span-4 @ 601px, density design §1.6) while
/// `colWidth` keeps answering a page-scale question, so the fixed columns
/// over-claimed and the value/SSID was clipped by the card surface's
/// `Clip.antiAlias` with no `RenderFlex` overflow raised — invisible to the
/// #1183 gate (§2.8). These assertions therefore live outside the gate.
///
/// Every case pumps on a WIDE surface (so a screen-derived width could NOT
/// coincidentally pass) and constrains only the card to the narrowest width.
/// Real fonts are loaded so "fits on one line" is measured against real glyphs.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  const wideSurface = Size(1400, 900);

  // Narrowest realization of a span-4 card: 260.5px at a 601px screen
  // (density design §1.6, line 229). Kept as a named constant so the intent is
  // legible rather than a magic number.
  const narrowestCardWidth = 260.5;

  WifiData mockWifiData({
    required String channelDisplay,
    required List<WifiAccessPointUIModel> aps,
  }) {
    // channelDisplay is derived from channel + autoChannelEnable; pick values
    // that reproduce the desired string. "149 (Auto)" is a realistic worst
    // case: a 3-digit 5 GHz channel plus the Auto suffix.
    final parts = channelDisplay.endsWith(' (Auto)');
    final channel = int.parse(channelDisplay.replaceAll(' (Auto)', '').trim());
    return WifiData(
      codegenContext: WifiCodegenContext.empty,
      radioModels: [
        WifiRadioUIModel(
          instancePath: 'Device.WiFi.Radio.1.',
          band: '5GHz',
          enable: true,
          transmitPower: -1,
          maxBitRate: 4800,
          channel: channel,
          autoChannelEnable: parts,
          channelBandwidth: '80MHz',
          supportedStandards: '802.11ax',
          accessPoints: aps,
        ),
      ],
    );
  }

  Future<void> pumpCard(WidgetTester tester, WifiData data) async {
    await tester.binding.setSurfaceSize(wideSurface);
    tester.view.physicalSize = wideSurface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.create(
            brightness: Brightness.light,
            seedColor: Colors.blue,
            designThemeBuilder: (c) =>
                CustomDesignTheme.fromJson({'style': 'flat'}),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              // The card fills whatever height its content needs, so give it an
              // unbounded-height slot and only pin the width to the narrowest
              // realization.
              child: SizedBox(
                width: narrowestCardWidth,
                height: 700,
                child: UspWifiStatusCard(wifiData: data),
              ),
            ),
          ),
        ),
      ),
    );
    // The card's tx-power / bit-rate bars use an AppLoader (linear), which
    // animates indefinitely, so pumpAndSettle never settles. A couple of fixed
    // pumps are enough to lay the card out for measurement.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  RenderParagraph paragraphOf(WidgetTester tester, String text) =>
      tester.renderObject<RenderParagraph>(find.text(text));

  /// One line == its rendered height is no taller than its unbounded-width
  /// (by definition one-line) height.
  bool isSingleLine(WidgetTester tester, String text) {
    final p = paragraphOf(tester, text);
    return p.size.height <= p.getMinIntrinsicHeight(double.infinity) + 0.5;
  }

  double labelColumnWidthFor(WidgetTester tester, String labelText) {
    // The label column is the SizedBox that directly wraps the label text
    // inside the card. Scope the search to that ancestor chain so we do not
    // pick up the test's own width wrapper or an icon button's box.
    final sizedBox = tester.widget<SizedBox>(
      find
          .ancestor(
            of: find.text(labelText),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    return sizedBox.width ?? double.infinity;
  }

  group('Channel row value stays legible at the narrowest card width', () {
    testWidgets('a 3-digit Auto channel value renders on one line',
        (tester) async {
      await pumpCard(
        tester,
        mockWifiData(channelDisplay: '149 (Auto)', aps: const []),
      );
      // channelDisplay renders as "149 (Auto)".
      expect(find.text('149 (Auto)'), findsOneWidget);
      expect(isSingleLine(tester, '149 (Auto)'), isTrue,
          reason: 'the Channel value must not be clipped/wrapped by an '
              'over-claiming screen-derived label column');
    });

    testWidgets('the Channel label column tracks the card, not the screen',
        (tester) async {
      // On a 1400px surface, a screen-derived colWidth(2) would be ~330px —
      // far wider than the 260.5px card. A row-derived column must be a
      // fraction of the ~228px the row gets, i.e. well under 150px.
      await pumpCard(
        tester,
        mockWifiData(channelDisplay: '6', aps: const []),
      );
      final labelColWidth = labelColumnWidthFor(tester, 'Channel');
      expect(labelColWidth, lessThan(150.0),
          reason: 'a screen-derived column on a 1400px surface would blow past '
              'this; a row-derived one stays a fraction of the 260.5px card');
    });
  });

  group('AP row keeps the SSID legible at the narrowest card width', () {
    testWidgets('the SSID renders on one line, not starved by fixed columns',
        (tester) async {
      await pumpCard(
        tester,
        mockWifiData(
          channelDisplay: '6',
          aps: const [
            WifiAccessPointUIModel(
              enable: true,
              ssidName: 'Linksys-Home',
              securityMode: 'WPA2-Personal',
              encryptionMode: 'AES',
            ),
          ],
        ),
      );
      expect(find.text('Linksys-Home'), findsOneWidget);
      expect(isSingleLine(tester, 'Linksys-Home'), isTrue,
          reason: 'the SSID Expanded must keep the dominant share of the row; '
              'screen-derived colWidth columns starved it to ~61px');
    });
  });
}
