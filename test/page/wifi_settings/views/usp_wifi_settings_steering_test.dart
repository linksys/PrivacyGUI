import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import '../../../util/app_test_fonts.dart';

class MockUspWifiAdvancedService extends Mock
    implements UspWifiAdvancedService {}

/// The two steering switches on the Advanced tab (#1661), on the real page: what
/// they show, and what a save does with them.
///
/// The Advanced notifier is the real one over a mocked service, so a tap on a
/// switch and a tap on Save go through the same code a user's would.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  late MockUspWifiAdvancedService svc;
  late List<RecoveryContext> recoveries;

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() {
    svc = MockUspWifiAdvancedService();
    recoveries = [];
    when(() => svc.fetchIeee80211h())
        .thenAnswer((_) async => {'Device.WiFi.Radio.2.': false});
    when(() => svc.fetchSteering())
        .thenAnswer((_) async => (clientSteering: false, nodeSteering: true));
    when(() => svc.setSteering(
          clientSteering: any(named: 'clientSteering'),
          nodeSteering: any(named: 'nodeSteering'),
        )).thenAnswer((_) async {});
  });

  Finder switchWith(String identifier) => find
      .byWidgetPredicate((w) => w is AppSwitch && w.identifier == identifier);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpAdvanced(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspWifiSettingsView(initialTab: 1),
      locale: const Locale('en'),
      overrides: [
        // The WiFi tab is a fixed fixture; Advanced is the real notifier.
        uspWifiSettingsProvider
            .overrideWith(() => FixedWifiSettingsNotifier(quickSetupOffState)),
        uspWifiAdvancedProvider.overrideWith(UspWifiAdvancedNotifier.new),
        uspWifiAdvancedServiceProvider.overrideWithValue(svc),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        // A DFS save re-reads L1 afterwards; nothing here is parked on a DFS
        // channel, so an empty read is the honest fixture.
        wifiDataProvider.overrideWith(_EmptyWifiDataNotifier.new),
        appConnectionStateProvider
            .overrideWith(() => _RecordingConnectionNotifier(recoveries)),
      ],
    ));
    await settle(tester);
  }

  group('UspWifiSettingsView - Advanced tab steering', () {
    testWidgets('both switches show the values read from the device',
        (tester) async {
      await pumpAdvanced(tester);

      expect(find.text('Client Steering'), findsOneWidget);
      expect(find.text('Node Steering'), findsOneWidget);
      expect(
          tester
              .widget<AppSwitch>(switchWith('wifi-advanced-client-steering'))
              .value,
          isFalse);
      expect(
          tester
              .widget<AppSwitch>(switchWith('wifi-advanced-node-steering'))
              .value,
          isTrue);
      expect(switchWith('wifi-advanced-dfs'), findsOneWidget,
          reason: 'DFS stays beside them');
    });

    testWidgets(
        'a steering-only save writes one Set and waits for no reconnect',
        (tester) async {
      await pumpAdvanced(tester);

      await tester.tap(switchWith('wifi-advanced-client-steering'));
      await settle(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await settle(tester);

      verify(() => svc.setSteering(clientSteering: true)).called(1);
      verifyNever(() => svc.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          ));
      expect(recoveries, isEmpty,
          reason: 'steering is applied without a radio restart, so the browser '
              'never loses the router and there is nothing to wait for');
      expect(find.text('WiFi settings saved'), findsOneWidget);
    });

    testWidgets('a save that changes DFS still waits for the radios',
        (tester) async {
      when(() => svc.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});
      await pumpAdvanced(tester);

      await tester.tap(switchWith('wifi-advanced-dfs'));
      await settle(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Save'));
      await settle(tester);

      expect(recoveries.map((r) => r.trigger),
          [RecoveryTrigger.operationalWifiChange]);
    });
  });
}

class _EmptyWifiDataNotifier extends WifiDataNotifier {
  @override
  Future<WifiData> build() async => const WifiData.empty();
}

/// Records every recovery the page asks for and declines it, so the test can
/// see whether a save waited for the router without a dialog to drive.
class _RecordingConnectionNotifier extends AppConnectionStateNotifier {
  _RecordingConnectionNotifier(this.calls);

  final List<RecoveryContext> calls;

  @override
  bool enterWaiting({required RecoveryContext context}) {
    calls.add(context);
    return false;
  }
}
