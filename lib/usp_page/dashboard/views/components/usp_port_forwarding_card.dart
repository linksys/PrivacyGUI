import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_provider.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/dashboard/views/dialogs/port_forwarding_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspPortForwardingCard extends ConsumerWidget {
  final UspDashboardState state;

  const UspPortForwardingCard({super.key, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = state.portForwarding.items;
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'portForwarding';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Port Forwarding'),
              Row(
                children: [
                  AppText.labelLarge('${rules.length}'),
                  AppGap.sm(),
                  AppIconButton(
                    icon: AppIcon.font(Icons.add, size: 20),
                    onTap: isLoading
                        ? null
                        : () => _showAddPortForwardingDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
          AppGap.xl(),
          if (rules.isEmpty)
            AppText.bodyMedium('No port forwarding rules configured')
          else
            ...rules.map(
                (r) => _buildPortForwardingRow(context, ref, r, isLoading)),
        ],
      ),
    );
  }

  Widget _buildPortForwardingRow(BuildContext context, WidgetRef ref,
      PortForwardingRule rule, bool isLoading) {
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
                          .togglePortForwardingRule(
                              rule.instancePath, value),
                    ),
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodyMedium(
              rule.description.isNotEmpty ? rule.description : 'Unnamed rule',
            ),
          ),
          SizedBox(
            width: 180,
            child: AppText.bodySmall(
              '${rule.externalPort} \u2192 ${rule.internalClient}:${rule.internalPort}',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            width: 50,
            child: AppText.bodySmall(
              rule.protocol,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppIconButton(
            icon: AppIcon.font(Icons.edit, size: 18),
            onTap: isLoading
                ? null
                : () => _showEditPortForwardingDialog(context, ref, rule),
          ),
          AppIconButton(
            icon: AppIcon.font(Icons.delete_outline, size: 18),
            onTap: isLoading
                ? null
                : () => _confirmDeletePortForwarding(context, ref, rule),
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

  Future<void> _showEditPortForwardingDialog(
      BuildContext context, WidgetRef ref, PortForwardingRule rule) async {
    final result = await showDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) => PortForwardingDialog(rule: rule),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'portForwarding',
      mutation: () => ref
          .read(uspDashboardProvider.notifier)
          .updatePortForwardingRule(PortForwardingRuleUpdate(
            instancePath: rule.instancePath,
            enabled: result.enabled,
            externalPort: result.externalPort,
            internalPort: result.internalPort,
            internalClient: result.internalClient,
            protocol: result.protocol,
            description: result.description,
          )),
      successMessage: 'Rule updated',
    );
  }

  Future<void> _confirmDeletePortForwarding(
      BuildContext context, WidgetRef ref, PortForwardingRule rule) async {
    final name =
        rule.description.isNotEmpty ? rule.description : 'this rule';
    final confirmed = await showSimpleAppDialog<bool>(
      context,
      title: 'Delete Rule',
      content: AppText.bodyMedium('Delete $name?'),
      actions: [
        AppButton.text(
          label: 'Cancel',
          onTap: () => context.pop(),
        ),
        AppButton.dangerText(
          label: 'Delete',
          onTap: () => context.pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'portForwarding',
      mutation: () => ref
          .read(uspDashboardProvider.notifier)
          .deletePortForwardingRule(rule.instancePath),
      successMessage: 'Rule deleted',
    );
  }
}
