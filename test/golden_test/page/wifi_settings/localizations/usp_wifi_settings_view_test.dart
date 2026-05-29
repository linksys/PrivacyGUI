import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/views/usp_wifi_settings_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_wifi_settings.dart';
import '../fixtures/wifi_settings_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'wifi_settings',
      view: () => const UspWifiSettingsView(),
      shell: ShellType.custom,
      height: 1600,
      states: {
        'quick_setup_off': (overrides) => overrides.addAll(
              wifiSettingsOverrides(
                wifiState: quickSetupOffState,
                advancedState: defaultAdvancedState,
              ),
            ),
        'quick_setup_on': (overrides) => overrides.addAll(
              wifiSettingsOverrides(
                wifiState: quickSetupOnState,
                advancedState: defaultAdvancedState,
              ),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              wifiSettingsOverrides(
                wifiState: editDirtyState,
                advancedState: defaultAdvancedState,
              ),
            ),
      },
      interactions: {
        'tab_advanced_dfs_on': Interaction(
          setup: (overrides) => overrides.addAll(
            wifiSettingsOverrides(
              wifiState: quickSetupOffState,
              advancedState: advancedDfsOnState,
            ),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(1));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'tab_advanced_dfs_off': Interaction(
          setup: (overrides) => overrides.addAll(
            wifiSettingsOverrides(
              wifiState: quickSetupOffState,
              advancedState: advancedDfsOffState,
            ),
          ),
          steps: (tester) async {
            await tester.tap(find.byType(Tab).at(1));
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'dialog_edit_name': Interaction(
          setup: (overrides) => overrides.addAll(
            wifiSettingsOverrides(
              wifiState: quickSetupOffState,
              advancedState: defaultAdvancedState,
            ),
          ),
          steps: (tester) async {
            final nameTile = find.text('HomeNetwork').first;
            await tester.tap(nameTile);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'dialog_edit_password': Interaction(
          setup: (overrides) => overrides.addAll(
            wifiSettingsOverrides(
              wifiState: quickSetupOffState,
              advancedState: defaultAdvancedState,
            ),
          ),
          steps: (tester) async {
            final passwordTile = find.text('•' * 12).first;
            await tester.tap(passwordTile);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'dialog_edit_security_mode': Interaction(
          setup: (overrides) => overrides.addAll(
            wifiSettingsOverrides(
              wifiState: quickSetupOffState,
              advancedState: defaultAdvancedState,
            ),
          ),
          steps: (tester) async {
            final securityTile = find.text('WPA2-Personal').first;
            await tester.tap(securityTile);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'dialog_edit_wifi_mode': Interaction(
          setup: (overrides) => overrides.addAll(
            wifiSettingsOverrides(
              wifiState: quickSetupOffState,
              advancedState: defaultAdvancedState,
            ),
          ),
          steps: (tester) async {
            final wifiModeTile = find.text('802.11b/g/n/ax Only').first;
            await tester.tap(wifiModeTile);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'dialog_edit_channel_width': Interaction(
          setup: (overrides) => overrides.addAll(
            wifiSettingsOverrides(
              wifiState: quickSetupOffState,
              advancedState: defaultAdvancedState,
            ),
          ),
          steps: (tester) async {
            final channelWidthTile = find.text('20MHz').first;
            await tester.tap(channelWidthTile);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
        'dialog_edit_channel': Interaction(
          setup: (overrides) => overrides.addAll(
            wifiSettingsOverrides(
              wifiState: quickSetupOffState,
              advancedState: defaultAdvancedState,
            ),
          ),
          steps: (tester) async {
            final channelDesc = find.text('6');
            await tester.tap(channelDesc.first);
            await tester.pump();
            for (int i = 0; i < 10; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
          },
        ),
      },
    ),
  );
}
