import 'package:flutter/material.dart';
import 'package:privacy_gui/page/admin/cards/usp_device_info_card.dart';
import 'package:privacy_gui/page/admin/cards/usp_time_settings_card.dart';
import 'package:privacy_gui/page/internet_settings/cards/usp_network_status_card.dart';
import 'package:privacy_gui/page/local_network/cards/usp_lan_info_card.dart';
import 'package:privacy_gui/page/local_network/cards/usp_ethernet_ports_card.dart';

import '../../../../golden_framework/golden_runner.dart';
import '../../../../golden_framework/golden_test_config.dart';
import '../../../../golden_framework/mocks/mock_dashboard_cards.dart';
import '../fixtures/cards_test_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // UspDeviceInfoCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_device_info',
      view: () => const UspDeviceInfoCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('400x400', Size(400, 400))],
      states: {
        'data': (overrides) => overrides.addAll(
              cardOverrides(systemInfoData: testSystemInfoData),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspTimeSettingsCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_time_settings',
      view: () => const UspTimeSettingsCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('400x200', Size(400, 200))],
      states: {
        'synchronized': (overrides) => overrides.addAll(
              cardOverrides(timeData: testTimeData),
            ),
        'unsynchronized': (overrides) => overrides.addAll(
              cardOverrides(timeData: testTimeUnsyncData),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspNetworkStatusCard — WAN online (DHCP)
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_network_status',
      view: () => const UspNetworkStatusCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('400x380', Size(400, 380))],
      states: {
        'online_dhcp': (overrides) => overrides.addAll(
              cardOverrides(wanData: testWanOnlineData),
            ),
        'offline': (overrides) => overrides.addAll(
              cardOverrides(wanData: testWanOfflineData),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspLanInfoCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_lan_info',
      view: () => const UspLanInfoCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('400x320', Size(400, 320))],
      states: {
        'dhcp_enabled': (overrides) => overrides.addAll(
              cardOverrides(lanData: testLanData),
            ),
        'dhcp_disabled': (overrides) => overrides.addAll(
              cardOverrides(lanData: testLanDisabledData),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspEthernetPortsCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_ethernet_ports',
      view: () => const UspEthernetPortsCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('600x200', Size(600, 200))],
      states: {
        'mixed_ports': (overrides) => overrides.addAll(
              cardOverrides(ethernetData: testEthernetData),
            ),
      },
    ),
  );
}
