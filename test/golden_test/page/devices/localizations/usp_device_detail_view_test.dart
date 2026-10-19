import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/devices/views/usp_device_detail_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../../mocks/provider_overrides/mock_devices.dart';
import '../../../../mocks/test_data/scenes/devices_scene_data.dart';

/// Opens the edit dialog from the pen after the device name (#1691). Found by
/// identifier, not by text, so the step is the same in every locale.
Future<void> _openEditDialog(WidgetTester tester) async {
  await tester.tap(find.bySemanticsIdentifier('device-detail-edit-identity'));
  await pumpOverlayIn(tester);
}

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'device_detail',
      view: () => const UspDeviceDetailView(mac: 'AA:BB:CC:DD:EE:01'),
      shell: ShellType.custom,
      height: 1200,
      states: {
        'wifi_with_reservation': (overrides) => overrides.addAll(
              deviceDetailOverrides(
                detail: wifiDetailWithReservation,
                reservations: [testReservation],
              ),
            ),
        'wifi_no_reservation': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: wifiDetailNoReservation),
            ),
        'wired_device': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: wiredDetail),
            ),
        // IPv6 global address — rendered without a scope badge.
        'global_ipv6': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: wifiDetailGlobalIpv6),
            ),
        // IPv6 link-local only — leading icon swapped for a scope badge.
        'link_local_ipv6': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: wifiDetailLinkLocalIpv6),
            ),
        'offline_device': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: offlineDetail),
            ),
        'not_found': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: deviceNotFound),
            ),
        // The firmware's identity (#1693) and the user's name and icon (#1691):
        // maker, model and OS rows from the X_LINKSYS_ leaves, Apple for a
        // randomised MAC, and the tablet icon the user picked over `Phone`.
        'firmware_identity': (overrides) => overrides.addAll(
              deviceDetailOverrides(detail: wifiDetailIdentified),
            ),
      },
      interactions: {
        // A device with nothing set: empty name, Auto selected, Reset off.
        'dialog_edit_identity': Interaction(
          setup: (overrides) => overrides.addAll(
            deviceDetailOverrides(detail: wifiDetailNoReservation),
          ),
          steps: _openEditDialog,
        ),
        // A device the user named and typed: the name prefilled, the user's
        // icon selected, Reset on.
        'dialog_edit_identity_named': Interaction(
          setup: (overrides) => overrides.addAll(
            deviceDetailOverrides(detail: wifiDetailIdentified),
          ),
          steps: _openEditDialog,
        ),
      },
    ),
  );
}
