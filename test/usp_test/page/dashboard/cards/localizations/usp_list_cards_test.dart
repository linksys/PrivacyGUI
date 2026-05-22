import 'package:flutter/material.dart';
import 'package:privacy_gui/page/devices/cards/usp_connected_devices_card.dart';
import 'package:privacy_gui/page/local_network/cards/usp_dhcp_reservations_card.dart';
import 'package:privacy_gui/page/port_forwarding/cards/usp_port_forwarding_card.dart';

import '../../../../golden_framework/golden_runner.dart';
import '../../../../golden_framework/golden_test_config.dart';
import '../../../../golden_framework/mocks/mock_dashboard_cards.dart';
import '../fixtures/cards_test_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // UspConnectedDevicesCard — with devices
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_connected_devices',
      view: () => const UspConnectedDevicesCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('400x400', Size(400, 400))],
      states: {
        'with_devices': (overrides) => overrides.addAll(
              cardOverrides(devicesData: testDevicesData),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(devicesData: testDevicesEmptyData),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspDhcpReservationsCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_dhcp_reservations',
      view: () => const UspDhcpReservationsCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x500', Size(500, 500))],
      states: {
        'with_data': (overrides) => overrides.addAll(
              cardOverrides(dhcpData: testDhcpData),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(dhcpData: testDhcpEmptyData),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspPortForwardingCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_port_forwarding',
      view: () => const UspPortForwardingCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x500', Size(500, 500))],
      states: {
        'with_rules': (overrides) => overrides.addAll(
              cardOverrides(
                portForwardingData: testPortForwardingData,
                portTriggeringData: testPortTriggeringData,
              ),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(
                portForwardingData: testPortForwardingEmptyData,
                portTriggeringData: testPortTriggeringEmptyData,
              ),
            ),
      },
    ),
  );
}
