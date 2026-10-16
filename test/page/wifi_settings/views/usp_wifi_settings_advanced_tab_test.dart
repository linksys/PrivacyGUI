import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../../mocks/test_data/scenes/wifi_settings_scene_data.dart';
import '../../../util/app_test_fonts.dart';

const _mlo = 'Device.X_LINKSYS_Mesh.MLOEnabled';
const _mloStatus = 'Device.X_LINKSYS_Mesh.MLOStatus';
const _client = 'Device.X_LINKSYS_Mesh.ClientSteeringEnabled';
const _node = 'Device.X_LINKSYS_Mesh.NodeSteeringEnabled';
const _dfs2 = 'Device.WiFi.Radio.2.IEEE80211hEnabled';

/// A router the real service reads and writes: every Set applies, and every
/// Get answers from [values].
class _Router extends Fake implements UspClient {
  _Router(this.values);

  final Map<String, Object?> values;
  final sets = <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> get(List<String> paths,
      {RequestPriority? priority, bool fresh = false}) async {
    return {
      for (final p in paths)
        if (p == 'Device.WiFi.Radio.*.IEEE80211hEnabled')
          _dfs2: values[_dfs2]
        else if (values.containsKey(p))
          p: values[p]
    };
  }

  @override
  Future<Map<String, dynamic>> set(Object pathOrParams,
      {dynamic singleValue, bool allowPartial = false}) async {
    final params = Map<String, dynamic>.from(pathOrParams as Map);
    sets.add(params);
    for (final e in params.entries) {
      values[e.key] = e.value == true ? '1' : '0';
    }
    return {
      'success': true,
      'result': {'data': params},
    };
  }
}

/// The WiFi Advanced tab on the real page: what its switches show, and what a
/// save does with them — steering (#1661) and MLO (#1692) beside DFS.
///
/// The Advanced notifier and service are the real ones over a fake router, so
/// a tap on a switch and a tap on Save go through the code a user's would.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  late _Router router;
  late List<RecoveryContext> recoveries;

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() {
    recoveries = [];
    router = _Router({
      _dfs2: '0',
      _client: '0',
      _node: '1',
      _mlo: '0',
      _mloStatus: 'Disabled',
    });
  });

  Finder switchWith(String identifier) => find
      .byWidgetPredicate((w) => w is AppSwitch && w.identifier == identifier);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpAdvanced(WidgetTester tester,
      {bool mloOffered = true}) async {
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
        uspWifiAdvancedServiceProvider
            .overrideWithValue(UspWifiAdvancedService(router)),
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
      await pumpAdvanced(tester);

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
      router.values
        ..remove(_mlo)
        ..remove(_mloStatus);
      await pumpAdvanced(tester, mloOffered: false);

      expect(switchWith('wifi-advanced-mlo'), findsNothing);
      expect(find.text('Multi-Link Operation'), findsNothing);
      expect(switchWith('wifi-advanced-client-steering'), findsOneWidget);
      expect(switchWith('wifi-advanced-dfs'), findsOneWidget);
    });

    testWidgets('the status the router reports is shown on the card',
        (tester) async {
      router.values
        ..[_mlo] = '1'
        ..[_mloStatus] = 'Active';
      await pumpAdvanced(tester);

      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('WPA3'), findsNothing,
          reason: 'the hint is for Inactive only');
    });

    testWidgets('Inactive says why, in FW\'s words', (tester) async {
      router.values
        ..[_mlo] = '1'
        ..[_mloStatus] = 'Inactive';
      await pumpAdvanced(tester);

      expect(find.text('Inactive'), findsOneWidget);
      expect(
          find.text('Use the same Wi-Fi name, password and WPA3 security on '
              '2.4 GHz and 5 GHz.'),
          findsOneWidget);
    });

    testWidgets(
        'a steering-only save writes one Set and waits for no reconnect',
        (tester) async {
      await pumpAdvanced(tester);

      await tester.tap(switchWith('wifi-advanced-client-steering'));
      await settle(tester);
      await save(tester);

      expect(router.sets, [
        {_client: true}
      ]);
      expect(recoveries, isEmpty,
          reason: 'steering is applied without a radio restart, so the browser '
              'never loses the router and there is nothing to wait for');
      expect(find.text('WiFi settings saved'), findsOneWidget);
    });

    testWidgets('a save that changes DFS still waits for the radios',
        (tester) async {
      await pumpAdvanced(tester);

      await tester.tap(switchWith('wifi-advanced-dfs'));
      await settle(tester);
      await save(tester);

      expect(recoveries.map((r) => r.trigger),
          [RecoveryTrigger.operationalWifiChange]);
    });

    testWidgets('an MLO-only save waits for the Wi-Fi restart too',
        (tester) async {
      await pumpAdvanced(tester);

      await tester.tap(switchWith('wifi-advanced-mlo'));
      await settle(tester);
      await save(tester);

      expect(router.sets, [
        {_mlo: true}
      ]);
      expect(recoveries.map((r) => r.trigger),
          [RecoveryTrigger.operationalWifiChange],
          reason: 'FWDEV#201: an MLO change restarts Wi-Fi for about 60 s');
    });

    testWidgets(
        'MLO, DFS and steering changed together: one Set, one reconnect wait',
        (tester) async {
      await pumpAdvanced(tester);

      await tester.tap(switchWith('wifi-advanced-node-steering'));
      await tester.tap(switchWith('wifi-advanced-mlo'));
      await tester.tap(switchWith('wifi-advanced-dfs'));
      await settle(tester);
      // On WPA2 bands the switch turns on but MLO cannot run (bench).
      router.values[_mloStatus] = 'Inactive';
      await save(tester);

      expect(router.sets, [
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
