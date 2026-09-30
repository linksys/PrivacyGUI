import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_state.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_add_device_dialog.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The MAC Filter page — a single Deny/Off toggle plus, when on, a blocked-device
/// list editor. Save-based: edits stay local until the bottom Save bar is used.
/// Shares the `X_LINKSYS_SetMACFilter` backend with Instant Privacy (which is
/// the same filter in Allow mode); the two are mutually exclusive.
class MacFilterView extends ConsumerWidget {
  const MacFilterView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(uspMacFilterProvider);
    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).macFilter,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () =>
          ref.read(uspMacFilterProvider.notifier).fetch(forceRemote: true),
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
            onRetry: () => ref.invalidate(uspMacFilterProvider),
          );
        }
        return _buildContent(context, ref, state);
      },
    );
  }

  UiKitBottomBarConfig? _buildBottomBar(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    if (!state.isDirty) return null;
    return UiKitBottomBarConfig(
      positiveLabel: loc(context).save,
      isPositiveEnabled: !state.status.isSaving,
      onPositiveTap: () => _onSave(context, ref),
      onNegativeTap: () => ref.read(uspMacFilterProvider.notifier).revert(),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(loc(context).macFilterPageDesc),
        // Read off the applied mode, so it stays up while this page's switch is
        // being turned on — until Save actually turns Instant Privacy off.
        if (state.isOtherFilterOn) ...[
          AppGap.md(),
          _buildOtherFilterOnBanner(context),
        ],
        AppGap.lg(),
        _buildToggleCard(context, ref, state),
        if (state.isEnabled) ...[
          AppGap.lg(),
          _buildDeviceList(context, ref, state),
        ],
      ],
    );
  }

  Widget _buildToggleCard(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    final isEnabled = state.isEnabled;
    final isSaving = state.status.isSaving;
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
                  AppText.labelLarge(loc(context).macFilter),
                  AppGap.xs(),
                  AppText.bodySmall(isEnabled
                      ? loc(context).macFilterModeDenyDesc
                      : loc(context).macFilterModeDisabledDesc),
                ],
              ),
            ),
            AppSwitch(
              identifier: 'mac-filter-enable',
              value: isEnabled,
              isLoading: isSaving,
              busySemanticLabel: isSaving ? loc(context).processing : null,
              onChanged: isSaving ? null : (v) => _onToggle(ref, v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    final macs = state.blockedMacs;
    final atLimit = macs.length >= UspMacFilterService.maxAddresses;
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wrap, not Row: header label + Add button reflow rather than overflow
          // at narrow widths / long locales (instant_privacy's #1380 treatment).
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.sm,
            children: [
              AppText.labelLarge(loc(context).macFilterListTitle(macs.length)),
              AppButton.text(
                identifier: 'mac-filter-add-device',
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
            AppText.bodySmall(loc(context).macFilterListEmpty)
          else
            ...macs.map((mac) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _buildDeviceRow(context, ref, state, mac),
                )),
        ],
      ),
    );
  }

  Widget _buildDeviceRow(
      BuildContext context, WidgetRef ref, MacFilterState state, String mac) {
    final device = state.connectedDevices
        .where((d) => d.mac.toUpperCase() == mac.toUpperCase())
        .firstOrNull;
    final name = device?.displayName ?? mac;
    return LayoutBlock(
      child: Row(
        children: [
          AppIcon.font(Icons.devices, size: 20),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(name),
                AppText.bodySmall(mac),
              ],
            ),
          ),
          AppIconButton(
            identifier: 'mac-filter-remove-$mac',
            icon: AppIcon.font(Icons.close, size: 20),
            semanticLabel: loc(context).macFilterRemoveDevice,
            onTap: () => ref.read(uspMacFilterProvider.notifier).removeMac(mac),
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
                AppText.labelLarge(loc(context).macFilterInstantPrivacyIsOn,
                    color: colorScheme.onErrorContainer),
                AppGap.xs(),
                AppText.bodySmall(loc(context).macFilterInstantPrivacyIsOnDesc,
                    color: colorScheme.onErrorContainer),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions (local mutations — nothing writes until Save)
  // ---------------------------------------------------------------------------

  /// A local edit only — the device changes on Save, which is where overriding
  /// Instant Privacy is confirmed.
  void _onToggle(WidgetRef ref, bool enable) {
    ref.read(uspMacFilterProvider.notifier).setEnabled(enable);
  }

  void _showAddDialog(
      BuildContext context, WidgetRef ref, MacFilterState state) {
    showMacFilterAddDeviceDialog(
      context: context,
      existingMacs: state.blockedMacs,
      connectedDevices: state.connectedDevices,
      onAdd: (mac) => ref.read(uspMacFilterProvider.notifier).addMac(mac),
    );
  }

  Future<void> _onSave(BuildContext context, WidgetRef ref) async {
    // The device only changes here, so this is where overriding the other filter
    // is confirmed: saving this page on while the other one is on turns it off.
    final state = ref.read(uspMacFilterProvider);
    if (state.isEnabled && state.isOtherFilterOn) {
      final ok = await showAppDialog<bool>(
        context: context,
        builder: (ctx) => AppDialog(
          titleText: loc(context).macFilter,
          content: AppText.bodyMedium(
              loc(context).macFilterEnableTurnsOffInstantPrivacy),
          actions: [
            AppButton.text(
              label: loc(context).cancel,
              onTap: () => Navigator.of(ctx).pop(false),
            ),
            AppButton.primary(
              identifier: 'mac-filter-override-confirm',
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
        ref.read(uspMacFilterProvider.notifier).save(),
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
