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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(
          loc(context).instantPrivacyPageDesc,
        ),
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
            AppSwitch(
              value: state.isEnabled,
              onChanged: state.isToggleDisabled
                  ? null
                  : (value) => value
                      ? _onEnable(context, ref)
                      : _onDisable(context, ref),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText.labelLarge(
                loc(context).allowedDevicesCount(state.allowedDevices.length)),
            AppButton.text(
              label: loc(context).addDevice,
              onTap: state.isToggleLocked
                  ? null
                  : () => _showAddMacDialog(context, ref, state),
            ),
          ],
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
    return LayoutBlock(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          AppIcon.font(
            Icons.devices,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.sm(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodyMedium(device.displayName),
                AppText.bodySmall(
                  device.mac,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildPrivateMacWarning(
    BuildContext context,
    List<InstantPrivacyDeviceUIModel> devices,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon.font(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: colorScheme.onErrorContainer,
                ),
                AppGap.sm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.labelLarge(
                        loc(context).privateMacWarningTitle,
                        color: colorScheme.onErrorContainer,
                      ),
                      AppGap.xs(),
                      AppText.bodySmall(
                        loc(context).privateMacWarningDesc,
                        color: colorScheme.onErrorContainer,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppGap.sm(),
            for (final device in devices)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: AppText.bodySmall(
                  '• ${device.displayName} (${device.mac})',
                  color: colorScheme.onErrorContainer,
                ),
              ),
          ],
        ),
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
              _buildPrivateMacWarning(context, privateMacDevices),
          ],
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          AppButton.primary(
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

  void _onChanged(String value) {
    // Don't setState here - any state change causes focus loss on Web
    // Validation happens on unfocus via _onFocusChange
  }

  bool get _canConfirm =>
      _controller.text.isNotEmpty &&
      _errorText == null &&
      UspInstantPrivacyService.validateMac(_controller.text);

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
              controller: _controller,
              focusNode: _focusNode,
              hintText: 'AA:BB:CC:DD:EE:FF',
              onChanged: _onChanged,
              errorText: _localizeError(_errorText),
            ),
          ),
        ],
      ),
      actions: [
        AppButton.text(
          label: loc(context).cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: _isConfirming ? loc(context).adding : loc(context).add,
          onTap: (_canConfirm && !_isConfirming) ? _confirm : null,
        ),
      ],
    );
  }
}
