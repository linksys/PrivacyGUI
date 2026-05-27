import 'package:flutter/material.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_networks_card.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_status_card.dart';

import '../../../../golden_framework/golden_runner.dart';
import '../../../../golden_framework/golden_test_config.dart';
import '../../../../golden_framework/mocks/mock_dashboard_cards.dart';
import '../fixtures/cards_test_data.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // UspWifiStatusCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_wifi_status',
      view: () => const UspWifiStatusCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('500x900', Size(500, 900))],
      states: {
        'two_radios_enabled': (overrides) => overrides.addAll(
              cardOverrides(wifiData: testWifiData),
            ),
        'one_radio_disabled': (overrides) => overrides.addAll(
              cardOverrides(wifiData: testWifiOneDisabledData),
            ),
      },
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UspWifiNetworksCard
  // ─────────────────────────────────────────────────────────────────────────
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'card_wifi_networks',
      view: () => const UspWifiNetworksCard(),
      shell: ShellType.scaffold,
      devices: [GoldenDevice('400x350', Size(400, 350))],
      states: {
        'with_networks': (overrides) => overrides.addAll(
              cardOverrides(wifiData: testWifiData),
            ),
        'empty': (overrides) => overrides.addAll(
              cardOverrides(wifiData: testWifiEmptyData),
            ),
      },
    ),
  );
}
