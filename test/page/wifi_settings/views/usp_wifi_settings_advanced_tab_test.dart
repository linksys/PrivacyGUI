import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import '../../../util/app_test_fonts.dart';

class MockUspWifiAdvancedService extends Mock
    implements UspWifiAdvancedService {}

/// The plan builder never touches the client; this only satisfies its type.
class _NoUsp extends Mock implements UspClient {}

const _mlo = 'Device.X_LINKSYS_Mesh.MLOEnabled';
const _node = 'Device.X_LINKSYS_Mesh.NodeSteeringEnabled';
const _client = 'Device.X_LINKSYS_Mesh.ClientSteeringEnabled';
const _dfs2 = 'Device.WiFi.Radio.2.IEEE80211hEnabled';

/// The WiFi Advanced tab on the real page: what its switches show, and what a
/// save does with them — steering (#1661) and MLO (#1692) beside DFS.
///
/// The Advanced notifier is the real one over a mocked service, so a tap on a
/// switch and a tap on Save go through the code a user's would. The Set the
/// save builds is the real service's [UspWifiAdvancedService.planSave]; only
/// sending it and reading it back go through the mock.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  late MockUspWifiAdvancedService svc;
  late List<RecoveryContext> recoveries;
  late List<Map<String, dynamic>> sets;
  late MloStatus mloStatus;

  setUpAll(() async {
    await loadAppFonts();
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(const WifiAdvancedSettings.empty());
  });

  setUp(() {
    svc = MockUspWifiAdvancedService();
    recoveries = [];
    sets = [];
    mloStatus = MloStatus.disabled;
    when(() => svc.fetchIeee80211h())
        .thenAnswer((_) async => {'Device.WiFi.Radio.2.': false});
    when(() => svc.fetchSteering())
        .thenAnswer((_) async => (clientSteering: false, nodeSteering: true));
    when(() => svc.fetchMlo())
        .thenAnswer((_) async => (enabled: false, status: mloStatus));
    when(() => svc.planSave(
          original: any(named: 'original'),
          current: any(named: 'current'),
          forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
        )).thenAnswer((inv) {
      final real = UspWifiAdvancedService(_NoUsp()).planSave(
        original: inv.namedArguments[#original] as WifiAdvancedSettings,
        current: inv.namedArguments[#current] as WifiAdvancedSettings,
        forceAutoChannelPaths:
            inv.namedArguments[#forceAutoChannelPaths] as List<String>,
      );
      return WifiWritePlan(
        params: real.params,
        proof: real.proof,
        send: () async {
          sets.add(real.params);
          return WifiWriteOutcome.confirmed;
        },
      );
    });
    when(() => svc.isApplied(any())).thenAnswer((_) async => true);
  });

  Finder switchWith(String identifier) => find
      .byWidgetPredicate((w) => w is AppSwitch && w.identifier == identifier);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    int tab = 1,
    bool mloOffered = true,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: UspWifiSettingsView(initialTab: tab),
      locale: const Locale('en'),
      overrides: [
        // The WiFi tab is a fixed fixture; Advanced is the real notifier.
        uspWifiSettingsProvider
            .overrideWith(() => FixedWifiSettingsNotifier(editDirtyState)),
        uspWifiAdvancedProvider.overrideWith(UspWifiAdvancedNotifier.new),
        uspWifiAdvancedServiceProvider.overrideWithValue(svc),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        deviceCapabilitiesProvider.overrideWithValue(
            DeviceCapabilities({if (mloOffered) DeviceCapability.wifiMlo})),
        // A save that restarts Wi-Fi waits this long before reading back.
        mloRestartSettleProvider.overrideWithValue(Duration.zero),
        wifiReadBackIntervalProvider
            .overrideWithValue(const Duration(milliseconds: 10)),
        // A save that restarts Wi-Fi re-reads L1 afterwards; nothing here is
        // parked on a DFS channel, so an empty read is the honest fixture.
        wifiDataProvider.overrideWith(_EmptyWifiDataNotifier.new),
        appConnectionStateProvider
            .overrideWith(() => _RecordingConnectionNotifier(recoveries)),
      ],
    ));
    await settle(tester);
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'Save'));
    await settle(tester);
  }

  group('UspWifiSettingsView - Advanced tab', () {
    testWidgets('the switches show the values read from the router',
        (tester) async {
      await pumpPage(tester);

      expect(find.text('Client Steering'), findsOneWidget);
      expect(find.text('Node Steering'), findsOneWidget);
      expect(find.text('Multi-Link Operation'), findsOneWidget);
      bool valueOf(String id) => tester.widget<AppSwitch>(switchWith(id)).value;
      expect(valueOf('wifi-advanced-client-steering'), isFalse);
      expect(valueOf('wifi-advanced-node-steering'), isTrue);
      expect(valueOf('wifi-advanced-mlo'), isFalse);
      expect(switchWith('wifi-advanced-dfs'), findsOneWidget);
    });

    testWidgets('a router without MLO has no MLO card, and the rest stays',
        (tester) async {
      await pumpPage(tester, mloOffered: false);

      expect(switchWith('wifi-advanced-mlo'), findsNothing);
      expect(find.text('Multi-Link Operation'), findsNothing);
      expect(switchWith('wifi-advanced-client-steering'), findsOneWidget);
      expect(switchWith('wifi-advanced-dfs'), findsOneWidget);
      verifyNever(() => svc.fetchMlo());
    });

    testWidgets('the status the router reports is shown on the card',
        (tester) async {
      mloStatus = MloStatus.active;
      await pumpPage(tester);

      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('WPA3'), findsNothing,
          reason: 'the hint is for Inactive only');
    });

    testWidgets("Inactive says why, in FW's words", (tester) async {
      mloStatus = MloStatus.inactive;
      await pumpPage(tester);

      expect(find.text('Inactive'), findsOneWidget);
      expect(
          find.text('Use the same Wi-Fi name, password and WPA3 security on '
              '2.4 GHz and 5 GHz.'),
          findsOneWidget);
    });

    testWidgets(
        'a WiFi-tab save reads the status again, so Advanced is not stale',
        (tester) async {
      // Inactive on WPA2; the user fixes it on the WiFi tab, as the hint says.
      mloStatus = MloStatus.inactive;
      await pumpPage(tester, tab: 0);
      mloStatus = MloStatus.active;
      await save(tester);

      await tester.tap(find.text('Advanced'));
      await settle(tester);

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Inactive'), findsNothing);
    });

    testWidgets(
        'a steering-only save writes one Set and waits for no reconnect',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(switchWith('wifi-advanced-client-steering'));
      await settle(tester);
      await save(tester);

      expect(sets, [
        {_client: true}
      ]);
      expect(recoveries, isEmpty,
          reason: 'steering is applied without a radio restart, so the browser '
              'never loses the router and there is nothing to wait for');
      expect(find.text('WiFi settings saved'), findsOneWidget);
    });

    testWidgets('a save that changes DFS still waits for the radios',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(switchWith('wifi-advanced-dfs'));
      await settle(tester);
      await save(tester);

      expect(recoveries.map((r) => r.trigger),
          [RecoveryTrigger.operationalWifiChange]);
    });

    testWidgets('an MLO-only save waits for the Wi-Fi restart too',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(switchWith('wifi-advanced-mlo'));
      await settle(tester);
      await save(tester);

      expect(sets, [
        {_mlo: true}
      ]);
      expect(recoveries.map((r) => r.trigger),
          [RecoveryTrigger.operationalWifiChange],
          reason: 'FWDEV#201: an MLO change restarts Wi-Fi for about 60 s');
    });

    testWidgets(
        'MLO, DFS and steering changed together: one Set, one reconnect wait',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(switchWith('wifi-advanced-node-steering'));
      await tester.tap(switchWith('wifi-advanced-mlo'));
      await tester.tap(switchWith('wifi-advanced-dfs'));
      await settle(tester);
      // On WPA2 bands the switch turns on but MLO cannot run (bench).
      mloStatus = MloStatus.inactive;
      await save(tester);

      expect(sets, [
        {_node: false, _mlo: true, _dfs2: true}
      ]);
      expect(recoveries.map((r) => r.trigger),
          [RecoveryTrigger.operationalWifiChange],
          reason: 'MLO restarts Wi-Fi as DFS does');
      expect(find.text('WiFi settings saved'), findsOneWidget);
      expect(find.text('Inactive'), findsOneWidget,
          reason: 'the status is read again after the restart');
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
