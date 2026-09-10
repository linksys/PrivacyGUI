import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Instant Privacy page — one-tap MAC whitelist to lock the network to
/// currently connected devices only.
class InstantPrivacyView extends ConsumerWidget {
  const InstantPrivacyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(uspInstantPrivacyProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).instantPrivacy,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () => ref.refresh(uspInstantPrivacyProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => ServiceErrorView(
            error: error is ServiceError ? error : null,
            title: loc(context).failedToLoadSettings,
            onRetry: () => ref.invalidate(uspInstantPrivacyProvider),
          ),
          data: (state) => _buildContent(context, ref, state),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    UspInstantPrivacyState state,
  ) {
    final hasPrivateMacInList = state.isEnabled
        ? state.allowedDevices.any((d) => d.isPrivateMac)
        : state.connectedDevices.any((d) => d.isPrivateMac);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          loc(context).instantPrivacyPageDesc,
        ),
        if (hasPrivateMacInList) ...[
          AppGap.md(),
          _buildPrivateMacWarningBanner(context),
        ],
        AppGap.lg(),
        _buildToggleCard(context, ref, state),
        AppGap.md(),
        if (state.isEnabled)
          _buildAllowedDevicesList(context, ref, state)
        else
          _buildConnectedDevicesList(context, state),
      ],
    );
  }

  Widget _buildToggleCard(
    BuildContext context,
    WidgetRef ref,
    UspInstantPrivacyState state,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: LayoutBlock(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(loc(context).instantPrivacy),
                  AppGap.xs(),
                  AppText.bodySmall(
                    state.isEnabled
                        ? loc(context).onlyAllowedDevicesCanConnect
                        : loc(context).allDevicesCanConnectFreely,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
            // While a write is in flight the switch becomes a loader. Its only
            // busy signal used to be the dimmed track `AppSwitch` renders for a
            // null `onChanged`, which reads as "unavailable", not "saving" — and
            // the enable/disable path holds that state for as long as a USP
            // mutation takes.
            //
            // A `Stack` over a size-maintaining switch rather than a plain
            // ternary: `AppSwitch` derives its footprint from the theme's
            // `spacingFactor`, so swapping it out for a fixed-size box would
            // reflow the row on any theme that does not scale at 1.0.
            //
            // `isToggleLocked`, not `isToggleDisabled` — the latter also covers
            // "no connected devices, so it cannot be enabled", which is a
            // permanently unavailable switch rather than work in progress.
            Stack(
              alignment: Alignment.center,
              children: [
                Visibility(
                  visible: !state.isToggleLocked,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: AppSwitch(
                    identifier: 'instant-privacy-enable',
                    value: state.isEnabled,
                    onChanged: state.isToggleDisabled
                        ? null
                        : (value) => value
                            ? _onEnable(context, ref)
                            : _onDisable(context, ref),
                  ),
                ),
                if (state.isToggleLocked)
                  // Thumb-sized and with foreground effects off, the way
                  // `AppButton` renders its own in-place loader. Bounded so a
                  // theme whose `LoaderStyle.size` exceeds the track cannot
                  // grow the `Stack` past what the switch reserved.
                  SizedBox.square(
                    dimension: 24,
                    child: AppLoader(
                      variant: LoaderVariant.circular,
                      foregroundEffectEnabled: false,
                      semanticLabel: loc(context).processing,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OFF state — show connected devices (snapshot preview)
  // ---------------------------------------------------------------------------

  Widget _buildConnectedDevicesList(
    BuildContext context,
    UspInstantPrivacyState state,
  ) {
    if (state.connectedDevices.isEmpty) {
      return _buildEmptyDevicesMessage(context);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelLarge(
            loc(context).devicesWillBeAllowed(state.connectedDevices.length)),
        AppGap.sm(),
        AppText.bodySmall(
          loc(context).devicesWillBeAllowedDesc,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.md(),
        for (final device in state.connectedDevices) ...[
          _buildDeviceLayoutBlock(context, device),
          AppGap.sm(),
        ],
      ],
    );
  }

  Widget _buildEmptyDevicesMessage(BuildContext context) {
    return DetailEmptyBlock(
      message: loc(context).noDevicesCurrentlyConnected,
      subtitle: loc(context).instantPrivacyCannotBeEnabled,
    );
  }

  // ---------------------------------------------------------------------------
  // ON state — show allowed devices + add MAC button
  // ---------------------------------------------------------------------------

  Widget _buildAllowedDevicesList(
    BuildContext context,
    WidgetRef ref,
    UspInstantPrivacyState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A `Wrap`, not a `Row`, and for the reason `usp_apps_view.dart:90`
        // records at the same shape: `spaceBetween` with two inflexible children
        // let the `addDevice` button take the width it asked for and left the
        // count label the remainder — over by up to +110px at 320px in 14 of the
        // 26 locales (#1380). Expanding the label only moves the damage: the
        // button is ~194px of a 288px content row, so `fr` then took 4 lines in
        // 76.7px and `ru` broke a 95.8px word inside 94.1px. The button drops
        // below the count when the two do not fit and nothing shrinks.
        // `WrapAlignment.spaceBetween` plus the tight `SizedBox` keep the wide
        // widths pixel-identical to what the `Row` gave them — a `Wrap` sizes to
        // its widest run, not to its constraint. Both directions are guarded in
        // test/page/_shared/page_surface_overflow_test.dart.
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            children: [
              AppText.labelLarge(loc(context)
                  .allowedDevicesCount(state.allowedDevices.length)),
              AppButton.text(
                label: loc(context).addDevice,
                onTap: state.isToggleLocked
                    ? null
                    : () => _showAddMacDialog(context, ref, state),
              ),
            ],
          ),
        ),
        AppGap.sm(),
        if (state.allowedDevices.isEmpty)
          AppText.bodySmall(
            loc(context).noDevicesInAllowedList,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )
        else
          for (final device in state.allowedDevices) ...[
            _buildDeviceLayoutBlock(context, device),
            AppGap.sm(),
          ],
      ],
    );
  }

  Widget _buildDeviceLayoutBlock(
      BuildContext context, InstantPrivacyDeviceUIModel device) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBlock(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          if (device.isPrivateMac) ...[
            AppBadge(
              label: loc(context).privateMacLabel,
              color: colorScheme.error,
              textColor: colorScheme.onError,
            ),
            AppGap.sm(),
          ],
          AppIcon.font(
            Icons.devices,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(device.displayName),
                AppText.bodySmall(
                  device.mac,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private (randomized) MAC warning
  // ---------------------------------------------------------------------------

  /// Banner shown on page when any device uses a private MAC.
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
          AppIcon.font(
            Icons.warning_amber_rounded,
            size: 20,
            color: colorScheme.onErrorContainer,
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.bodySmall(
              loc(context).privateMacWarningDesc,
              color: colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// Inline warning shown in enable dialog (title only).
  Widget _buildPrivateMacDialogWarning(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Row(
        children: [
          AppIcon.font(
            Icons.warning_amber_rounded,
            size: 20,
            color: colorScheme.error,
          ),
          AppGap.sm(),
          Expanded(
            child: AppText.labelMedium(
              loc(context).privateMacWarningTitle,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Confirmation dialogs
  // ---------------------------------------------------------------------------

  Future<void> _onEnable(BuildContext context, WidgetRef ref) async {
    final connected =
        ref.read(uspInstantPrivacyProvider).valueOrNull?.connectedDevices ??
            const [];
    final privateMacDevices = connected.where((d) => d.isPrivateMac).toList();
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleText: loc(context).enableInstantPrivacyTitle,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(
              loc(context).enableInstantPrivacyDesc(connected.length),
            ),
            if (privateMacDevices.isNotEmpty)
              _buildPrivateMacDialogWarning(context),
          ],
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          AppButton.primary(
            identifier: 'instant-privacy-enable-confirm',
            label: loc(context).enable,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(uspInstantPrivacyProvider.notifier).enable();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeServiceError(context, e))),
        );
      }
    }
  }

  Future<void> _onDisable(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleText: loc(context).disableInstantPrivacyTitle,
        content: AppText.bodyMedium(
          loc(context).disableInstantPrivacyDesc,
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          AppButton.primary(
            label: loc(context).disable,
            onTap: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(uspInstantPrivacyProvider.notifier).disable();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeServiceError(context, e))),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Add MAC dialog
  // ---------------------------------------------------------------------------

  Future<void> _showAddMacDialog(
    BuildContext context,
    WidgetRef ref,
    UspInstantPrivacyState state,
  ) async {
    // Build autocomplete options from connected devices
    final deviceOptions = state.connectedDevices
        .map((d) => AppAutoCompleteOption(
              label: d.displayName,
              value: d.mac,
            ))
        .toList();

    await showAppDialog<void>(
      context: context,
      // Tapping the scrim used to discard whatever had been typed. The field
      // only reveals its validation error on unfocus, so the tap that was
      // meant to trigger validation was closing the dialog instead (#1059).
      barrierDismissible: false,
      builder: (ctx) => _AddMacDialog(
        existingDevices: state.allowedDevices,
        deviceOptions: deviceOptions,
        onConfirm: (mac) async {
          Navigator.of(ctx).pop();
          try {
            await ref.read(uspInstantPrivacyProvider.notifier).addMac(mac);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizeServiceError(context, e))),
              );
            }
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AddMacDialog — stateful dialog for MAC address input with validation
// ---------------------------------------------------------------------------

class _AddMacDialog extends StatefulWidget {
  final List<InstantPrivacyDeviceUIModel> existingDevices;
  final List<AppAutoCompleteOption> deviceOptions;
  final Future<void> Function(String mac) onConfirm;

  const _AddMacDialog({
    required this.existingDevices,
    required this.onConfirm,
    this.deviceOptions = const [],
  });

  @override
  State<_AddMacDialog> createState() => _AddMacDialogState();
}

class _AddMacDialogState extends State<_AddMacDialog> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorText;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _validate();
    }
  }

  void _validate() {
    setState(() {
      final value = _controller.text;
      if (value.isEmpty) {
        _errorText = null;
        return;
      }
      if (!UspInstantPrivacyService.validateMac(value)) {
        _errorText = 'invalidMacFormat';
        return;
      }
      final normalized = UspInstantPrivacyService.normalizeMac(value);
      final isDuplicate =
          widget.existingDevices.any((d) => d.mac == normalized);
      _errorText = isDuplicate ? 'deviceAlreadyInAllowedList' : null;
    });
  }

  /// Whether the current text is a MAC that is not already on the list.
  ///
  /// Deliberately independent of [_errorText]: that field only exists to render
  /// the message, and it is populated on unfocus. Gating the button on it as
  /// well left a valid MAC un-submittable until the user tabbed away.
  bool get _canConfirm {
    final value = _controller.text;
    if (!UspInstantPrivacyService.validateMac(value)) return false;
    final normalized = UspInstantPrivacyService.normalizeMac(value);
    return !widget.existingDevices.any((d) => d.mac == normalized);
  }

  Future<void> _confirm() async {
    if (!_canConfirm) return;
    setState(() => _isConfirming = true);
    await widget
        .onConfirm(UspInstantPrivacyService.normalizeMac(_controller.text));
  }

  String? _localizeError(String? key) {
    if (key == null) return null;
    return switch (key) {
      'invalidMacFormat' => loc(context).invalidMacAddressFormat,
      'deviceAlreadyInAllowedList' => loc(context).deviceAlreadyInAllowedList,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      titleText: loc(context).addDeviceManually,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium(loc(context).enterMacAddressToAllow),
          AppGap.md(),
          AppSelectAutoComplete(
            options: widget.deviceOptions,
            controller: _controller,
            onSelected: (_) => _validate(),
            child: AppTextField(
              identifier: 'instant-privacy-add-mac-input',
              controller: _controller,
              focusNode: _focusNode,
              // Deliberately unrestricted. This field is also the query box of
              // the [AppSelectAutoComplete] above it, which matches a connected
              // device on its name as well as its MAC — so a hex-only input
              // formatter would make the search half of the field unusable.
              // Free text is validated on unfocus instead, and selecting a
              // suggestion writes the MAC into the controller.
              hintText: loc(context).searchByNameMacIp,
              errorText: _localizeError(_errorText),
            ),
          ),
        ],
      ),
      actions: [
        AppButton.text(
          identifier: 'instant-privacy-add-mac-cancel',
          label: loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        // Rebuilt from the controller rather than from setState. The whole
        // reason validation was moved to unfocus is that a setState mid-typing
        // rebuilds the tree and severs the TextField's TextInputConnection on
        // Web (#1059). The field is not inside this builder, so enabling the
        // button as the user types cannot reach it.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, _, __) => AppButton.primary(
            identifier: 'instant-privacy-add-mac-confirm',
            label: _isConfirming ? loc(context).adding : loc(context).add,
            onTap: (_canConfirm && !_isConfirming) ? _confirm : null,
          ),
        ),
      ],
    );
  }
}
