import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/views/dialogs/firmware_update_recovery_dialog.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Full-screen firmware update flow.
///
/// PR-1 ships a skeleton: phase-driven body switcher and a load-banks call so
/// the page renders meaningful copy from real router data. File-picker,
/// chunked push, install polling, and reboot detection land in PR-2 → PR-4.
class FirmwareUpdateView extends ConsumerStatefulWidget {
  const FirmwareUpdateView({super.key});

  @override
  ConsumerState<FirmwareUpdateView> createState() => _FirmwareUpdateViewState();
}

class _FirmwareUpdateViewState extends ConsumerState<FirmwareUpdateView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firmwareUpdateNotifierProvider.notifier).loadBanks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(firmwareUpdateNotifierProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Firmware Update',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdmin,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildBody(childContext, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FirmwareUpdateState state) {
    switch (state.phase) {
      case FirmwareUpdatePhase.idle:
        return _buildIdle(context, state);
      case FirmwareUpdatePhase.picking:
      case FirmwareUpdatePhase.validating:
        return _buildPickingOrValidating(context, state);
      case FirmwareUpdatePhase.uploading:
        return _buildUploading(context, state);
      case FirmwareUpdatePhase.triggering:
      case FirmwareUpdatePhase.installing:
        return _buildInstalling(context);
      case FirmwareUpdatePhase.rebooting:
        return _buildRebooting(context, state);
      case FirmwareUpdatePhase.verifying:
        return _buildVerifying(context);
      case FirmwareUpdatePhase.done:
        return _buildDone(context, state);
      case FirmwareUpdatePhase.failed:
        return _buildFailed(context, state);
    }
  }

  Widget _buildIdle(BuildContext context, FirmwareUpdateState state) {
    final asyncSystemInfo = ref.watch(systemInfoDataProvider);
    final systemInfo = asyncSystemInfo.valueOrNull?.model;
    final banks = systemInfo?.firmwareImages ?? const [];
    final isLoadingBanks = asyncSystemInfo.isLoading && banks.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRouterInfo(context, systemInfo),
        AppGap.xl(),
        _buildBanksSection(context, banks, isLoadingBanks),
        AppGap.xl(),
        _buildSelectedImageCard(context, state),
        AppGap.xl(),
        _buildWarningNote(context),
      ],
    );
  }

  Widget _buildRouterInfo(BuildContext context, SystemInfoUIModel? systemInfo) {
    final scheme = Theme.of(context).colorScheme;
    if (systemInfo == null) {
      return const SizedBox.shrink();
    }
    final iconName = routerIconTestByModel(
      modelNumber: systemInfo.modelName,
      hardwareVersion: systemInfo.hardwareVersion,
    );
    return Row(
      children: [
        Image(
          image: DeviceImageHelper.getRouterImage(iconName, xl: false),
          width: 48,
          height: 48,
        ),
        AppGap.md(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleSmall(systemInfo.modelName),
              AppGap.xs(),
              AppText.bodySmall(
                systemInfo.serialNumber,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBanksSection(
    BuildContext context,
    List<FirmwareImageUIModel> banks,
    bool isLoadingBanks,
  ) {
    if (isLoadingBanks) {
      return Row(
        children: [
          const SizedBox(width: 16, height: 16, child: AppLoader()),
          AppGap.md(),
          AppText.bodyMedium('Loading firmware banks…'),
        ],
      );
    }
    return _BanksDetail(banks: banks);
  }

  Widget _buildWarningNote(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 18, color: scheme.outline),
        AppGap.sm(),
        Expanded(
          child: AppText.bodySmall(
            'The update will take approximately 5–8 minutes. '
            'Do not power off or disconnect the router during the process.',
            color: scheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImageCard(
      BuildContext context, FirmwareUpdateState state) {
    final hasPickedFile = state.selectedFileName != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium('Selected image'),
          AppGap.md(),
          if (hasPickedFile)
            _buildSelectedFileDetails(context, state)
          else
            AppText.bodyMedium(
                'No firmware image selected. Choose a .img or .bin file to begin.'),
          AppGap.xl(),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton.primaryOutline(
                label: hasPickedFile
                    ? 'Choose another file'
                    : 'Choose firmware file',
                onTap: () => _onPickFile(context),
              ),
              if (hasPickedFile)
                AppButton(
                  label: 'Update Firmware',
                  onTap: () => _onConfirmInstall(context, state),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFileDetails(
      BuildContext context, FirmwareUpdateState state) {
    final size = state.selectedFileSize ?? 0;
    final mib = (size / (1024 * 1024)).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.bodyMedium(state.selectedFileName ?? '—'),
        AppGap.sm(),
        AppText.bodySmall('Size: $size bytes ($mib MiB)'),
        if (state.selectedFileMd5 != null) ...[
          AppGap.sm(),
          AppText.bodySmall('MD5: ${state.selectedFileMd5}'),
        ],
      ],
    );
  }

  Widget _buildPickingOrValidating(
      BuildContext context, FirmwareUpdateState state) {
    final title = state.phase == FirmwareUpdatePhase.picking
        ? 'Selecting file'
        : 'Validating image';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(title),
          AppGap.md(),
          if (state.selectedFileName != null)
            AppText.bodyMedium(state.selectedFileName!),
          AppGap.xl(),
          const AppLoader(variant: LoaderVariant.linear),
        ],
      ),
    );
  }

  Widget _buildUploading(BuildContext context, FirmwareUpdateState state) {
    final progress = state.uploadProgress;
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Uploading firmware'),
        AppGap.md(),
        AppText.bodyMedium('$percent%'),
        AppGap.xl(),
        LinearProgressIndicator(value: progress),
        AppGap.xl(),
        AppButton.primaryOutline(
          label: 'Cancel',
          onTap: () =>
              ref.read(firmwareUpdateNotifierProvider.notifier).cancel(),
        ),
      ],
    );
  }

  Widget _buildInstalling(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Installing firmware'),
        AppGap.md(),
        AppText.bodyMedium(
            'The router is writing the new image. Do not power off.'),
        AppGap.xl(),
        const AppLoader(),
      ],
    );
  }

  Widget _buildRebooting(BuildContext context, FirmwareUpdateState state) {
    // Recovery dialog is showing on top with its own loader; keep page content
    // minimal to avoid visual clutter (two spinners).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Rebooting router'),
        AppGap.md(),
        AppText.bodyMedium('Waiting for the router to come back online.'),
      ],
    );
  }

  Widget _buildVerifying(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Verifying firmware'),
        AppGap.md(),
        const AppLoader(),
      ],
    );
  }

  Widget _buildDone(BuildContext context, FirmwareUpdateState state) {
    final newVersion = state.activeBank?.version ?? '—';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Firmware update complete'),
        AppGap.md(),
        AppText.bodyMedium('Now running $newVersion.'),
      ],
    );
  }

  Widget _buildFailed(BuildContext context, FirmwareUpdateState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleMedium('Firmware update failed'),
        AppGap.md(),
        AppText.bodyMedium(state.errorMessage ?? 'Unknown error'),
        AppGap.xxl(),
        AppButton(
          label: 'Retry',
          onTap: () =>
              ref.read(firmwareUpdateNotifierProvider.notifier).cancel(),
        ),
      ],
    );
  }

  Future<void> _onPickFile(BuildContext context) async {
    final notifier = ref.read(firmwareUpdateNotifierProvider.notifier);
    final ok = await notifier.pickAndValidateFile();
    if (!context.mounted) return;
    if (!ok) {
      final err = ref.read(firmwareUpdateNotifierProvider).errorMessage;
      if (err != null && err.isNotEmpty) {
        showFailedSnackBar(context, err);
      }
    }
  }

  Future<void> _onConfirmInstall(
      BuildContext context, FirmwareUpdateState state) async {
    final target = state.targetBank;
    if (target == null) {
      showFailedSnackBar(context, 'No target bank available');
      return;
    }
    final confirmed = await showConfirmActionDialog(
      context,
      title: 'Update Firmware',
      message:
          'The router will install the new firmware and reboot. Do not power off during the update.',
      confirmLabel: 'Update',
    );
    if (confirmed != true || !context.mounted) return;
    final notifier = ref.read(firmwareUpdateNotifierProvider.notifier);
    // CommandKey must be numeric — router rejects non-digit keys with
    // USP_ERR_INVALID_COMMAND_ARGS during chunkedPush argument validation.
    final commandKey = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await notifier.runUpload(commandKey: commandKey);
    } on FirmwareUploadCancelledException {
      return;
    } catch (_) {
      return;
    }
    if (!context.mounted) return;
    try {
      await notifier.triggerInstall(targetInstance: target.instance);
    } catch (_) {
      return;
    }
    if (!context.mounted) return;

    // Let user see the "Installing firmware" screen before transitioning to
    // reboot. The actual flash write is happening in the background on the
    // router; we have no status feedback (B2 blocker), so a fixed delay is
    // the best we can do.
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!context.mounted) return;

    // Hand off to the shared recovery framework. The dialog blocks until the
    // probe loop reports `recovered` (auto-dismiss), the user opts out, or the
    // notifier flips to logged-out via serial mismatch.
    final expectedVersion = target.version;
    notifier.enterRecoveryWaiting();
    await showFirmwareUpdateRecoveryDialog(context, ref);
    if (!context.mounted) return;

    final connState = ref.read(appConnectionStateProvider);
    if (connState != AppConnectionState.authenticated) {
      // User bailed (loggedOut) — recovery framework / router_provider drives
      // the redirect; nothing for us to do here.
      return;
    }

    try {
      await notifier.verify(
        expectedVersion: expectedVersion,
        expectedActiveInstance: target.instance,
      );
    } catch (_) {
      // Notifier already transitioned to `failed` and surfaced the message.
    }
  }
}

