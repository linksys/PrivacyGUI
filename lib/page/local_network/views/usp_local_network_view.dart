import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Local Network Settings page.
///
/// Sections: Router info (hostname, IP, subnet) + DHCP server settings.
/// Uses cascade validation — changing router IP immediately validates pool range.
class UspLocalNetworkView extends ConsumerStatefulWidget {
  const UspLocalNetworkView({super.key});

  @override
  ConsumerState<UspLocalNetworkView> createState() =>
      _UspLocalNetworkViewState();
}

class _UspLocalNetworkViewState extends ConsumerState<UspLocalNetworkView> {
  late TextEditingController _hostNameController;
  late TextEditingController _ipAddressController;
  late TextEditingController _subnetMaskController;
  late TextEditingController _minAddressController;
  late TextEditingController _maxAddressController;
  late TextEditingController _leaseTimeController;
  late TextEditingController _dns1Controller;
  late TextEditingController _dns2Controller;
  late TextEditingController _dns3Controller;

  @override
  void initState() {
    super.initState();
    _hostNameController = TextEditingController();
    _ipAddressController = TextEditingController();
    _subnetMaskController = TextEditingController();
    _minAddressController = TextEditingController();
    _maxAddressController = TextEditingController();
    _leaseTimeController = TextEditingController();
    _dns1Controller = TextEditingController();
    _dns2Controller = TextEditingController();
    _dns3Controller = TextEditingController();
  }

  @override
  void dispose() {
    _hostNameController.dispose();
    _ipAddressController.dispose();
    _subnetMaskController.dispose();
    _minAddressController.dispose();
    _maxAddressController.dispose();
    _leaseTimeController.dispose();
    _dns1Controller.dispose();
    _dns2Controller.dispose();
    _dns3Controller.dispose();
    super.dispose();
  }

  /// Sync controllers when state data arrives or changes.
  void _syncControllers(LocalNetworkFeatureState state) {
    final p = state.settings.current.model;
    _syncOne(_hostNameController, p.hostName);
    _syncOne(_ipAddressController, p.ipAddress);
    _syncOne(_subnetMaskController, p.subnetMask);
    _syncOne(_minAddressController, p.minAddress);
    _syncOne(_maxAddressController, p.maxAddress);
    _syncOne(_leaseTimeController,
        p.leaseTimeMinutes > 0 ? '${p.leaseTimeMinutes}' : '');
    _syncOne(_dns1Controller, p.dnsServer1);
    _syncOne(_dns2Controller, p.dnsServer2);
    _syncOne(_dns3Controller, p.dnsServer3);
  }

