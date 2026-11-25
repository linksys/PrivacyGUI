import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';
import 'package:privacy_gui/page/_shared/providers/usp_system_monitor_notifier.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/admin/cards/usp_device_info_card.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';
import 'package:privacy_gui/providers/app_settings/temperature_unit.dart';
import 'package:privacy_gui/providers/app_settings/temperature_unit_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_dashboard_cards.dart';
import '../../../mocks/test_data/system_info_test_data.dart';
import '../../../mocks/test_data/system_monitor_test_data.dart';

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

const _baseMac = '74:12:13:21:55:02';

/// The master `devicesDataProvider` publishes on FLWRT 2.0 at login and on every
/// refresh, until DataElements answers — and for good when it answers empty.
/// `Device.Hosts.Host.*.DeviceRole` is gone, so the builder's last resort is the
/// literal `'GATEWAY'` (#1665).
final _gatewayFallbackDevices = DevicesData(
  meshNetwork: MeshNetwork(
    master: MasterNode(deviceId: 'GATEWAY', model: 'M60'),
  ),
);

Widget _buildTestWidget({
  String? baseMacAddress,
  DevicesData? devicesData,
  SystemMonitorState? systemMonitorState,
  String? region = 'TW',
}) {
  return ProviderScope(
    overrides: [
      ...cardOverrides(
        systemMonitorState: systemMonitorState,
        devicesData: devicesData ?? _gatewayFallbackDevices,
        systemInfoData: SystemInfoData(
          model: SystemInfoTestData.create(baseMacAddress: baseMacAddress),
        ),
      ),
      platformRegionProvider.overrideWithValue(region),
    ],
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SizedBox(width: 800, child: UspDeviceInfoCard()),
      ),
    ),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('UspDeviceInfoCard — MAC (#1665)', () {
    testWidgets(
        'shows the router base MAC while the master node is the GATEWAY '
        'fallback', (tester) async {
      await tester.pumpWidget(_buildTestWidget(baseMacAddress: _baseMac));
      await tester.pumpAndSettle();

      expect(find.text('MAC'), findsOneWidget);
      expect(find.text(_baseMac), findsOneWidget);
      expect(find.text('GATEWAY'), findsNothing);
    });

    testWidgets('hides the MAC row when the router reports no base MAC',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('MAC'), findsNothing);
      expect(find.text('GATEWAY'), findsNothing);
    });
  });

  // The headline is the controller's name; the model is a subtitle only when
  // they differ. Since #1751 a controller nobody named is named by its
  // DeviceInfo.HostName, not its model, so the card reads two lines where it
  // read one. `MeshNetworkBuilder` puts the host name in `MasterNode.hostName`
  // (its tests pin that); this pins what the card makes of it.
  group('UspDeviceInfoCard — the controller\'s name (#1751)', () {
    DevicesData masterNamed({String? hostName}) => DevicesData(
          meshNetwork: MeshNetwork(
            master: MasterNode(
              deviceId: 'GATEWAY',
              model: SystemInfoTestData.defaultModel,
              hostName: hostName,
            ),
          ),
        );

    testWidgets('a host name is the headline, and the model its subtitle',
        (tester) async {
      await tester.pumpWidget(
          _buildTestWidget(devicesData: masterNamed(hostName: 'Linksys12345')));
      await tester.pumpAndSettle();

      expect(find.text('Linksys12345'), findsOneWidget);
      expect(find.text(SystemInfoTestData.defaultModel), findsOneWidget,
          reason: 'the model moves to the subtitle, not off the card');
    });

    testWidgets('with no host name, the model is the one headline',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(devicesData: masterNamed()));
      await tester.pumpAndSettle();

      expect(find.text(SystemInfoTestData.defaultModel), findsOneWidget,
          reason: 'headline only: no subtitle repeats it');
    });
  });

  // The router's CPU temperature (#1926), from the system monitor's poll, so
  // it moves without a re-login; the session-cached SystemInfo would not. It
  // sits beside the manufacturer in the hero, above the fold, as a tag the user
  // taps to switch between °C and °F.
  group('UspDeviceInfoCard — temperature (#1926)', () {
    Future<TemperatureUnit?> savedUnit() async {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(pAppSettings);
      return saved == null ? null : AppSettings.fromJson(saved).temperatureUnit;
    }

    testWidgets(
        'shows the latest snapshot\'s CPU temperature in the hero, beside the '
        'manufacturer', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        systemMonitorState: SystemMonitorTestData.state([
          SystemMonitorTestData.snapshot(cpuTemperatureCelsius: 48),
          SystemMonitorTestData.snapshot(cpuTemperatureCelsius: 50),
        ]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('50 °C'), findsOneWidget);
      expect(find.text('48 °C'), findsNothing);
      expect(
          find.ancestor(
              of: find.text('50 °C'), matching: find.byType(HeroBlock)),
          findsOneWidget);
      expect(find.text('TEMPERATURE'), findsNothing,
          reason: 'no longer an InfoGrid item below the fold');
    });

    testWidgets('reads °F where the browser\'s region is the United States',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        region: 'US',
        systemMonitorState: SystemMonitorTestData.state(
            [SystemMonitorTestData.snapshot(cpuTemperatureCelsius: 50)]),
      ));
      await tester.pumpAndSettle();

      expect(find.text('122 °F'), findsOneWidget);
      expect(find.text('50 °C'), findsNothing);
    });

    testWidgets('a tap switches the unit, and the pick is saved',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        systemMonitorState: SystemMonitorTestData.state(
            [SystemMonitorTestData.snapshot(cpuTemperatureCelsius: 50)]),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('50 °C'));
      await tester.pumpAndSettle();

      expect(find.text('122 °F'), findsOneWidget);
      expect(await savedUnit(), TemperatureUnit.fahrenheit);

      await tester.tap(find.text('122 °F'));
      await tester.pumpAndSettle();

      expect(find.text('50 °C'), findsOneWidget);
      expect(await savedUnit(), TemperatureUnit.celsius);
    });

    testWidgets('moves when a new snapshot arrives, with no re-login',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        systemMonitorState: SystemMonitorTestData.state(
            [SystemMonitorTestData.snapshot(cpuTemperatureCelsius: 50)]),
      ));
      await tester.pumpAndSettle();

      ProviderScope.containerOf(tester.element(find.byType(UspDeviceInfoCard)))
          .read(uspSystemMonitorProvider.notifier)
          .pushSnapshot(
              SystemMonitorTestData.snapshot(cpuTemperatureCelsius: 53));
      await tester.pumpAndSettle();

      expect(find.text('53 °C'), findsOneWidget);
      expect(find.text('50 °C'), findsNothing);
    });

    // No sensor row, or -274: the monitor reads null, and the card shows no
    // temperature rather than one it does not have.
    for (final (label, state) in [
      (
        'the latest poll has no reading',
        SystemMonitorTestData.state(
            [SystemMonitorTestData.snapshot(cpuTemperatureCelsius: null)]),
      ),
      ('nothing has been polled yet', const SystemMonitorState()),
    ]) {
      testWidgets('shows no temperature when $label', (tester) async {
        await tester.pumpWidget(_buildTestWidget(systemMonitorState: state));
        await tester.pumpAndSettle();

        expect(find.byType(AppTag), findsNothing);
        expect(
            find.text(SystemInfoTestData.defaultManufacturer), findsOneWidget,
            reason: 'the manufacturer line still renders');
      });
    }
  });
}
