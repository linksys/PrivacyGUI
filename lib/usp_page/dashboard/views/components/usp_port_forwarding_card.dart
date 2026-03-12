import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/dashboard/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_state.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/dashboard/views/dialogs/port_forwarding_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspPortForwardingCard extends ConsumerWidget {
  final UspDashboardState? state;

  const UspPortForwardingCard({super.key, this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = this.state ??
        ref.watch(uspDashboardProvider).valueOrNull;
    if (state == null) return const SizedBox.shrink();
    final rules = state.portForwardingRuleModels;
    final triggers = state.portTriggeringRuleModels;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'portForwarding';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Port Rules'),
              Row(
                children: [
                  AppText.labelLarge('${rules.length + triggers.length}'),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.add, size: 20),
                    onTap: isLoading
                        ? null
                        : () => _showAddPortForwardingDialog(context, ref),
                  ),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.open_in_new, size: 18),
                    onTap: () =>
                        context.goNamed(RouteNamed.uspPortForwardingDetail),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          // Port Forwarding section
          AppText.labelLarge('Port Forwarding'),
          AppGap.sm(),
          if (rules.isEmpty)
            AppText.bodyMedium('No port forwarding rules configured')
          else
            ...rules.map(
                (r) => _buildPortForwardingRow(context, ref, r, isLoading)),
          AppGap.lg(),
          // Port Triggering section
          AppText.labelLarge('Port Triggering'),
          AppGap.sm(),
          if (triggers.isEmpty)
            AppText.bodyMedium('No port triggering rules configured')
          else
            ...triggers.map(
                (t) => _buildPortTriggeringRow(context, ref, t, isLoading)),
        ],
      ),
    );
  }

  Widget _buildPortForwardingRow(BuildContext context, WidgetRef ref,
      PortForwardingRuleUIModel rule, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          AppSwitch(
            value: rule.enabled,
            scale: 0.8,
            onChanged: isLoading
                ? null
                : (value) => performUspMutation(
                      context,
                      ref,
                      loadingKey: 'portForwarding',
                      mutation: () => ref
                          .read(uspDashboardProvider.notifier)
                          .togglePortForwardingRule(rule.instancePath, value),
                    ),
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodyMedium(rule.displayName),
          ),
          SizedBox(
            width: context.colWidth(2),
            child: AppText.bodySmall(
              rule.portSummary,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: context.colWidth(1),
            child: AppText.bodySmall(
              rule.protocol,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortTriggeringRow(BuildContext context, WidgetRef ref,
      PortTriggeringRuleUIModel trigger, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          AppSwitch(
            value: trigger.enabled,
            scale: 0.8,
            onChanged: isLoading
                ? null
                : (value) => performUspMutation(
                      context,
                      ref,
                      loadingKey: 'portForwarding',
                      mutation: () => ref
                          .read(uspDashboardProvider.notifier)
                          .togglePortTriggerRule(trigger.instancePath, value),
                    ),
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodyMedium(trigger.displayName),
          ),
          SizedBox(
            width: context.colWidth(2),
            child: AppText.bodySmall(
              '${trigger.triggerPortDisplay} \u2192 ${trigger.forwardPortDisplay}',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: context.colWidth(1),
            child: AppText.bodySmall(
              trigger.triggerProtocol,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPortForwardingDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) => const PortForwardingDialog(),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'portForwarding',
      mutation: () =>
          ref.read(uspDashboardProvider.notifier).addPortForwardingRule(
                externalPort: result.externalPort,
                internalPort: result.internalPort,
                internalClient: result.internalClient,
                protocol: result.protocol,
                description: result.description,
                enabled: result.enabled,
              ),
      successMessage: 'Rule added',
    );
  }
}
