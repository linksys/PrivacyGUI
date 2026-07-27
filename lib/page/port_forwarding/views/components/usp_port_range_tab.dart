import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/port_forwarding/providers/usp_port_forwarding_page_notifier.dart';
import 'package:privacy_gui/page/port_forwarding/views/dialogs/port_range_forwarding_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 2: Port Range Forwarding — shows rules where isPortRange == true.
class UspPortRangeTab extends ConsumerWidget {
  final List<PortForwardingRuleUIModel> rules;
  final bool isSaving;

  const UspPortRangeTab({
    super.key,
    required this.rules,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleMedium(
                '${loc(context).portRangeForwarding} (${rules.length})'),
            AppIconButton(
              icon: AppIcon.font(Icons.add, size: 20),
              identifier: 'pf-add-port-range',
              onTap: isSaving ? null : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        AppGap.lg(),
        if (rules.isEmpty)
          DetailEmptyBlock(
            icon: Icons.open_in_browser,
            message: loc(context).noPortRangeRules,
          )
        else
          ...rules.map((r) => _buildRuleRow(context, ref, r)),
      ],
    );
  }

  Widget _buildRuleRow(
      BuildContext context, WidgetRef ref, PortForwardingRuleUIModel rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            AppSwitch(
              identifier: 'pf-rule-enable-${rule.identifierKey}',
              value: rule.enabled,
              scale: 0.8,
              onChanged: isSaving
                  ? null
                  : (value) => ref
                      .read(uspPortForwardingPageProvider.notifier)
                      .toggleForwardingRule(rule, value),
            ),
            AppGap.md(),
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
              identifier: 'pf-edit-${rule.identifierKey}',
              onTap:
                  isSaving ? null : () => _showEditDialog(context, ref, rule),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.delete_outline, size: 18),
              identifier: 'pf-delete-${rule.identifierKey}',
              onTap: isSaving ? null : () => _confirmDelete(context, ref, rule),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showAppDialog<PortRangeForwardingDialogResult>(
      context: context,
      builder: (_) => const PortRangeForwardingDialog(),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspPortForwardingPageProvider.notifier).addForwardingRule(
          PortForwardingRuleUIModel(
            description: result.description,
            externalPort: result.externalPortStart,
            externalPortEndRange: result.externalPortEnd,
            internalPort: result.internalPort,
            internalClient: result.internalClient,
            protocol: result.protocol,
            enabled: result.enabled,
          ),
        );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref,
      PortForwardingRuleUIModel rule) async {
    final result = await showAppDialog<PortRangeForwardingDialogResult>(
      context: context,
      builder: (_) => PortRangeForwardingDialog(rule: rule),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspPortForwardingPageProvider.notifier).editForwardingRule(
          rule,
          rule.copyWith(
            enabled: result.enabled,
            description: result.description,
            externalPort: result.externalPortStart,
            externalPortEndRange: result.externalPortEnd,
            internalPort: result.internalPort,
            internalClient: result.internalClient,
            protocol: result.protocol,
          ),
        );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      PortForwardingRuleUIModel rule) async {
    final confirmed = await showSimpleAppDialog<bool>(
      context,
      title: loc(context).deleteRule,
      content: AppText.bodyMedium(loc(context).deleteConfirm(rule.displayName)),
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () => context.pop(),
        ),
        AppButton.dangerText(
          label: loc(context).delete,
          onTap: () => context.pop(true),
        ),
      ],
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(uspPortForwardingPageProvider.notifier).deleteForwardingRule(rule);
  }
}
