import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_mutation_helper.dart';
import 'package:privacy_gui/usp_page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/usp_page/port_forwarding/views/dialogs/port_triggering_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 3: Port Triggering — independent data source from PortTriggering.
class UspPortTriggeringTab extends ConsumerWidget {
  final List<PortTriggeringRuleUIModel> rules;

  const UspPortTriggeringTab({super.key, required this.rules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'portTriggering';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleMedium('Port Triggering'),
            AppIconButton(
              icon: AppIcon.font(Icons.add, size: 20),
              onTap: isLoading ? null : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        AppGap.lg(),
        if (rules.isEmpty)
          AppText.bodyMedium('No port triggering rules configured')
        else
          ...rules.map((r) => _buildRuleRow(context, ref, r, isLoading)),
      ],
    );
  }

  Widget _buildRuleRow(BuildContext context, WidgetRef ref,
      PortTriggeringRuleUIModel rule, bool isLoading) {
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
                        loadingKey: 'portTriggering',
                        mutation: () => ref
                            .read(portTriggeringDataProvider.notifier)
                            .toggleRule(rule.instancePath, value),
                      ),
            ),
            AppGap.sm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(rule.displayName),
                  AppText.bodySmall(
                    rule.summary,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
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

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<PortTriggeringDialogResult>(
      context: context,
      builder: (_) => const PortTriggeringDialog(),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'portTriggering',
      mutation: () =>
          ref.read(portTriggeringDataProvider.notifier).addRule(
                triggerPort: result.triggerPort,
                triggerPortEndRange: result.triggerPortEndRange,
                triggerProtocol: result.triggerProtocol,
                description: result.description,
                enabled: result.enabled,
                forwardPort: result.forwardPort,
                forwardPortEndRange: result.forwardPortEndRange,
                forwardProtocol: result.forwardProtocol,
              ),
      successMessage: 'Rule added',
    );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref,
      PortTriggeringRuleUIModel rule) async {
    final result = await showDialog<PortTriggeringDialogResult>(
      context: context,
      builder: (_) => PortTriggeringDialog(rule: rule),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'portTriggering',
      mutation: () =>
          ref.read(portTriggeringDataProvider.notifier).updateRule(
                instancePath: rule.instancePath,
                enabled: result.enabled,
                triggerPort: result.triggerPort,
                triggerPortEndRange: result.triggerPortEndRange,
                triggerProtocol: result.triggerProtocol,
                description: result.description,
              ),
      successMessage: 'Rule updated',
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      PortTriggeringRuleUIModel rule) async {
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
      loadingKey: 'portTriggering',
      mutation: () => ref
          .read(portTriggeringDataProvider.notifier)
          .deleteRule(rule.instancePath),
      successMessage: 'Rule deleted',
    );
  }
}