  void _syncOne(TextEditingController c, String value) {
    if (c.text != value) c.text = value;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(uspLocalNetworkProvider);
    final status = state.status;

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).localNetwork,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdvancedSettings,
      onRefresh: () =>
          ref.read(uspLocalNetworkProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (status.error != null) {
          return ServiceErrorView(
            error: status.error,
            onRetry: () => ref
                .read(uspLocalNetworkProvider.notifier)
                .fetch(forceRemote: true),
          );
        }
        _syncControllers(state);
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
    LocalNetworkFeatureState state,
  ) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled:
          !state.status.isSaving && !state.status.hasValidationErrors,
      onPositiveTap: () => _onSave(context, ref, state),
      onNegativeTap: () => ref.read(uspLocalNetworkProvider.notifier).revert(),
    );
  }

  // ---------------------------------------------------------------------------
  // Content
  // ---------------------------------------------------------------------------

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    LocalNetworkFeatureState state,
  ) {
    final disabled = state.status.isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRouterCard(context, state, disabled),
        AppGap.md(),
        _buildDhcpCard(context, state, disabled),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Router Info Card
  // ---------------------------------------------------------------------------

  Widget _buildRouterCard(
    BuildContext context,
    LocalNetworkFeatureState state,
    bool disabled,
  ) {
    final notifier = ref.read(uspLocalNetworkProvider.notifier);
    final errors = state.status.validationErrors;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall(loc(context).router),
          AppGap.md(),
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                AppTextFormField(
                  controller: _hostNameController,
                  label: loc(context).hostname,
                  onChanged: (v) =>
                      notifier.updateSetting((m) => m.copyWith(hostName: v)),
                  externalErrorText: errors['hostName'],
                  enabled: !disabled,
                ),
                AppGap.md(),
                AppIpv4TextField(
                  controller: _ipAddressController,
                  label: loc(context).ipAddress,
                  onChanged: (v) =>
                      notifier.updateSetting((m) => m.copyWith(ipAddress: v)),
                  errorText: errors['ipAddress'],
                  enabled: !disabled,
                ),
                AppGap.md(),
                AppIpv4TextField(
                  controller: _subnetMaskController,
                  label: loc(context).subnetMask,
                  onChanged: (v) =>
                      notifier.updateSetting((m) => m.copyWith(subnetMask: v)),
                  errorText: errors['subnetMask'],
                  enabled: !disabled,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DHCP Server Card
  // ---------------------------------------------------------------------------

  Widget _buildDhcpCard(
    BuildContext context,
    LocalNetworkFeatureState state,
    bool disabled,
  ) {
    final notifier = ref.read(uspLocalNetworkProvider.notifier);
    final pending = state.settings.current.model;
    final errors = state.status.validationErrors;

    final poolReadOnly =
        SegmentReadOnly.lockPrefix(state.status.lockedOctetCount);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          LayoutBlock(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.titleSmall(loc(context).dhcpServer),
                AppSwitch(
                  value: pending.dhcpEnabled,
                  onChanged: disabled
                      ? null
                      : (v) => notifier
                          .updateSetting((m) => m.copyWith(dhcpEnabled: v)),
                ),
              ],
            ),
          ),
          // DHCP fields — only shown when enabled
          if (pending.dhcpEnabled) ...[
            AppGap.sm(),
            // Pool Settings Block
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelMedium(loc(context).addressPool),
                  AppGap.md(),
                  AppIpv4TextField(
                    controller: _minAddressController,
                    label: loc(context).poolStart,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(minAddress: v)),
                    errorText: errors['minAddress'],
                    readOnly: poolReadOnly,
                    enabled: !disabled,
                  ),
                  AppGap.md(),
                  AppIpv4TextField(
                    controller: _maxAddressController,
                    label: loc(context).poolEnd,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(maxAddress: v)),
                    errorText: errors['maxAddress'],
                    readOnly: poolReadOnly,
                    enabled: !disabled,
                  ),
                  AppGap.md(),
                  AppTextFormField(
                    controller: _leaseTimeController,
                    label: loc(context).leaseTimeMinutes,
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final minutes = int.tryParse(v) ?? 0;
                      notifier.updateSetting(
                          (m) => m.copyWith(leaseTimeMinutes: minutes));
                    },
                    externalErrorText: errors['leaseTime'],
                    enabled: !disabled,
                  ),
                ],
              ),
            ),
            AppGap.sm(),
            // DNS Servers Block
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelMedium(loc(context).dnsServers),
                  AppGap.md(),
                  AppIpv4TextField(
                    controller: _dns1Controller,
                    label: loc(context).dnsServer1,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(dnsServer1: v)),
                    errorText: errors['dnsServer1'],
                    enabled: !disabled,
                  ),
                  AppGap.md(),
                  AppIpv4TextField(
                    controller: _dns2Controller,
                    label: loc(context).dnsServer2,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(dnsServer2: v)),
                    errorText: errors['dnsServer2'],
                    enabled: !disabled,
                  ),
                  AppGap.md(),
                  AppIpv4TextField(
                    controller: _dns3Controller,
                    label: loc(context).dnsServer3,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(dnsServer3: v)),
                    errorText: errors['dnsServer3'],
                    enabled: !disabled,
                  ),
                ],
              ),
            ),
            AppGap.sm(),
            // Reservations Link Block
            LayoutBlock(
              onTap: () => context.goNamed(RouteNamed.uspDhcpDetail),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.bodyMedium(loc(context).viewDhcpReservations),
                  AppIcon.font(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(
    BuildContext context,
    WidgetRef ref,
    LocalNetworkFeatureState state,
  ) async {
    // Warn if router IP or subnet changed (may cause disconnection)
    if (state.hasNetworkChange) {
      final confirmed = await _showNetworkChangeConfirmation(context);
      if (confirmed != true || !context.mounted) return;
    }

    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspLocalNetworkProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).localNetworkSettingsSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }

  Future<bool?> _showNetworkChangeConfirmation(BuildContext context) {
    return showAppDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc(context).changeNetworkSettingsTitle),
        content: Text(loc(context).changeNetworkSettingsDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(loc(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(loc(context).textContinue),
          ),
        ],
      ),
    );
  }
}
