import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/unified_diagnostics/providers/speed_test_notifier.dart';

import '../../models/diagnostic_result.dart';
import '../../models/diagnostic_state.dart';
import '../../providers/unified_diagnostics_notifier.dart';

class DiagnosticRunningView extends ConsumerWidget {
  final UnifiedDiagnosticsState state;

  const DiagnosticRunningView({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final (flowIcon, flowTitle, _) = _getFlowMeta(state);
    final steps = _getFlowSteps(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(flowIcon, color: colorScheme.primary, size: 24),
            ),
            AppGap.md(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleMedium(flowTitle),
                  AppText.bodySmall(
                    'Diagnosing your network path...',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ],
        ),
        AppGap.xl(),

        // Vertical Stepper - Non-scrollable list as it is already inside a scrollable parent
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final result = state.results.firstWhere(
            (r) => r.step == step,
            orElse: () => DiagnosticStepUIModel(
              step: step,
              severity: DiagnosticSeverity.ok,
              titleKey: '',
              descriptionKey: '',
            ),
          );

          final isCompleted = state.results.any((r) => r.step == step);
          final isCurrent = state.step == step;
          final isWaiting = !isCompleted && !isCurrent;
          final isLast = index == steps.length - 1;

          // Speed test special handling for live progress
          String? progressDetail;
          if (isCurrent && step == DiagnosticStep.runningSpeedTest) {
            final speedState = ref.watch(speedTestProvider).valueOrNull;
            progressDetail = speedState?.progressMessage;
          }

          return _DiagnosticStepNode(
            key: ValueKey(step),
            step: step,
            title: _getStepLabel(step),
            subtitle: isCompleted ? _getStepSummary(result) : progressDetail,
            severity: isCompleted ? result.severity : null,
            isCurrent: isCurrent,
            isWaiting: isWaiting,
            isLast: isLast,
          );
        }),

