import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/usp_port_forwarding_page_notifier.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/port_forwarding_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Tab 1: Single Port Forwarding — shows rules where isSinglePort == true.
class UspSinglePortTab extends ConsumerWidget {
  final List<PortForwardingRuleUIModel> rules;
  final bool isSaving;

  const UspSinglePortTab({
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
                '${loc(context).singlePortForwarding} (${rules.length})'),
            AppIconButton(
              icon: AppIcon.font(Icons.add, size: 20),
              identifier: 'pf-add-single-port',
              onTap: isSaving ? null : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        AppGap.lg(),
        if (rules.isEmpty)
          DetailEmptyBlock(
            icon: Icons.open_in_browser,
            message: loc(context).noSinglePortRules,
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

  List<AppAutoCompleteOption> _buildIpv4DeviceOptions(WidgetRef ref) {
    final devices =
        ref.read(devicesDataProvider).valueOrNull?.clientDevices ?? [];
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
    final result = await showAppDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) => PortForwardingDialog(deviceOptions: deviceOptions),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspPortForwardingPageProvider.notifier).addForwardingRule(
          PortForwardingRuleUIModel(
            description: result.description,
            externalPort: result.externalPort,
            internalPort: result.internalPort,
            internalClient: result.internalClient,
            protocol: result.protocol,
            enabled: result.enabled,
          ),
        );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref,
      PortForwardingRuleUIModel rule) async {
    final deviceOptions = _buildIpv4DeviceOptions(ref);
    final result = await showAppDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) =>
          PortForwardingDialog(rule: rule, deviceOptions: deviceOptions),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspPortForwardingPageProvider.notifier).editForwardingRule(
          rule,
          rule.copyWith(
            enabled: result.enabled,
            description: result.description,
            externalPort: result.externalPort,
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
