import 'package:privacy_gui/page/unified_diagnostics/views/unified_diagnostics_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_unified_diagnostics.dart';
import '../fixtures/unified_diagnostics_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'unified_diagnostics',
      view: () => const UnifiedDiagnosticsView(),
      shell: ShellType.custom,
      height: 1600,
      states: {
        'idle': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(idleState),
            ),
        'pre_qualifying': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(preQualifyingState),
            ),
        // Flow selection variants
        'select_flow_internet_ok': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(selectFlowInternetOkState),
            ),
        'select_flow_wan_down': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(selectFlowWanDownState),
            ),
        'select_flow_dns_failure': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(selectFlowDnsFailureState),
            ),
        'select_flow_slow': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(selectFlowSlowState),
            ),
        // Running states (representative subset — all render DiagnosticRunningView)
        'running_wan_check': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(runningWanCheckState),
            ),
        'running_speed_test': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(runningSpeedTestState),
            ),
        'running_mesh_backhaul': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(runningMeshBackhaulState),
            ),
        'running_analyzing': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(runningAnalyzingState),
            ),
        // Results variants
        'results_internet': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(internetResultsState),
            ),
        'results_all_ok': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(allOkResultsState),
            ),
        'results_dns_lookup_failure': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(dnsLookupFailureResultsState),
            ),
        'results_traceroute': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(tracerouteResultsState),
            ),
        'results_wifi_coverage': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(wifiCoverageResultsState),
            ),
        'results_mesh_backhaul': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(meshBackhaulResultsState),
            ),
        'results_device_issues': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(deviceIssuesResultsState),
            ),
        'results_multiple_recommendations': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(multipleRecommendationsState),
            ),
        // Manual tools — all tabs and results
        'manual_tools_ping_idle': (overrides) => overrides.addAll(
              manualToolsOverrides(manualToolsPingIdleState),
            ),
        'manual_tools_ping_result': (overrides) => overrides.addAll(
              manualToolsOverrides(manualToolsPingResultState),
            ),
        'manual_tools_ping_running': (overrides) => overrides.addAll(
              manualToolsOverrides(manualToolsPingRunningState),
            ),
        'manual_tools_traceroute_idle': (overrides) => overrides.addAll(
              manualToolsOverrides(manualToolsTracerouteIdleState),
            ),
        'manual_tools_traceroute_result': (overrides) => overrides.addAll(
              manualToolsOverrides(manualToolsTracerouteResultState),
            ),
        'manual_tools_nslookup_idle': (overrides) => overrides.addAll(
              manualToolsOverrides(manualToolsNsLookupIdleState),
            ),
        'manual_tools_nslookup_result': (overrides) => overrides.addAll(
              manualToolsOverrides(manualToolsNsLookupResultState),
            ),
        'manual_tools_error': (overrides) => overrides.addAll(
              manualToolsOverrides(manualToolsErrorState),
            ),
        // Terminal states
        'completed': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(completedState),
            ),
        'error': (overrides) => overrides.addAll(
              unifiedDiagnosticsOverrides(errorState),
            ),
      },
    ),
  );
}
