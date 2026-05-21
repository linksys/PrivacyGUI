import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_state.dart';
import '../../providers/unified_diagnostics_notifier.dart';
import 'flow_card.dart';

class DiagnosticFlowMenu extends ConsumerWidget {
  final UnifiedDiagnosticsState state;

  const DiagnosticFlowMenu({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final preQualifier = state.preQualifierResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.headlineSmall('What issue are you experiencing?'),
        AppGap.md(),

        // Show pre-qualifier hint if relevant
        if (preQualifier == PreQualifierResult.wanDownNoIp ||
            preQualifier == PreQualifierResult.dnsFailure) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: colorScheme.onErrorContainer),
                AppGap.md(),
                Expanded(
                  child: AppText.bodySmall(
                    preQualifier == PreQualifierResult.wanDownNoIp
                        ? 'Network issue detected: WAN connection down'
                        : 'Network issue detected: DNS not responding',
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          AppGap.lg(),
        ] else if (preQualifier == PreQualifierResult.internetSlow) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.speed, color: colorScheme.onTertiaryContainer),
                AppGap.md(),
                Expanded(
                  child: AppText.bodySmall(
                    'High latency detected during connection check',
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          AppGap.lg(),
        ],

        // Flow 1: Internet (combined connectivity + speed)
        FlowCard(
          icon: Icons.language,
          title: 'Internet',
          description: 'Check connectivity and speed',
          color: colorScheme.primary,
          recommended: preQualifier == PreQualifierResult.wanDownNoIp ||
              preQualifier == PreQualifierResult.dnsFailure ||
              preQualifier == PreQualifierResult.internetSlow,
          onTap: () => notifier.selectFlow(DiagnosticFlow.internet),
        ),
        AppGap.md(),

        // Flow 2: WiFi Coverage
        FlowCard(
          icon: Icons.wifi,
          title: 'WiFi Coverage',
          description: 'Weak signal in certain areas',
          color: colorScheme.tertiary,
          onTap: () => notifier.selectFlow(DiagnosticFlow.wifiCoverage),
        ),
        AppGap.md(),

        // Flow 3: Mesh / Backhaul
        FlowCard(
          icon: Icons.hub,
          title: 'Mesh / Backhaul',
          description: 'Check node-to-node link quality',
          color: colorScheme.primary,
          onTap: () => notifier.selectFlow(DiagnosticFlow.meshBackhaul),
        ),
        AppGap.md(),

        // Flow 4: Device Issues
        FlowCard(
          icon: Icons.devices,
          title: 'Device Issues',
          description: 'Specific device has connection problems',
          color: colorScheme.secondary,
          onTap: () => notifier.selectFlow(DiagnosticFlow.deviceIssues),
        ),
        AppGap.md(),

        // Flow 5: Intermittent
        FlowCard(
          icon: Icons.sync_problem,
          title: 'Intermittent Connection',
          description: 'Connection drops on and off',
          color: colorScheme.outline,
          onTap: () => notifier.selectFlow(DiagnosticFlow.intermittent),
        ),
        AppGap.xxxl(),

        Center(
          child: AppButton.text(
            label: 'Cancel',
            onTap: () => notifier.cancel(),
          ),
        ),
      ],
    );
  }
}
