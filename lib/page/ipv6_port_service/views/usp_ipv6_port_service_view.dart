import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_feature_state.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/ipv6_port_service/providers/usp_ipv6_port_service_notifier.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/dialogs/ipv6_port_service_rule_dialog.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

class UspIpv6PortServiceView extends ConsumerWidget {
  const UspIpv6PortServiceView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspIpv6PortServiceProvider);
    final status = state.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'IPv6 Port Service',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdvancedSettings,
      onRefresh: () => ref
          .read(uspIpv6PortServiceProvider.notifier)
          .fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (status.errorMessage != null) {
          return _buildError(context, ref);
        }
        return _buildContent(context, ref, state);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Bar
  // ---------------------------------------------------------------------------

  UiKitBottomBarConfig? _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    Ipv6PortServiceFeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: 'Save',
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () =>
          ref.read(uspIpv6PortServiceProvider.notifier).revert(),
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
            onTap: () => ref
                .read(uspIpv6PortServiceProvider.notifier)
                .fetch(forceRemote: true),
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
    Ipv6PortServiceFeatureState state,
  ) {
    final rules = state.settings.current.rules;
    final isSaving = state.status.isSaving;

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
            AppIconButton(
              icon: AppIcon.font(Icons.add, size: 20),
              onTap: isSaving ? null : () => _showAddDialog(context, ref),
            ),
          ],
        ),
        AppGap.lg(),
        if (rules.isEmpty)
          AppText.bodyMedium('No IPv6 port service rules configured')
        else
          ...rules.asMap().entries.map((entry) =>
              _buildRuleCard(context, ref, entry.key, entry.value, isSaving)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Rule Card
  // ---------------------------------------------------------------------------

  Widget _buildRuleCard(
    BuildContext context,
    WidgetRef ref,
    int index,
    Ipv6PortServiceRuleUIModel rule,
    bool isSaving,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Row(
          children: [
            AppSwitch(
              value: rule.enabled,
              scale: 0.8,
              onChanged: isSaving
                  ? null
                  : (value) => ref
                      .read(uspIpv6PortServiceProvider.notifier)
                      .toggleRule(index, value),
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
              onTap: isSaving
                  ? null
                  : () => _showEditDialog(context, ref, index, rule),
            ),
            AppIconButton(
              icon: AppIcon.font(Icons.delete_outline, size: 18),
              onTap: isSaving
                  ? null
                  : () => ref
                      .read(uspIpv6PortServiceProvider.notifier)
                      .deleteRule(index),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  List<AppAutoCompleteOption> _buildIpv6DeviceOptions(WidgetRef ref) {
    final devices =
        ref.read(devicesDataProvider).valueOrNull?.deviceModels ?? [];
    return devices
        .expand((d) => d.ipv6Addresses.map((addr) => AppAutoCompleteOption(
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
    ref.read(uspIpv6PortServiceProvider.notifier).addRule(
          Ipv6PortServiceRuleUIModel(
            enabled: result.enabled,
            description: result.description,
            ipv6Address: result.ipv6Address,
            protocol: result.protocol,
            startPort: result.startPort,
            endPort: result.endPort,
          ),
        );
  }

  Future<void> _showEditDialog(BuildContext context, WidgetRef ref, int index,
      Ipv6PortServiceRuleUIModel rule) async {
    final deviceOptions = _buildIpv6DeviceOptions(ref);
    final result = await showDialog<Ipv6PortServiceRuleDialogResult>(
      context: context,
      builder: (_) =>
          Ipv6PortServiceRuleDialog(rule: rule, deviceOptions: deviceOptions),
    );
    if (result == null || !context.mounted) return;
    ref.read(uspIpv6PortServiceProvider.notifier).editRule(
          index,
          rule.copyWith(
            enabled: result.enabled,
            description: result.description,
            ipv6Address: result.ipv6Address,
            protocol: result.protocol,
            startPort: result.startPort,
            endPort: result.endPort,
          ),
        );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(uspIpv6PortServiceProvider.notifier).save();
      if (context.mounted) {
        showSuccessSnackBar(context, 'IPv6 port rules saved');
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, 'Failed to save: $e');
      }
    }
  }
}
