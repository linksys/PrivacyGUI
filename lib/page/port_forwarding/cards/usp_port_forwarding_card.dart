import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/components/usp_mutation_helper.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/port_forwarding_dialog.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/usp_port_forwarding_page_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspPortForwardingCard extends ConsumerWidget {
  const UspPortForwardingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pfData = ref.watch(portForwardingDataProvider).valueOrNull;
    final ptData = ref.watch(portTriggeringDataProvider).valueOrNull;
    if (pfData == null && ptData == null) {
      return const CardSkeleton.list(rows: 3);
    }
    final rules = pfData?.ruleModels ?? [];
    final triggers = ptData?.ruleModels ?? [];
    final isLoading = ref.watch(uspMutationLoadingProvider) == 'portForwarding';

    return DashboardCardTemplate.multiSection(
      title: loc(context).portRules,
      trailing: AppIconButton(
        icon: AppIcon.font(Icons.add, size: 20),
        onTap:
            isLoading ? null : () => _showAddPortForwardingDialog(context, ref),
      ),
      detailRoute: RouteNamed.uspPortForwardingDetail,
      itemCount: rules.length + triggers.length,
      detailLabel: loc(context).viewAll,
      sections: [
        CardSection(
          title: loc(context).portForwarding,
          titleBadge: AppText.labelMedium('${rules.length}'),
          isEmpty: rules.isEmpty,
          emptyMessage: loc(context).noPortForwardingRulesConfigured,
          content: Column(
            children: [
              for (var i = 0; i < rules.length; i++) ...[
                _buildPortForwardingRow(context, ref, rules[i], isLoading),
                if (i < rules.length - 1) AppGap.sm(),
              ],
            ],
          ),
        ),
        CardSection(
          title: loc(context).portTriggering,
          titleBadge: AppText.labelMedium('${triggers.length}'),
          isEmpty: triggers.isEmpty,
          emptyMessage: loc(context).noPortTriggeringRules,
          content: Column(
            children: [
              for (var i = 0; i < triggers.length; i++) ...[
                _buildPortTriggeringRow(context, ref, triggers[i], isLoading),
                if (i < triggers.length - 1) AppGap.sm(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortForwardingRow(BuildContext context, WidgetRef ref,
      PortForwardingRuleUIModel rule, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBlock(
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
                          .read(uspPortForwardingPageProvider.notifier)
                          .immediateToggleForwarding(rule.instancePath!, value),
                    ),
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodyMedium(rule.displayName),
          ),
          AppText.bodySmall(
            rule.portSummary,
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.md(),
          _ProtocolBadge(protocol: rule.protocol),
        ],
      ),
    );
  }

  Widget _buildPortTriggeringRow(BuildContext context, WidgetRef ref,
      PortTriggeringRuleUIModel trigger, bool isLoading) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBlock(
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
                          .read(uspPortForwardingPageProvider.notifier)
                          .immediateToggleTriggering(
                              trigger.instancePath!, value),
                    ),
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodyMedium(trigger.displayName),
          ),
          AppText.bodySmall(
            '${trigger.triggerPortDisplay} → ${trigger.forwardPortDisplay}',
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.md(),
          _ProtocolBadge(protocol: trigger.triggerProtocol),
        ],
      ),
    );
  }

  Future<void> _showAddPortForwardingDialog(
      BuildContext context, WidgetRef ref) async {
    final result = await showAppDialog<PortForwardingDialogResult>(
      context: context,
      builder: (_) => const PortForwardingDialog(),
    );
    if (result == null || !context.mounted) return;
    await performUspMutation(
      context,
      ref,
      loadingKey: 'portForwarding',
      mutation: () => ref
          .read(uspPortForwardingPageProvider.notifier)
          .immediateAddForwarding(
            externalPort: result.externalPort,
            internalPort: result.internalPort,
            internalClient: result.internalClient,
            protocol: result.protocol,
            description: result.description,
            enabled: result.enabled,
          ),
      successMessage: loc(context).ruleAdded,
    );
  }
}

class _ProtocolBadge extends StatelessWidget {
  final String protocol;
  const _ProtocolBadge({required this.protocol});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: AppText.labelSmall(
        protocol,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
