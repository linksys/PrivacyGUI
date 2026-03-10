import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/local_network/providers/usp_local_network_notifier.dart';
import 'package:privacy_gui/usp_page/local_network/services/usp_local_network_service.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
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
  void _syncControllers(UspLocalNetworkState state) {
    final p = state.pending;
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
    final asyncState = ref.watch(uspLocalNetworkProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      onRefresh: () => ref.refresh(uspLocalNetworkProvider.future),
      padding:
          const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => _buildError(context, ref),
          data: (state) {
            _syncControllers(state);
            return _buildContent(context, ref, state);
          },
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
          AppText.titleMedium('Unable to load local network settings'),
          AppGap.md(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspLocalNetworkProvider),
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
    UspLocalNetworkState state,
  ) {
    final disabled = state.isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref),
        AppGap.xl(),
        _buildRouterCard(context, state, disabled),
        AppGap.md(),
        _buildDhcpCard(context, state, disabled),
        if (state.isDirty) ...[
          AppGap.xl(),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: 'Save',
              onTap: disabled || state.hasErrors
                  ? null
                  : () => _onSave(context, ref, state),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        AppIconButton(
          icon: AppIcon.font(Icons.arrow_back),
          onTap: () => context.canPop()
              ? context.pop()
              : context.goNamed(RouteNamed.uspMenu),
        ),
        AppGap.md(),
        Expanded(
          child: AppText.headlineSmall('Local Network'),
        ),
        AppIconButton(
          icon: AppIcon.font(Icons.refresh),
          onTap: () => ref.invalidate(uspLocalNetworkProvider),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Router Info Card
  // ---------------------------------------------------------------------------

  Widget _buildRouterCard(
    BuildContext context,
    UspLocalNetworkState state,
    bool disabled,
  ) {
    final notifier = ref.read(uspLocalNetworkProvider.notifier);
    final errors = state.errors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('Router'),
          AppGap.lg(),
          AppTextFormField(
            controller: _hostNameController,
            label: 'Hostname',
            onChanged: (v) =>
                notifier.updateSetting((m) => m.copyWith(hostName: v)),
            externalErrorText: errors['hostName'],
            enabled: !disabled,
          ),
          AppGap.md(),
          AppIpv4TextField(
            controller: _ipAddressController,
            label: 'IP Address',
            onChanged: (v) =>
                notifier.updateSetting((m) => m.copyWith(ipAddress: v)),
            errorText: errors['ipAddress'],
            enabled: !disabled,
          ),
          AppGap.md(),
          AppIpv4TextField(
            controller: _subnetMaskController,
            label: 'Subnet Mask',
            onChanged: (v) =>
                notifier.updateSetting((m) => m.copyWith(subnetMask: v)),
            errorText: errors['subnetMask'],
            enabled: !disabled,
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
    UspLocalNetworkState state,
    bool disabled,
  ) {
    final notifier = ref.read(uspLocalNetworkProvider.notifier);
    final svc = ref.read(uspLocalNetworkServiceProvider);
    final pending = state.pending;
    final errors = state.errors;

    // Lock prefix octets based on subnet mask (e.g. /24 → lock first 3)
    final lockedOctets = svc.lockedOctetCount(pending.subnetMask);
    final poolReadOnly = SegmentReadOnly.lockPrefix(lockedOctets);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleSmall('DHCP Server'),
              AppSwitch(
                value: pending.dhcpEnabled,
                onChanged: disabled
                    ? null
                    : (v) => notifier
                        .updateSetting((m) => m.copyWith(dhcpEnabled: v)),
              ),
            ],
          ),
          // DHCP fields — only shown when enabled
          if (pending.dhcpEnabled) ...[
            AppGap.lg(),
            AppIpv4TextField(
              controller: _minAddressController,
              label: 'Pool Start',
              onChanged: (v) =>
                  notifier.updateSetting((m) => m.copyWith(minAddress: v)),
              errorText: errors['minAddress'],
              readOnly: poolReadOnly,
              enabled: !disabled,
            ),
            AppGap.md(),
            AppIpv4TextField(
              controller: _maxAddressController,
              label: 'Pool End',
              onChanged: (v) =>
                  notifier.updateSetting((m) => m.copyWith(maxAddress: v)),
              errorText: errors['maxAddress'],
              readOnly: poolReadOnly,
              enabled: !disabled,
            ),
            AppGap.md(),
            AppTextFormField(
              controller: _leaseTimeController,
              label: 'Lease Time (minutes)',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final minutes = int.tryParse(v) ?? 0;
                notifier.updateSetting(
                    (m) => m.copyWith(leaseTimeMinutes: minutes));
              },
              externalErrorText: errors['leaseTime'],
              enabled: !disabled,
            ),
            AppGap.lg(),
            AppText.labelMedium('DNS Servers'),
            AppGap.sm(),
            AppIpv4TextField(
              controller: _dns1Controller,
              label: 'DNS Server 1',
              onChanged: (v) =>
                  notifier.updateSetting((m) => m.copyWith(dnsServer1: v)),
              errorText: errors['dnsServer1'],
              enabled: !disabled,
            ),
            AppGap.md(),
            AppIpv4TextField(
              controller: _dns2Controller,
              label: 'DNS Server 2',
              onChanged: (v) =>
                  notifier.updateSetting((m) => m.copyWith(dnsServer2: v)),
              errorText: errors['dnsServer2'],
              enabled: !disabled,
            ),
            AppGap.md(),
            AppIpv4TextField(
              controller: _dns3Controller,
              label: 'DNS Server 3',
              onChanged: (v) =>
                  notifier.updateSetting((m) => m.copyWith(dnsServer3: v)),
              errorText: errors['dnsServer3'],
              enabled: !disabled,
            ),
            AppGap.lg(),
            AppButton.text(
              label: 'View DHCP Reservations',
              icon: AppIcon.font(Icons.arrow_forward, size: 16),
              onTap: () => context.goNamed(RouteNamed.uspDhcpDetail),
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
    UspLocalNetworkState state,
  ) async {
    // Warn if router IP or subnet changed (may cause disconnection)
    if (state.hasNetworkChange) {
      final confirmed = await _showNetworkChangeConfirmation(context);
      if (confirmed != true) return;
    }

    try {
      await ref.read(uspLocalNetworkProvider.notifier).save();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local network settings saved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<bool?> _showNetworkChangeConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Network Settings?'),
        content: const Text(
          'Changing the router IP address or subnet mask may cause a temporary '
          'loss of connection. DHCP reservations may also become invalid.\n\n'
          'Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
