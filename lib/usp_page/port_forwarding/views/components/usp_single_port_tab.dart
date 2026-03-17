import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/usp_page/dashboard/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/dashboard/views/dialogs/port_forwarding_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 1: Single Port Forwarding — shows rules where isSinglePort == true.
class UspSinglePortTab extends ConsumerWidget {
  final List<PortForwardingRuleUIModel> rules;

  const UspSinglePortTab({super.key, required this.rules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'portForwarding';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleMedium('Single Port Forwarding'),
            AppIconButton(
              icon: AppIcon.font(Icons.add, size: 20),
              onTap: isLoading ? null : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        AppGap.lg(),
        if (rules.isEmpty)
          AppText.bodyMedium('No single port forwarding rules configured')
        else
          ...rules.map((r) => _buildRuleRow(context, ref, r, isLoading)),
      ],
    );
  }

  Widget _buildRuleRow(BuildContext context, WidgetRef ref,
      PortForwardingRuleUIModel rule, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(rule.displayName),
                  AppText.bodySmall(
                    rule.portSummary,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            AppText.bodySmall(
              rule.protocol,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            AppGap.sm(),
            AppIconButton(
              icon: AppIcon.font(Icons.edit, size: 18),
              onTap:
                  isLoading ? null : () => _showEditDialog(context, ref, rule),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.delete_outline, size: 18),
              onTap:
                  isLoading ? null : () => _confirmDelete(context, ref, rule),
            ),
          ],
        ),
      ),
    );
  }

  List<AppAutoCompleteOption> _buildIpv4DeviceOptions(WidgetRef ref) {
    final devices =
        ref.read(uspDashboardProvider).valueOrNull?.deviceModels ?? [];
    return devices
        .where((d) => d.ip.isNotEmpty)
        .map((d) => AppAutoCompleteOption(
              label: d.displayName,
              value: d.ip,
              subtitle: d.mac,
              isActive: d.isActive,
            ))
        .toList();
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final deviceOptions = _buildIpv4DeviceOptions(ref);
    final result = await showDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) => PortForwardingDialog(deviceOptions: deviceOptions),
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

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref,
      PortForwardingRuleUIModel rule) async {
    final deviceOptions = _buildIpv4DeviceOptions(ref);
    final result = await showDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) =>
          PortForwardingDialog(rule: rule, deviceOptions: deviceOptions),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'portForwarding',
      mutation: () =>
          ref.read(uspDashboardProvider.notifier).updatePortForwardingRule(
                instancePath: rule.instancePath,
                enabled: result.enabled,
                externalPort: result.externalPort,
                internalPort: result.internalPort,
                internalClient: result.internalClient,
                protocol: result.protocol,
                description: result.description,
              ),
      successMessage: 'Rule updated',
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      PortForwardingRuleUIModel rule) async {
    final confirmed = await showSimpleAppDialog<bool>(
      context,
      title: 'Delete Rule',
      content: AppText.bodyMedium('Delete "${rule.displayName}"?'),
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
