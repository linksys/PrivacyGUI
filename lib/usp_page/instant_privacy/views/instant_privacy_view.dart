import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:privacy_gui/usp_page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/usp_page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/usp_page/instant_privacy/services/instant_privacy_service.dart';
import 'package:privacy_gui/usp_page/instant_privacy/views/components/instant_privacy_device_tile.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
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
      title: 'Instant Privacy',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      onBackTap: () => context.canPop()
          ? context.pop()
          : context.goNamed(RouteNamed.uspMenu),
      onRefresh: () => ref.refresh(uspInstantPrivacyProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError(context, ref),
          data: (state) => _buildContent(context, ref, state),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppText.titleMedium('Unable to load Instant Privacy settings'),
          AppGap.md(),
          AppButton.text(
            label: 'Retry',
            onTap: () => ref.invalidate(uspInstantPrivacyProvider),
          ),
        ],
      ),
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
          'Lock your network to only currently connected devices. '
          'Any new device will be blocked until you disable Instant Privacy.',
        ),
        AppGap.xl(),
        _buildToggleCard(context, ref, state),
        AppGap.lg(),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge('Instant Privacy'),
                AppGap.xs(),
                AppText.bodySmall(
                  state.isEnabled
                      ? 'Only allowed devices can connect'
                      : 'All devices can connect freely',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          AppSwitch(
            value: state.isEnabled,
            onChanged: state.isToggleDisabled
                ? null
                : (value) =>
                    value ? _onEnable(context, ref) : _onDisable(context, ref),
          ),
        ],
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
            'Devices that will be allowed (${state.connectedDevices.length})'),
        AppGap.sm(),
        AppText.bodySmall(
          'These devices are currently connected and will form the whitelist when you enable Instant Privacy.',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        AppGap.md(),
        for (final device in state.connectedDevices) ...[
          InstantPrivacyDeviceTile(device: device),
          AppGap.sm(),
        ],
      ],
    );
  }

  Widget _buildEmptyDevicesMessage(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          AppIcon.font(
            Icons.devices_other,
            size: 40,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.md(),
          AppText.bodyMedium(
            'No devices are currently connected.',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          AppGap.xs(),
          AppText.bodySmall(
            'Instant Privacy cannot be enabled until at least one device is connected.',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
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
                'Allowed devices (${state.allowedDevices.length})'),
            AppButton.text(
              label: 'Add device',
              onTap: state.isToggleLocked
                  ? null
                  : () => _showAddMacDialog(context, ref, state),
            ),
          ],
        ),
        AppGap.sm(),
        if (state.allowedDevices.isEmpty)
          AppText.bodySmall(
            'No devices in the allowed list.',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          )
        else
          for (final device in state.allowedDevices) ...[
            InstantPrivacyDeviceTile(device: device),
            AppGap.sm(),
          ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Confirmation dialogs
  // ---------------------------------------------------------------------------

  Future<void> _onEnable(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleText: 'Enable Instant Privacy?',
        content: AppText.bodyMedium(
          'Only the ${ref.read(uspInstantPrivacyProvider).valueOrNull?.connectedDevices.length ?? 0} currently connected device(s) will be allowed to connect. All other devices will be blocked.',
        ),
        actions: [
          AppButton.text(
            label: 'Cancel',
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          AppButton.primary(
            label: 'Enable',
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
          SnackBar(content: Text('Failed to enable Instant Privacy: $e')),
        );
      }
    }
  }

  Future<void> _onDisable(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        titleText: 'Disable Instant Privacy?',
        content: AppText.bodyMedium(
          'All devices will be able to connect freely to your network.',
        ),
        actions: [
          AppButton.text(
            label: 'Cancel',
            onTap: () => Navigator.of(ctx).pop(false),
          ),
          AppButton.primary(
            label: 'Disable',
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
          SnackBar(content: Text('Failed to disable Instant Privacy: $e')),
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
    await showDialog<void>(
      context: context,
      builder: (ctx) => _AddMacDialog(
        existingDevices: state.allowedDevices,
        onConfirm: (mac) async {
          Navigator.of(ctx).pop();
          try {
            await ref.read(uspInstantPrivacyProvider.notifier).addMac(mac);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to add device: $e')),
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
  final Future<void> Function(String mac) onConfirm;

  const _AddMacDialog({
    required this.existingDevices,
    required this.onConfirm,
  });

  @override
  State<_AddMacDialog> createState() => _AddMacDialogState();
}

class _AddMacDialogState extends State<_AddMacDialog> {
  final _controller = TextEditingController();
  String? _errorText;
  bool _isConfirming = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = null;
        return;
      }
      if (!UspInstantPrivacyService.validateMac(value)) {
        _errorText = 'Invalid MAC address format (e.g. AA:BB:CC:DD:EE:FF)';
        return;
      }
      final normalized = UspInstantPrivacyService.normalizeMac(value);
      final isDuplicate =
          widget.existingDevices.any((d) => d.mac == normalized);
      _errorText =
          isDuplicate ? 'This device is already in the allowed list' : null;
    });
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

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      titleText: 'Add device manually',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.bodyMedium('Enter the MAC address of the device to allow.'),
          AppGap.md(),
          AppTextFormField(
            controller: _controller,
            hintText: 'AA:BB:CC:DD:EE:FF',
            onChanged: _onChanged,
            externalErrorText: _errorText,
          ),
        ],
      ),
      actions: [
        AppButton.text(
          label: 'Cancel',
          onTap: () => Navigator.of(context).pop(),
        ),
        AppButton.primary(
          label: _isConfirming ? 'Adding…' : 'Add',
          onTap: (_canConfirm && !_isConfirming) ? _confirm : null,
        ),
      ],
    );
  }
}
