import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/admin/cards/usp_device_info_card.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_dashboard_cards.dart';
import '../../../mocks/test_data/system_info_test_data.dart';

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

Widget _buildTestWidget({String? baseMacAddress}) {
  return ProviderScope(
    overrides: cardOverrides(
      devicesData: _gatewayFallbackDevices,
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
}