        AppGap.lg(),
        Center(
          child: AppButton.text(
            label: 'Cancel Diagnostics',
            onTap: () => ref.read(unifiedDiagnosticsProvider.notifier).cancel(),
          ),
        ),
      ],
    );
  }

  List<DiagnosticStep> _getFlowSteps(UnifiedDiagnosticsState state) {
    return switch (state.flow) {
      DiagnosticFlow.internet => [
          DiagnosticStep.checkingWanStatus,
          DiagnosticStep.checkingDhcpPool,
          DiagnosticStep.pingGateway,
          DiagnosticStep.pingDns,
          DiagnosticStep.dnsLookup,
          DiagnosticStep.pingInternet,
          DiagnosticStep.runningSpeedTest,
        ],
      DiagnosticFlow.deviceIssues => [
          DiagnosticStep.checkingConnectedDevices,
        ],
      DiagnosticFlow.wifiCoverage => [
          DiagnosticStep.checkingWifiSignal,
        ],
      DiagnosticFlow.meshBackhaul => [
          DiagnosticStep.checkingMeshBackhaul,
        ],
      DiagnosticFlow.intermittent => [
          DiagnosticStep.pingInternet,
        ],
      // Full diagnostic (no flow selected) — runs all checks.
      null => [
          DiagnosticStep.checkingWanStatus,
          DiagnosticStep.pingGateway,
          DiagnosticStep.pingDns,
          DiagnosticStep.dnsLookup,
          DiagnosticStep.pingInternet,
          DiagnosticStep.runningSpeedTest,
          DiagnosticStep.checkingWifiSignal,
          DiagnosticStep.checkingDhcpPool,
          DiagnosticStep.checkingConnectedDevices,
        ],
    };
  }

  (IconData, String, int) _getFlowMeta(UnifiedDiagnosticsState state) {
    return switch (state.flow) {
      DiagnosticFlow.internet => (Icons.language, 'Internet Diagnostics', 7),
      DiagnosticFlow.deviceIssues => (
          Icons.devices,
          'Device Issues Diagnostics',
          1,
        ),
      DiagnosticFlow.wifiCoverage => (
          Icons.wifi,
          'WiFi Coverage Diagnostics',
          1,
        ),
      DiagnosticFlow.meshBackhaul => (
          Icons.hub,
          'Mesh Backhaul Diagnostics',
          1,
        ),
      DiagnosticFlow.intermittent => (
          Icons.sync_problem,
          'Intermittent Connection Diagnostics',
          1,
        ),
      null => (Icons.network_check, 'Full Diagnostic', 9),
    };
  }

  String _getStepLabel(DiagnosticStep step) {
    return switch (step) {
      DiagnosticStep.checkingWanStatus => 'WAN Status',
      DiagnosticStep.checkingDhcp => 'DHCP Lease',
      DiagnosticStep.checkingDhcpPool => 'DHCP Pool Usage',
      DiagnosticStep.pingGateway => 'Gateway Connection',
      DiagnosticStep.pingDns => 'DNS Connection',
      DiagnosticStep.pingInternet => 'Internet Connectivity',
      DiagnosticStep.dnsLookup => 'DNS Resolution',
      DiagnosticStep.runningSpeedTest => 'Speed Test',
      DiagnosticStep.checkingWifiSignal => 'WiFi Signal Analysis',
      DiagnosticStep.checkingConnectedDevices => 'Connected Devices',
      DiagnosticStep.runningTraceroute => 'Network Path Analysis',
      DiagnosticStep.analyzing => 'Analyzing Results...',
      _ => 'Running...',
    };
  }

  String? _getStepSummary(DiagnosticStepUIModel result) {
    if (result.severity == DiagnosticSeverity.skipped) return 'Skipped';
    if (result.severity == DiagnosticSeverity.error) return 'Issue detected';

    return switch (result) {
      WanStatusCheckUIModel r => r.status,
      PingCheckUIModel r => '${r.avgResponseTime}ms',
      WifiSignalCheckUIModel r => '${r.rssi} dBm',
      DhcpPoolCheckUIModel r => '${r.usedLeases}/${r.capacity} used',
      ConnectedDevicesCheckUIModel r => '${r.totalDevices} devices',
      DnsLookupCheckUIModel r => r.hasResolved ? 'OK' : 'Failed',
      TracerouteCheckUIModel r => '${r.hops.length} hops',
      _ when result.step == DiagnosticStep.runningSpeedTest => result.rawData
              .containsKey('downloadMbps')
          ? '${(result.rawData['downloadMbps'] as double).toStringAsFixed(1)} Mbps'
          : 'Completed',
      _ => 'Completed',
    };
  }
}

class _DiagnosticStepNode extends StatelessWidget {
  final DiagnosticStep step;
  final String title;
  final String? subtitle;
  final DiagnosticSeverity? severity;
  final bool isCurrent;
  final bool isWaiting;
  final bool isLast;

  const _DiagnosticStepNode({
    super.key,
    required this.step,
    required this.title,
    this.subtitle,
    this.severity,
    required this.isCurrent,
    required this.isWaiting,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, color) = _getStatusInfo(colorScheme);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isWaiting
                      ? Colors.transparent
                      : color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWaiting ? colorScheme.outlineVariant : color,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isCurrent
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: AppLoader(strokeWidth: 2),
                        )
                      : Icon(icon,
                          size: 16,
                          color:
                              isWaiting ? colorScheme.outlineVariant : color),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isWaiting ? colorScheme.outlineVariant : color,
                  ),
                ),
            ],
          ),
          AppGap.md(),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(
                  title,
                  color: isWaiting
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: AppText.bodySmall(
                      subtitle!,
                      color: isCurrent
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  const AppGap(AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getStatusInfo(ColorScheme colorScheme) {
    if (isWaiting) return (Icons.circle_outlined, colorScheme.outlineVariant);
    if (isCurrent) return (Icons.circle, colorScheme.primary);

    return switch (severity) {
      DiagnosticSeverity.ok => (Icons.check, colorScheme.primary),
      DiagnosticSeverity.warning => (Icons.warning, colorScheme.tertiary),
      DiagnosticSeverity.error => (Icons.close, colorScheme.error),
      DiagnosticSeverity.skipped => (Icons.block, colorScheme.onSurfaceVariant),
      null => (Icons.circle, colorScheme.primary),
    };
  }
}
