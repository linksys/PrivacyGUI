import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_networks_card.dart';
import 'package:privacy_gui/page/wifi_settings/cards/usp_wifi_status_card.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../golden_framework/golden_runner.dart';
import '../../../../golden_framework/golden_test_config.dart';
import '../../../../../mocks/provider_overrides/mock_dashboard_cards.dart';
import '../../../../../mocks/test_data/scenes/cards_scene_data.dart';

/// Opens the channel dialog of the card's radio at [index] (0 = 2.4 GHz,
/// 1 = 5 GHz) through its edit button, as the user does.
Future<void> _openChannelDialog(WidgetTester tester, int index) async {
  await tester.tap(find
      .ancestor(
          of: find.byIcon(Icons.edit), matching: find.byType(AppIconButton))
      .at(index));
  await pumpOverlayIn(tester);
}

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
        // #1782: no channel in use read, so "--" and "-- (Auto)", never the
        // configured channel.
        'channel_in_use_unknown': (overrides) => overrides.addAll(
              cardOverrides(wifiData: testWifiChannelInUseUnknownData),
            ),
      },
      interactions: {
        // A fixed channel the radio is not on: 40 selected, "Currently
        // using: 36" (#1782).
        'dialog_channel_fixed': Interaction(
          setup: (overrides) => overrides.addAll(
            cardOverrides(wifiData: testWifiWithChannelChoicesData),
          ),
          steps: (tester) => _openChannelDialog(tester, 1),
        ),
        // Auto on: the dropdown is locked to Auto.
        'dialog_channel_auto': Interaction(
          setup: (overrides) => overrides.addAll(
            cardOverrides(wifiData: testWifiWithChannelChoicesData),
          ),
          steps: (tester) => _openChannelDialog(tester, 0),
        ),
        // No PossibleChannels: Auto only, and the line that says so.
        'dialog_channel_no_manual_options': Interaction(
          setup: (overrides) => overrides.addAll(
            cardOverrides(wifiData: testWifiData),
          ),
          steps: (tester) => _openChannelDialog(tester, 0),
        ),
        // No channel in use read: the "Currently using" line is left out
        // (#1782).
        'dialog_channel_in_use_unknown': Interaction(
          setup: (overrides) => overrides.addAll(
            cardOverrides(wifiData: testWifiChannelInUseUnknownData),
          ),
          steps: (tester) => _openChannelDialog(tester, 1),
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
