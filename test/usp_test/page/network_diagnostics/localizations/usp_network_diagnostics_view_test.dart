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
        'data': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(idleState),
            ),
        'data_running': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(runningPingState),
            ),
        'data_ping_result': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(pingCompletedState),
            ),
        'data_traceroute_result': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(tracerouteCompletedState),
            ),
        'data_diagnostic_error': (overrides) => overrides.addAll(
              networkDiagnosticsOverrides(diagnosticErrorState),
            ),
      },
    ),
  );
}
