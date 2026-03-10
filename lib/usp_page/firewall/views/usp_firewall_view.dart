import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/usp_page/firewall/providers/usp_firewall_notifier.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Firewall settings page — SPI firewall, VPN passthrough, internet filters.
class UspFirewallView extends ConsumerWidget {
  const UspFirewallView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspFirewallProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      onRefresh: () => ref.refresh(uspFirewallProvider.future),
      padding:
          const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
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
          AppText.titleMedium('Unable to load firewall settings'),
          AppGap.md(),
          AppButton(
            label: 'Retry',
            onTap: () => ref.invalidate(uspFirewallProvider),
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
    UspFirewallState state,
  ) {
    final notifier = ref.read(uspFirewallProvider.notifier);
    final fw = state.pending;
    final disabled = state.isSaving;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, ref),
        AppGap.md(),
        AppText.bodyMedium(
          'Configure firewall and VPN passthrough settings',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.xl(),
        _buildFirewallSection(context, fw, notifier, disabled),
        AppGap.md(),
        _buildVpnSection(context, fw, notifier, disabled),
        AppGap.md(),
        _buildFiltersSection(context, fw, notifier, disabled),
        AppGap.md(),
        _buildIpv6PortServiceLink(context),
        if (state.isDirty) ...[
          AppGap.xl(),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: 'Save',
              onTap: disabled ? null : () => _onSave(context, ref),
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
          child: AppText.headlineSmall('Firewall'),
        ),
        AppIconButton(
          icon: AppIcon.font(Icons.refresh),
          onTap: () => ref.invalidate(uspFirewallProvider),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Firewall Protection Section
  // ---------------------------------------------------------------------------

  Widget _buildFirewallSection(
    BuildContext context,
    FirewallUIModel fw,
    UspFirewallNotifier notifier,
    bool disabled,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('Firewall Protection'),
          AppGap.lg(),
          _switchRow(
            context,
            label: 'IPv4 SPI Firewall',
            value: fw.isIPv4FirewallEnabled,
            disabled: disabled,
            onChanged: (v) => notifier.updateSetting(
              (m) => m.copyWith(isIPv4FirewallEnabled: v),
            ),
          ),
          const Divider(height: 1),
          _switchRow(
            context,
            label: 'IPv6 SPI Firewall',
            value: fw.isIPv6FirewallEnabled,
            disabled: disabled,
            onChanged: (v) => notifier.updateSetting(
              (m) => m.copyWith(isIPv6FirewallEnabled: v),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VPN Passthrough Section
  // ---------------------------------------------------------------------------

  Widget _buildVpnSection(
    BuildContext context,
    FirewallUIModel fw,
    UspFirewallNotifier notifier,
    bool disabled,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('VPN Passthrough'),
          AppGap.lg(),
          _switchRow(
            context,
            label: 'IPSec Passthrough',
            value: !fw.blockIPSec,
            disabled: disabled,
            onChanged: (v) => notifier.updateSetting(
              (m) => m.copyWith(blockIPSec: !v),
            ),
          ),
          const Divider(height: 1),
          _switchRow(
            context,
            label: 'PPTP Passthrough',
            value: !fw.blockPPTP,
            disabled: disabled,
            onChanged: (v) => notifier.updateSetting(
              (m) => m.copyWith(blockPPTP: !v),
            ),
          ),
          const Divider(height: 1),
          _switchRow(
            context,
            label: 'L2TP Passthrough',
            value: !fw.blockL2TP,
            disabled: disabled,
            onChanged: (v) => notifier.updateSetting(
              (m) => m.copyWith(blockL2TP: !v),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Internet Filters Section
  // ---------------------------------------------------------------------------

  Widget _buildFiltersSection(
    BuildContext context,
    FirewallUIModel fw,
    UspFirewallNotifier notifier,
    bool disabled,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleSmall('Internet Filters'),
          AppGap.lg(),
          _switchRow(
            context,
            label: 'Filter Anonymous Requests',
            value: fw.blockAnonymousRequests,
            disabled: disabled,
            onChanged: (v) => notifier.updateSetting(
              (m) => m.copyWith(blockAnonymousRequests: v),
            ),
          ),
          const Divider(height: 1),
          _switchRow(
            context,
            label: 'Filter Multicast',
            value: fw.blockMulticast,
            disabled: disabled,
            onChanged: (v) => notifier.updateSetting(
              (m) => m.copyWith(blockMulticast: v),
            ),
          ),
          const Divider(height: 1),
          _switchRow(
            context,
            label: 'Filter IDENT (Port 113)',
            value: fw.blockIDENT,
            disabled: disabled,
            onChanged: (v) => notifier.updateSetting(
              (m) => m.copyWith(blockIDENT: v),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared toggle row
  // ---------------------------------------------------------------------------

  Widget _switchRow(
    BuildContext context, {
    required String label,
    required bool value,
    required bool disabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: AppText.labelLarge(label)),
          AppSwitch(
            value: value,
            onChanged: disabled ? null : onChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // IPv6 Port Service Link
  // ---------------------------------------------------------------------------

  Widget _buildIpv6PortServiceLink(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: () => context.goNamed(RouteNamed.uspIpv6PortService),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleSmall('IPv6 Port Service'),
                  AppGap.xs(),
                  AppText.bodySmall(
                    'Manage IPv6 inbound port access rules',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            AppIcon.font(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(uspFirewallProvider.notifier).save();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firewall settings saved')),
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
}
