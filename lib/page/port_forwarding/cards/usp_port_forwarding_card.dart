import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
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
      title: 'Port Rules',
      trailing: AppIconButton(
        icon: AppIcon.font(Icons.add, size: 20),
        onTap:
            isLoading ? null : () => _showAddPortForwardingDialog(context, ref),
      ),
      detailRoute: RouteNamed.uspPortForwardingDetail,
      itemCount: rules.length + triggers.length,
      detailLabel: 'View all',
      sections: [
        CardSection(
          title: 'Port Forwarding',
          titleBadge: AppText.labelMedium('${rules.length}'),
          isEmpty: rules.isEmpty,
          emptyMessage: 'No port forwarding rules configured',
          content: Column(
            children: rules
                .map((r) => _buildPortForwardingRow(context, ref, r, isLoading))
                .toList(),
          ),
        ),
        CardSection(
          title: 'Port Triggering',
          titleBadge: AppText.labelMedium('${triggers.length}'),
          isEmpty: triggers.isEmpty,
          emptyMessage: 'No port triggering rules configured',
          content: Column(
            children: triggers
                .map((t) => _buildPortTriggeringRow(context, ref, t, isLoading))
                .toList(),
          ),
        ),
      ],
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
                          .read(uspPortForwardingPageProvider.notifier)
                          .immediateToggleForwarding(rule.instancePath!, value),
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
                          .read(uspPortForwardingPageProvider.notifier)
                          .immediateToggleTriggering(
                              trigger.instancePath!, value),
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
      successMessage: 'Rule added',
    );
  }
}