class _BanksDetail extends StatelessWidget {
  const _BanksDetail({required this.banks});

  final List<FirmwareImageUIModel> banks;

  @override
  Widget build(BuildContext context) {
    if (banks.isEmpty) {
      return AppText.bodyMedium('No firmware banks reported by router');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < banks.length; i++) ...[
          _BankSlotTile(bank: banks[i]),
          if (i < banks.length - 1) AppGap.md(),
        ],
      ],
    );
  }
}

/// Hard-drive style "slot" visual: large number badge + status indicators on
/// a bordered tile. Active bank highlights with primary border + tinted fill;
/// available slots fall back to a muted neutral border.
class _BankSlotTile extends StatelessWidget {
  const _BankSlotTile({required this.bank});

  final FirmwareImageUIModel bank;

  int? get _slotNumber {
    final path = bank.instancePath;
    final trimmed =
        path.endsWith('.') ? path.substring(0, path.length - 1) : path;
    final lastDot = trimmed.lastIndexOf('.');
    final tail = lastDot < 0 ? trimmed : trimmed.substring(lastDot + 1);
    return int.tryParse(tail);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = bank.isActive;
    final borderColor =
        isActive ? scheme.primary : scheme.outline.withValues(alpha: 0.4);
    final tileBg = isActive
        ? scheme.primaryContainer.withValues(alpha: 0.25)
        : Colors.transparent;
    final version = bank.version.isEmpty ? '(empty slot)' : bank.version;
    final slot = _slotNumber;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SlotNumberBadge(number: slot, isActive: isActive),
          AppGap.lg(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusChip(
                      icon: isActive ? Icons.circle : Icons.circle_outlined,
                      iconColor: isActive ? scheme.primary : scheme.outline,
                      label: isActive ? 'Active' : 'Available',
                    ),
                    if (bank.isBootTarget) ...[
                      AppGap.sm(),
                      _StatusChip(
                        icon: Icons.bolt,
                        iconColor: scheme.tertiary,
                        label: 'Boot',
                      ),
                    ],
                  ],
                ),
                AppGap.sm(),
                AppText.bodyMedium(
                  version,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotNumberBadge extends StatelessWidget {
  const _SlotNumberBadge({required this.number, required this.isActive});

  final int? number;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isActive ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = isActive ? scheme.onPrimary : scheme.onSurface;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: AppText.titleLarge(
        number?.toString() ?? '?',
        color: fg,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 4),
        AppText.labelSmall(label),
      ],
    );
  }
}
