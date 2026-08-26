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
import 'package:privacy_gui/page/local_network/views/helpers/lan_ip_redirect_dialog.dart';
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

  final _hostNameFocus = FocusNode();
  final _leaseTimeFocus = FocusNode();

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

    _hostNameFocus.addListener(_onTextFieldFocusChange);
    _leaseTimeFocus.addListener(_onTextFieldFocusChange);
  }

  void _onTextFieldFocusChange() {
    if (!_hostNameFocus.hasFocus && !_leaseTimeFocus.hasFocus) {
      ref.read(uspLocalNetworkProvider.notifier).validate();
    }
  }

  void _onIpv4FocusChanged(int? index, bool hasFocus) {
    // Only validate when focus leaves the entire IPv4 field
    if (index == null && !hasFocus) {
      ref.read(uspLocalNetworkProvider.notifier).validate();
    }
  }

  @override
  void dispose() {
    _hostNameFocus.removeListener(_onTextFieldFocusChange);
    _leaseTimeFocus.removeListener(_onTextFieldFocusChange);

    _hostNameFocus.dispose();
    _leaseTimeFocus.dispose();

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
            title: loc(context).failedToLoadSettings,
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
    // Always return a config to keep widget tree stable.
    // Returning null when !isDirty causes tree structure change,
    // which triggers TextField unfocus on Flutter Web.
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: state.isDirty &&
          !state.status.isSaving &&
          !state.status.hasValidationErrors,
      isNegativeEnabled: state.isDirty,
      onPositiveTap: state.isDirty ? () => _onSave(context, ref, state) : null,
      onNegativeTap: state.isDirty
          ? () => ref.read(uspLocalNetworkProvider.notifier).revert()
          : null,
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
                  identifier: 'local-network-hostname',
                  controller: _hostNameController,
                  focusNode: _hostNameFocus,
                  label: loc(context).hostname,
                  onChanged: (v) =>
                      notifier.updateSetting((m) => m.copyWith(hostName: v)),
                  externalErrorText: errors['hostName'],
                  enabled: !disabled,
                ),
                AppGap.md(),
                AppIpv4TextField(
                  identifier: 'local-network-ip-address',
                  controller: _ipAddressController,
                  label: loc(context).ipAddress,
                  onChanged: (v) =>
                      notifier.updateSetting((m) => m.copyWith(ipAddress: v)),
                  onFocusChanged: _onIpv4FocusChanged,
                  errorText: errors['ipAddress'],
                  enabled: !disabled,
                ),
                AppGap.md(),
                AppIpv4TextField(
                  identifier: 'local-network-subnet-mask',
                  controller: _subnetMaskController,
                  label: loc(context).subnetMask,
                  onChanged: (v) =>
                      notifier.updateSetting((m) => m.copyWith(subnetMask: v)),
                  onFocusChanged: _onIpv4FocusChanged,
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
                  identifier: 'local-network-dhcp-enable',
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
                    identifier: 'local-network-pool-start',
                    controller: _minAddressController,
                    label: loc(context).poolStart,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(minAddress: v)),
                    onFocusChanged: _onIpv4FocusChanged,
                    errorText: errors['minAddress'],
                    readOnly: poolReadOnly,
                    enabled: !disabled,
                  ),
                  AppGap.md(),
                  AppIpv4TextField(
                    identifier: 'local-network-pool-end',
                    controller: _maxAddressController,
                    label: loc(context).poolEnd,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(maxAddress: v)),
                    onFocusChanged: _onIpv4FocusChanged,
                    errorText: errors['maxAddress'],
                    readOnly: poolReadOnly,
                    enabled: !disabled,
                  ),
                  AppGap.md(),
                  AppTextFormField(
                    identifier: 'local-network-lease-time',
                    controller: _leaseTimeController,
                    focusNode: _leaseTimeFocus,
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
                    identifier: 'local-network-dns1',
                    controller: _dns1Controller,
                    label: loc(context).dnsServer1,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(dnsServer1: v)),
                    onFocusChanged: _onIpv4FocusChanged,
                    errorText: errors['dnsServer1'],
                    enabled: !disabled,
                  ),
                  AppGap.md(),
                  AppIpv4TextField(
                    identifier: 'local-network-dns2',
                    controller: _dns2Controller,
                    label: loc(context).dnsServer2,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(dnsServer2: v)),
                    onFocusChanged: _onIpv4FocusChanged,
                    errorText: errors['dnsServer2'],
                    enabled: !disabled,
                  ),
                  AppGap.md(),
                  AppIpv4TextField(
                    identifier: 'local-network-dns3',
                    controller: _dns3Controller,
                    label: loc(context).dnsServer3,
                    onChanged: (v) => notifier
                        .updateSetting((m) => m.copyWith(dnsServer3: v)),
                    onFocusChanged: _onIpv4FocusChanged,
                    errorText: errors['dnsServer3'],
                    enabled: !disabled,
                  ),
                ],
              ),
            ),
            AppGap.sm(),
            // Reservations Link Block
            LayoutBlock(
              identifier: 'local-network-dhcp-reservations',
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
    // Read the change intent and hostname BEFORE saving: save() collapses
    // original into current (markAsSaved) and may drop SSE, so these must be
    // captured up front. The disconnection warning covers any IP/subnet change,
    // but only an IP address change makes the old origin unreachable and
    // triggers the redirect. hostName is the redirect target
    // (https://<hostName>.local).
    final networkChanged = state.hasNetworkChange;
    final ipChanged = state.hasIpAddressChange;
    final hostName = state.settings.current.model.hostName;

    // Warn if router IP or subnet changed (may cause disconnection)
    if (networkChanged) {
      final confirmed = await _showNetworkChangeConfirmation(context);
      if (confirmed != true || !context.mounted) return;
    }

    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspLocalNetworkProvider.notifier).save(),
      );
      if (!context.mounted) return;

      // Only redirect after a confirmed save when the IP address actually
      // changed: the old address is now unreachable, so the browser must be
      // sent to the router's new .local address. On native, showLanIpRedirect
      // Dialog's navigate is a no-op. Otherwise (mask-only or DHCP fields),
      // the connection survives — stay on the page with a success message.
      if (ipChanged && hostName.isNotEmpty) {
        await showLanIpRedirectDialog(context, hostName: hostName);
      } else {
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
          AppButton.text(
            identifier: 'network-change-cancel',
            label: loc(context).cancel,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          AppButton.text(
            identifier: 'network-change-continue',
            label: loc(context).textContinue,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
  }
}
