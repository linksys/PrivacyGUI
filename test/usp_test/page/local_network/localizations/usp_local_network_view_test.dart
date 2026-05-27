import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/local_network/views/usp_local_network_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_local_network.dart';
import '../fixtures/local_network_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'local_network',
      view: () => const UspLocalNetworkView(),
      shell: ShellType.custom,
      height: 1300,
      states: {
        'dhcp_enabled': (overrides) => overrides.addAll(
              localNetworkOverrides(dataState(dhcpEnabledModel)),
            ),
        'dhcp_disabled': (overrides) => overrides.addAll(
              localNetworkOverrides(dataState(dhcpDisabledModel)),
            ),
        'edit_dirty': (overrides) => overrides.addAll(
              localNetworkOverrides(dirtyState()),
            ),
        'validation_error': (overrides) => overrides.addAll(
              localNetworkOverrides(validationErrorAllState()),
            ),
      },
      interactions: {
        'validation_error_tooltip': Interaction(
          setup: (overrides) => overrides.addAll(
            localNetworkOverrides(validationErrorAllState()),
          ),
          steps: (tester) async {
            final errorIcons = find.byIcon(Icons.error_outline);
            for (int i = 0; i < errorIcons.evaluate().length; i++) {
              await tester.tap(errorIcons.at(i));
              await tester.pump();
            }
            await tester.pump(const Duration(milliseconds: 100));
          },
        ),
      },
    ),
  );
}
