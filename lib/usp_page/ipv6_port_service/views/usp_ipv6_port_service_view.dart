import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/usp_page/components/select_auto_complete.dart';
import 'package:privacy_gui/usp_page/ipv6_port_service/providers/usp_ipv6_port_service_notifier.dart';
import 'package:privacy_gui/usp_page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/usp_dashboard_notifier.dart';
import 'package:privacy_gui/usp_page/ipv6_port_service/views/dialogs/ipv6_port_service_rule_dialog.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspIpv6PortServiceView extends ConsumerWidget {
  const UspIpv6PortServiceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspIpv6PortServiceProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'IPv6 Port Service',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      onBackTap: () => context.canPop()
          ? context.pop()
          : context.goNamed(RouteNamed.uspMenu),
      onRefresh: () => ref.refresh(uspIpv6PortServiceProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => _buildError(context, ref),
          data: (state) => _buildContent(context, ref, state),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.font(Icons.error_outline,
              size: 48, color: Theme.of(context).colorScheme.error),
          AppGap.xl(),
          AppText.titleMedium('Unable to load IPv6 port service'),
          AppGap.md(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspIpv6PortServiceProvider),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UspIpv6PortServiceState state,
  ) {
    final isMutating = state.isMutating;
    final rules = state.rules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          'Manage IPv6 inbound port access rules',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.titleMedium('Rules'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isMutating)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  AppIconButton(
                    icon: AppIcon.font(Icons.refresh, size: 20),
                    onTap: () => ref.invalidate(uspIpv6PortServiceProvider),
                  ),
                AppIconButton(
                  icon: AppIcon.font(Icons.add, size: 20),
                  onTap: isMutating ? null : () => _showAddDialog(context, ref),
                ),
              ],
            ),
          ],
        ),
        AppGap.lg(),
        if (rules.isEmpty)
          AppText.bodyMedium('No IPv6 port service rules configured')
        else
          ...rules.map((r) => _buildRuleCard(context, ref, r, isMutating)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Rule Card
  // ---------------------------------------------------------------------------

  Widget _buildRuleCard(
    BuildContext context,
    WidgetRef ref,
    Ipv6PortServiceRuleUIModel rule,
    bool isMutating,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            AppSwitch(
              value: rule.enabled,
              scale: 0.8,
              onChanged: isMutating
                  ? null
                  : (value) => _toggleRule(context, ref, rule, value),
            ),
            AppGap.sm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.bodyMedium(
                    rule.description.isNotEmpty
                        ? rule.description
                        : '(unnamed)',
                  ),
                  AppText.bodySmall(
                    rule.ipv6Address,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  AppText.bodySmall(
                    '${rule.protocol} | Port ${rule.portDisplay}',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.edit, size: 18),
              onTap:
                  isMutating ? null : () => _showEditDialog(context, ref, rule),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.delete_outline, size: 18),
              onTap:
                  isMutating ? null : () => _confirmDelete(context, ref, rule),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleRule(BuildContext context, WidgetRef ref,
      Ipv6PortServiceRuleUIModel rule, bool value) async {
    try {
      await ref
          .read(uspIpv6PortServiceProvider.notifier)
          .toggleRule(rule.instancePath, value);
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    }
  }

  List<AutoCompleteOption> _buildIpv6DeviceOptions(WidgetRef ref) {
    final devices =
        ref.read(uspDashboardProvider).valueOrNull?.deviceModels ?? [];
    return devices
        .expand((d) => d.ipv6Addresses.map((addr) => AutoCompleteOption(
              label: d.displayName,
              value: addr,
              subtitle: d.mac,
              isActive: d.isActive,
            )))
        .toList();
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final deviceOptions = _buildIpv6DeviceOptions(ref);
    final result = await showDialog<Ipv6PortServiceRuleDialogResult>(
      context: context,
      builder: (_) => Ipv6PortServiceRuleDialog(deviceOptions: deviceOptions),
    );
    if (result == null || !context.mounted) return;
    final svc = ref.read(uspIpv6PortServiceServiceProvider);
    try {
      await ref.read(uspIpv6PortServiceProvider.notifier).addRule(
            description: result.description,
            ipv6Address: result.ipv6Address,
            protocol: svc.mapDisplayToIana(result.protocol),
            startPort: result.startPort,
            endPort: result.endPort,
            enabled: result.enabled,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Rule added');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref,
      Ipv6PortServiceRuleUIModel rule) async {
    final deviceOptions = _buildIpv6DeviceOptions(ref);
    final result = await showDialog<Ipv6PortServiceRuleDialogResult>(
      context: context,
      builder: (_) =>
          Ipv6PortServiceRuleDialog(rule: rule, deviceOptions: deviceOptions),
    );
    if (result == null || !context.mounted) return;
    final svc = ref.read(uspIpv6PortServiceServiceProvider);
    try {
      await ref.read(uspIpv6PortServiceProvider.notifier).updateRule(
            instancePath: rule.instancePath,
            description: result.description,
            ipv6Address: result.ipv6Address,
            protocol: svc.mapDisplayToIana(result.protocol),
            startPort: result.startPort,
            endPort: result.endPort,
            enabled: result.enabled,
          );
      if (context.mounted) showSuccessSnackBar(context, 'Rule updated');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      Ipv6PortServiceRuleUIModel rule) async {
    final confirmed = await showSimpleAppDialog<bool>(
      context,
      title: 'Delete Rule',
      content: AppText.bodyMedium(
          'Delete "${rule.description.isNotEmpty ? rule.description : 'this rule'}"?'),
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
    try {
      await ref
          .read(uspIpv6PortServiceProvider.notifier)
          .deleteRule(rule.instancePath);
      if (context.mounted) showSuccessSnackBar(context, 'Rule deleted');
    } catch (e) {
      if (context.mounted) showFailedSnackBar(context, 'Error: $e');
    }
  }
}
