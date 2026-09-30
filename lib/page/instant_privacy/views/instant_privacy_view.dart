import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_add_device_dialog.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Instant Privacy page — a single Allow/Off toggle that locks the network to a
/// whitelist. Save-based: enabling pre-populates the list with every online
/// device, edits stay local until the bottom Save bar is used. Shares the
/// `X_LINKSYS_SetMACFilter` backend with the MAC Filter page (Deny); the two are
/// mutually exclusive.
class InstantPrivacyView extends ConsumerWidget {
  const InstantPrivacyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspInstantPrivacyProvider);
    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).instantPrivacy,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () =>
          ref.read(uspInstantPrivacyProvider.notifier).fetch(forceRemote: true),
      bottomBar: _buildBottomBar(context, ref, state),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (state.status.isLoading) {
          return const Center(child: AppLoader());
        }
        if (state.status.error != null) {
          return ServiceErrorView(
            error: state.status.error,
            title: loc(context).failedToLoadSettings,
            onRetry: () => ref.invalidate(uspInstantPrivacyProvider),
          );
        }
        return _buildContent(context, ref, state);
      },
    );
  }

  UiKitBottomBarConfig? _buildBottomBar(
      BuildContext context, WidgetRef ref, UspInstantPrivacyState state) {
    if (!state.isDirty) return null;
    // The firmware refuses `Allow` with an empty list and any list over the
    // limit, so neither can be saved. Turning on pre-fills every online device,
    // so the list can start over the limit: rows are removed until it fits, or
    // the switch is turned back off.
    final macs = state.allowedMacs;
    final unsaveable = state.isEnabled &&
        (macs.isEmpty || macs.length > UspMacFilterService.maxAddresses);
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: !state.status.isSaving && !unsaveable,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () =>
          ref.read(uspInstantPrivacyProvider.notifier).revert(),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, UspInstantPrivacyState state) {
    final isEnabled = state.isEnabled;
    final hasPrivateMac = _listedPrivateMac(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(loc(context).instantPrivacyPageDesc),
        // Read off the applied mode, so it stays up while this page's switch is
        // being turned on — until Save actually turns MAC Filtering off.
        if (state.isOtherFilterOn) ...[
          AppGap.md(),
          _buildOtherFilterOnBanner(context),
        ],
        if (hasPrivateMac) ...[
          AppGap.md(),
          _buildPrivateMacWarningBanner(context),
        ],
        AppGap.lg(),
        _buildToggleCard(context, ref, state),
        if (isEnabled) ...[
          AppGap.lg(),
          _buildDeviceList(context, ref, state),
        ],
      ],
    );
  }

  /// Whether any MAC in the current allow-list belongs to a private-MAC device.
  bool _listedPrivateMac(UspInstantPrivacyState state) {
    final privateMacs = state.connectedDevices
        .where((d) => d.isPrivateMac)
        .map((d) => d.mac.toUpperCase())
        .toSet();
    return state.allowedMacs.any((m) => privateMacs.contains(m.toUpperCase()));
  }

  Widget _buildToggleCard(
      BuildContext context, WidgetRef ref, UspInstantPrivacyState state) {
    final isEnabled = state.isEnabled;
    final isSaving = state.status.isSaving;
    // Turning on pre-fills the list with the online devices, so with none online
    // it would be an empty `Allow` list — refused by the firmware. Off stays
    // reachable: this only blocks the off → on direction.
    final cannotEnable = !isEnabled && state.connectedDevices.isEmpty;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBlock(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(loc(context).instantPrivacy),
                  AppGap.xs(),
                  AppText.bodySmall(isEnabled
                      ? loc(context).onlyAllowedDevicesCanConnect
                      : cannotEnable
                          ? loc(context).instantPrivacyCannotBeEnabled
                          : loc(context).allDevicesCanConnectFreely),
                ],
              ),
            ),
            AppSwitch(
              identifier: 'instant-privacy-enable',
              value: isEnabled,
              isLoading: isSaving,
              busySemanticLabel: isSaving ? loc(context).processing : null,
              onChanged:
                  isSaving || cannotEnable ? null : (v) => _onToggle(ref, v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(
      BuildContext context, WidgetRef ref, UspInstantPrivacyState state) {
    final macs = state.allowedMacs;
    final atLimit = macs.length >= UspMacFilterService.maxAddresses;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap, not Row: header + Add reflow rather than overflow (#1380).
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.sm,
            children: [
              AppText.labelLarge(loc(context).allowedDevicesCount(macs.length)),
              AppButton.text(
                identifier: 'instant-privacy-add-device',
                label: loc(context).addDevice,
                onTap:
                    atLimit ? null : () => _showAddDialog(context, ref, state),
              ),
            ],
          ),
          AppGap.md(),
          if (atLimit) ...[
            AppText.bodySmall(loc(context)
                .macFilterMaxReached(UspMacFilterService.maxAddresses)),
            AppGap.sm(),
          ],
          if (macs.isEmpty)
            AppText.bodySmall(loc(context).noDevicesInAllowedList)
          else
            ...macs.map((mac) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildDeviceRow(context, ref, state, mac),
                )),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(BuildContext context, WidgetRef ref,
      UspInstantPrivacyState state, String mac) {
    final colorScheme = Theme.of(context).colorScheme;
    final device = state.connectedDevices
        .where((d) => d.mac.toUpperCase() == mac.toUpperCase())
        .firstOrNull;
    // A name over its MAC, or the MAC alone. No name is the usual case for a
    // listed device that is offline — the router clears its Hosts name then — and
    // an online one with no hostname carries its MAC as its display name.
    final displayName = device?.displayName ?? '';
    final name =
        displayName.isEmpty || displayName.toUpperCase() == mac.toUpperCase()
            ? null
            : displayName;
    final isPrivate = device?.isPrivateMac ?? false;
    return LayoutBlock(
      child: Row(
        children: [
          if (isPrivate) ...[
            AppBadge(
              label: loc(context).privateMacLabel,
              color: colorScheme.error,
              textColor: colorScheme.onError,
            ),
            AppGap.sm(),
          ],
          AppIcon.font(Icons.devices, size: 20),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (name != null) ...[
                  AppText.bodyMedium(name),
                  AppText.bodySmall(mac),
                ] else
                  AppText.bodyMedium(mac),
              ],
            ),
          ),
          AppIconButton(
            identifier: 'instant-privacy-remove-$mac',
            icon: AppIcon.font(Icons.close, size: 20),
            semanticLabel: loc(context).macFilterRemoveDevice,
            onTap: () =>
                ref.read(uspInstantPrivacyProvider.notifier).removeMac(mac),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivateMacWarningBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.font(Icons.warning_amber_rounded,
              size: 20, color: colorScheme.onErrorContainer),
          AppGap.sm(),
          Expanded(
            child: AppText.bodySmall(loc(context).privateMacWarningDesc,
                color: colorScheme.onErrorContainer),
          ),
        ],
      ),
    );
  }

  /// Says the other filter is on. They share one device mode, so saving this page
  /// on turns the other one off — which the Save confirm asks about, and this
  /// states up front. Same treatment as the private-MAC banner on Instant Privacy.
  Widget _buildOtherFilterOnBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.font(Icons.info_outline,
              size: 20, color: colorScheme.onErrorContainer),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).instantPrivacyMacFilterIsOn,
                    color: colorScheme.onErrorContainer),
                AppGap.xs(),
                AppText.bodySmall(loc(context).instantPrivacyMacFilterIsOnDesc,
                    color: colorScheme.onErrorContainer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions (local — nothing writes until Save)
  // ---------------------------------------------------------------------------

  /// A local edit only — the device changes on Save, which is where overriding
  /// MAC Filtering is confirmed.
  void _onToggle(WidgetRef ref, bool enable) {
    ref.read(uspInstantPrivacyProvider.notifier).setEnabled(enable);
  }

  void _showAddDialog(
      BuildContext context, WidgetRef ref, UspInstantPrivacyState state) {
    showMacFilterAddDeviceDialog(
      context: context,
      existingMacs: state.allowedMacs,
      connectedDevices: state.connectedDevices,
      onAdd: (mac) => ref.read(uspInstantPrivacyProvider.notifier).addMac(mac),
    );
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    // The device only changes here, so this is where overriding the other filter
    // is confirmed: saving this page on while the other one is on turns it off.
    final state = ref.read(uspInstantPrivacyProvider);
    if (state.isEnabled && state.isOtherFilterOn) {
      final ok = await showAppDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
          titleText: loc(context).instantPrivacy,
          content: AppText.bodyMedium(
              loc(context).instantPrivacyEnableTurnsOffMacFilter),
          actions: [
            AppButton.text(
              label: loc(context).cancel,
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            AppButton.primary(
              identifier: 'instant-privacy-override-confirm',
              label: loc(context).ok,
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );
      if (ok != true || !context.mounted) return;
    }
    try {
      await doSomethingWithSpinner(
        context,
        ref.read(uspInstantPrivacyProvider.notifier).save(),
      );
      if (context.mounted) {
        showSuccessSnackBar(context, loc(context).changesSaved);
      }
    } catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }
}
