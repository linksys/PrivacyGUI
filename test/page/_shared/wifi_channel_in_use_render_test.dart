import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/usp_widget_specs.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/wifi_channel_dialog.dart';
import 'package:privacy_gui/page/statistics/views/sections/stats_wifi_channels_section.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_probe_ui_models.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/diagnostic_result.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/widgets/step_result_tile.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_status_card.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../mocks/provider_overrides/mock_dashboard_cards.dart';
import '../../mocks/provider_overrides/mock_statistics.dart';
import '../../mocks/test_data/scenes/cards_scene_data.dart';
import '../../util/dashboard/dashboard_card_probe.dart';
import '../../util/overflow_probe.dart';
import '../../util/statistics/stats_section_probe.dart';

// Every place that shows the channel a radio is on prints `ChannelsInUse`, and
// every place about the setting keeps `Channel` (#1782).
//
// The fixture is the swap measured on FW 2.0.4.26103108 (#1295): the 5 GHz
// radio is set to 40, and hostapd's 20/40 MHz coexistence check moved it to
// 36. `Channel` keeps 40, `ChannelsInUse` reads 36. A surface that prints 40
// here prints a channel the radio is not on.
//
// Untagged on purpose: CI excludes `ui`, so a case added to the `ui`-tagged
// `wifi_channel_dialog_test.dart` would never run.
void main() {
  final locale = AppLocalizations.supportedLocales
      .firstWhere((l) => l.languageCode == 'en');

  WifiRadioUIModel radio({int? channelInUse = 36}) => WifiRadioUIModel(
        instancePath: 'Device.WiFi.Radio.2.',
        band: '5GHz',
        enable: true,
        transmitPower: -1,
        maxBitRate: 2400,
        channel: 40,
        channelInUse: channelInUse,
        autoChannelEnable: false,
        channelBandwidth: '80MHz',
        supportedStandards: 'a,n,ac,ax',
        possibleChannels: const [36, 40, 44, 48],
        isDfsEnabled: true,
      );

  WifiData wifiData({int? channelInUse = 36}) => WifiData(
        codegenContext: WifiCodegenContext.empty,
        radioModels: [radio(channelInUse: channelInUse)],
      );

  Widget app(Widget child, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: AppTheme.create(
            brightness: Brightness.light,
            seedColor: Colors.blue,
            designThemeBuilder: (c) =>
                CustomDesignTheme.fromJson({'style': 'flat'}),
          ),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home:
              Scaffold(body: Align(alignment: Alignment.topLeft, child: child)),
        ),
      );

  // The card fills the height it is given, so it needs a bounded one.
  Widget statusCard(WifiData data) => SizedBox(
      width: 400, height: 600, child: UspWifiStatusCard(wifiData: data));

  group('prints the channel in use', () {
    testWidgets('WiFi status card', (tester) async {
      await tester.pumpWidget(app(statusCard(wifiData())));
      await tester.pump();

      expect(find.text('36'), findsOneWidget);
      expect(find.text('40'), findsNothing);
    });

    testWidgets('WiFi status card, unknown channel in use', (tester) async {
      await tester.pumpWidget(app(statusCard(wifiData(channelInUse: null))));
      await tester.pump();

      expect(find.text('--'), findsOneWidget);
      expect(find.text('40'), findsNothing);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('WiFi Performance card, Channels tab', (tester) async {
      final l = await AppLocalizations.delegate.load(locale);
      const cardId = 'wifi_performance';
      final spec = UspWidgetSpecs.all.firstWhere((s) => s.id == cardId);
      final desktop = desktopCaseFor(spec);
      final height = dashboardCardHeight(
          spec.getConstraints(DisplayMode.normal).minHeightRows);
      await setLayoutSurface(tester, Size(desktop.screenWidth, height));
      await tester.pumpWidget(buildDashboardCardApp(
        cardId: cardId,
        locale: locale,
        screenWidth: desktop.screenWidth,
        cardWidth: desktop.cardWidth,
        cardHeight: height,
        tabIndex: 2,
        extraOverrides: cardOverrides(
            wifiData: wifiData(), devicesData: testDevicesEmptyData),
      ));
      await settleIgnoringAnimations(tester);

      expect(find.text('${l.channel} 36  ·  80MHz'), findsOneWidget);
      expect(find.textContaining('${l.channel} 40'), findsNothing);
    });

    testWidgets('Statistics, WiFi Channels section', (tester) async {
      final l = await AppLocalizations.delegate.load(locale);
      await probeSectionOverflow(
        tester,
        section: const StatsWifiChannelsSection(),
        screenWidth: 905.0,
        locale: locale,
        overrides: statisticsOverrides(wifiData: wifiData()),
      );

      expect(find.text('${l.channel} 36  ·  80MHz'), findsOneWidget);
      expect(find.textContaining('${l.channel} 40'), findsNothing);
    });

    group('Unified diagnostics, WiFi signal result', () {
      WifiSignalCheckUIModel result({int? channelInUse = 36}) =>
          WifiSignalCheckUIModel(
            rssi: -50,
            channel: 40,
            channelInUse: channelInUse,
            band: '5GHz',
            connectedDevices: 2,
            radios: [
              RadioSignalStatsUIModel(
                instancePath: 'Device.WiFi.Radio.2.',
                band: '5GHz',
                channel: 40,
                channelInUse: channelInUse,
                status: 'Up',
                clientCount: 2,
                averageRssi: -50,
                minRssi: -55,
              ),
            ],
            severity: DiagnosticSeverity.ok,
            titleKey: 'diagnostics_wifi_ok',
            descriptionKey: 'diagnostics_wifi_ok_desc',
          );

      testWidgets('summary and per-radio rows', (tester) async {
        await tester.pumpWidget(
            app(StepResultTile(result: result(), initiallyExpanded: true)));
        await tester.pumpAndSettle();

        expect(find.text('36'), findsOneWidget);
        expect(find.text('5GHz Ch36'), findsOneWidget);
        expect(find.text('40'), findsNothing);
        expect(find.textContaining('Ch40'), findsNothing);
      });

      testWidgets('an unknown channel in use', (tester) async {
        await tester.pumpWidget(app(StepResultTile(
            result: result(channelInUse: null), initiallyExpanded: true)));
        await tester.pumpAndSettle();

        expect(find.text('--'), findsOneWidget);
        expect(find.text('5GHz Ch--'), findsOneWidget);
        expect(find.text('40'), findsNothing);
        expect(find.text('0'), findsNothing);
      });
    });
  });

  group('Channel dialog', () {
    /// Opens [WifiChannelDialog] for [r]; the record it pops is in [result].
    Future<void> openDialog(WidgetTester tester, WifiRadioUIModel r,
        void Function(({int channel, bool autoChannel})?) result) async {
      await tester.pumpWidget(app(Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result(
              await showDialog<({int channel, bool autoChannel})>(
                  context: context,
                  builder: (_) => WifiChannelDialog(radio: r))),
          child: const Text('open'),
        ),
      )));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('"Currently using" is the channel in use', (tester) async {
      final l = await AppLocalizations.delegate.load(locale);
      await openDialog(tester, radio(), (_) {});

      expect(find.text(l.channelCurrentlyUsing(36)), findsOneWidget);
      expect(find.text(l.channelCurrentlyUsing(40)), findsNothing);
    });

    testWidgets('an unknown channel in use claims no channel', (tester) async {
      final l = await AppLocalizations.delegate.load(locale);
      await openDialog(tester, radio(channelInUse: null), (_) {});

      expect(find.text(l.channelCurrentlyUsing(40)), findsNothing);
      expect(find.text(l.channelCurrentlyUsing(0)), findsNothing);
    });

    testWidgets('selects the configured channel', (tester) async {
      await openDialog(tester, radio(), (_) {});

      expect(
          tester.widget<AppDropdown<int>>(find.byType(AppDropdown<int>)).value,
          40);
    });

    testWidgets('switching to Auto returns the configured channel',
        (tester) async {
      final l = await AppLocalizations.delegate.load(locale);
      ({int channel, bool autoChannel})? returned;
      await openDialog(tester, radio(), (r) => returned = r);

      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.apply));
      await tester.pumpAndSettle();

      expect(returned, (channel: 40, autoChannel: true));
    });
  });
}
