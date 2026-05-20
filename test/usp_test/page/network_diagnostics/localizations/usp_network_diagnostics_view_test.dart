import 'package:privacy_gui/page/network_diagnostics/views/usp_network_diagnostics_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_network_diagnostics.dart';
import '../fixtures/network_diagnostics_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'network_diagnostics',
      view: () => const UspNetworkDiagnosticsView(),
      shell: ShellType.custom,
      states: {
        'idle': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(idleState),
            ),
        'running': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(runningPingState),
            ),
        'ping_result': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(pingCompletedState),
            ),
        'traceroute_result': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(tracerouteCompletedState),
            ),
        'diagnostic_error': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(diagnosticErrorState),
            ),
      },
    ),
  );
}
