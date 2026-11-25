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
}) {
  return ProviderScope(
    overrides: cardOverrides(
      systemMonitorState: systemMonitorState,
      devicesData: devicesData ?? _gatewayFallbackDevices,
      systemInfoData: SystemInfoData(
        model: SystemInfoTestData.create(baseMacAddress: baseMacAddress),
      ),
    ),
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
  // it moves without a re-login; the session-cached SystemInfo would not.
  group('UspDeviceInfoCard — temperature (#1926)', () {
    testWidgets('shows the latest snapshot\'s CPU temperature', (tester) async {
      await tester.pumpWidget(_buildTestWidget(
        systemMonitorState: SystemMonitorTestData.state([
          SystemMonitorTestData.snapshot(cpuTemperatureCelsius: 48),
          SystemMonitorTestData.snapshot(cpuTemperatureCelsius: 50),
        ]),
      ));
      await tester.pumpAndSettle();

      // InfoGrid draws its labels upper-cased, as it does SERIAL.
      expect(find.text('TEMPERATURE'), findsOneWidget);
      expect(find.text('50 °C'), findsOneWidget);
      expect(find.text('48 °C'), findsNothing);
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
    // line rather than a temperature it does not have.
    for (final (label, state) in [
      (
        'the latest poll has no reading',
        SystemMonitorTestData.state(
            [SystemMonitorTestData.snapshot(cpuTemperatureCelsius: null)]),
      ),
      ('nothing has been polled yet', const SystemMonitorState()),
    ]) {
      testWidgets('has no temperature row when $label', (tester) async {
        await tester.pumpWidget(_buildTestWidget(systemMonitorState: state));
        await tester.pumpAndSettle();

        expect(find.text('TEMPERATURE'), findsNothing);
        expect(find.text('SERIAL'), findsOneWidget,
            reason: 'the rest of the card still renders');
      });
    }
  });
}
