import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/port_forwarding/providers/usp_port_forwarding_page_notifier.dart';
import 'package:privacy_gui/page/port_forwarding/views/dialogs/port_triggering_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 3: Port Triggering.
class UspPortTriggeringTab extends ConsumerWidget {
  final List<PortTriggeringRuleUIModel> rules;
  final bool isSaving;

  const UspPortTriggeringTab({
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
            AppText.titleMedium(loc(context).portTriggering),
            AppIconButton(
              icon: AppIcon.font(Icons.add, size: 20),
              onTap: isSaving ? null : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        AppGap.lg(),
        if (rules.isEmpty)
          DetailEmptyBlock(
            icon: Icons.swap_horiz,
            message: loc(context).noPortTriggeringRules,
          )
        else
          ...rules.map((r) => _buildRuleRow(context, ref, r)),
      ],
    );
  }

  Widget _buildRuleRow(
      BuildContext context, WidgetRef ref, PortTriggeringRuleUIModel rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            AppSwitch(
              value: rule.enabled,
              scale: 0.8,
              onChanged: isSaving
                  ? null
                  : (value) => ref
                      .read(uspPortForwardingPageProvider.notifier)
                      .toggleTriggeringRule(rule, value),
            ),
            AppGap.md(),
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
                  isSaving ? null : () => _showEditDialog(context, ref, rule),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.delete_outline, size: 18),
              onTap: isSaving ? null : () => _confirmDelete(context, ref, rule),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showAppDialog<PortTriggeringDialogResult>(
      context: context,
      builder: (_) => const PortTriggeringDialog(),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspPortForwardingPageProvider.notifier).addTriggeringRule(
          PortTriggeringRuleUIModel(
            enabled: result.enabled,
            description: result.description,
            triggerPort: result.triggerPort,
            triggerPortEndRange: result.triggerPortEndRange,
            triggerProtocol: result.triggerProtocol,
            forwardRules: [
              PortTriggerForwardRuleUIModel(
                forwardPort: result.forwardPort,
                forwardPortEndRange: result.forwardPortEndRange,
                forwardProtocol: result.forwardProtocol,
              ),
            ],
          ),
        );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref,
      PortTriggeringRuleUIModel rule) async {
    final result = await showAppDialog<PortTriggeringDialogResult>(
      context: context,
      builder: (_) => PortTriggeringDialog(rule: rule),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspPortForwardingPageProvider.notifier).editTriggeringRule(
          rule,
          rule.copyWith(
            enabled: result.enabled,
            description: result.description,
            triggerPort: result.triggerPort,
            triggerPortEndRange: result.triggerPortEndRange,
            triggerProtocol: result.triggerProtocol,
          ),
        );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      PortTriggeringRuleUIModel rule) async {
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
    ref.read(uspPortForwardingPageProvider.notifier).deleteTriggeringRule(rule);
  }
}
