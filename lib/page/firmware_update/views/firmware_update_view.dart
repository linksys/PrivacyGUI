import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart'
    hide FirmwareImageUIModel;
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_info.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_ota_check_service.dart';
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
  /// Delay after triggering local install before showing recovery dialog.
  /// Router typically takes ~60-90 seconds to write firmware before reboot.
  static const _localInstallDelayBeforeReboot = Duration(seconds: 60);

  /// Delay after triggering OTA install before showing recovery dialog.
  /// Router needs to download (~50-100MB) + flash, typically ~120 seconds.
  static const _otaInstallDelayBeforeReboot = Duration(seconds: 120);

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
      title: loc(context).firmwareUpdate,
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
    final asyncSystemInfo = ref.watch(systemInfoDataProvider);
    final systemInfo = asyncSystemInfo.valueOrNull?.model;
    final asyncBanks = ref.watch(firmwareBanksDataProvider);
    final banks = asyncBanks.valueOrNull?.banks ?? const [];
    final isLoadingBanks = asyncBanks.isLoading && banks.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RouterStatusCard(
          systemInfo: systemInfo,
          banks: banks,
          isLoadingBanks: isLoadingBanks,
        ),
        AppGap.xl(),
        _OtaCheckCard(
          state: state,
          onCheck: () => _onCheckForUpdates(context),
        ),
        AppGap.xl(),
        _buildActionCard(context, state),
        AppGap.xl(),
        _buildWarningNote(context),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, FirmwareUpdateState state) {
    switch (state.phase) {
      case FirmwareUpdatePhase.idle:
      case FirmwareUpdatePhase.checkingOta:
        return _buildIdleCard(context, state);
      case FirmwareUpdatePhase.picking:
      case FirmwareUpdatePhase.validating:
        return _buildPickingOrValidatingCard(context, state);
      case FirmwareUpdatePhase.uploading:
        return _buildUploadingCard(context, state);
      case FirmwareUpdatePhase.triggering:
        return _buildTriggeringCard(context);
      case FirmwareUpdatePhase.installing:
        return _buildInstallingCard(context);
      case FirmwareUpdatePhase.rebooting:
        return _buildRebootingCard(context, state);
      case FirmwareUpdatePhase.verifying:
        return _buildVerifyingCard(context);
      case FirmwareUpdatePhase.done:
        return _buildDoneCard(context, state);
      case FirmwareUpdatePhase.failed:
        return _buildFailedCard(context, state);
    }
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
            loc(context).firmwareUpdateWarning,
            color: scheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildIdleCard(BuildContext context, FirmwareUpdateState state) {
    final hasPickedFile = state.selectedFileName != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).firmwareImage),
          AppGap.md(),
          if (hasPickedFile)
            _buildSelectedFileDetails(context, state)
          else
            AppText.bodyMedium(loc(context).noFirmwareImageSelected),
          AppGap.xl(),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton.primaryOutline(
                label: hasPickedFile
                    ? loc(context).chooseAnotherFile
                    : loc(context).chooseFirmwareFile,
                onTap: () => _onPickFile(context),
              ),
              if (hasPickedFile)
                AppButton(
                  label: loc(context).updateFirmware,
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
        AppText.bodySmall(loc(context).sizeBytes(size, mib)),
        if (state.selectedFileMd5 != null) ...[
          AppGap.sm(),
          AppText.bodySmall(loc(context).md5Label(state.selectedFileMd5!)),
        ],
      ],
    );
  }

  Widget _buildPickingOrValidatingCard(
      BuildContext context, FirmwareUpdateState state) {
    final title = state.phase == FirmwareUpdatePhase.picking
        ? loc(context).selectingFile
        : loc(context).validatingImage;
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

  Widget _buildUploadingCard(BuildContext context, FirmwareUpdateState state) {
    final progress = state.uploadProgress;
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).uploadingFirmware),
          AppGap.md(),
          AppText.bodyMedium(loc(context).percentComplete(percent)),
          AppGap.lg(),
          AppLoader(variant: LoaderVariant.linear, value: progress),
          AppGap.xl(),
          AppButton.primaryOutline(
            label: loc(context).cancel,
            onTap: () =>
                ref.read(firmwareUpdateNotifierProvider.notifier).cancel(),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggeringCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).preparingToInstall),
          AppGap.md(),
          AppText.bodyMedium(loc(context).verifyingFirmwareImage),
          AppGap.xl(),
          const AppLoader(variant: LoaderVariant.linear),
        ],
      ),
    );
  }

  Widget _buildInstallingCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).installingFirmware),
          AppGap.md(),
          AppText.bodyMedium(loc(context).routerWritingImage),
          AppGap.xl(),
          const AppLoader(variant: LoaderVariant.linear),
        ],
      ),
    );
  }

  Widget _buildRebootingCard(BuildContext context, FirmwareUpdateState state) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).rebootingRouter),
          AppGap.md(),
          AppText.bodyMedium(loc(context).waitingForRouterOnline),
          AppGap.xl(),
          const AppLoader(variant: LoaderVariant.linear),
        ],
      ),
    );
  }

  Widget _buildVerifyingCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).verifyingFirmware),
          AppGap.md(),
          AppText.bodyMedium(loc(context).confirmingNewFirmware),
          AppGap.xl(),
          const AppLoader(variant: LoaderVariant.linear),
        ],
      ),
    );
  }

  Widget _buildDoneCard(BuildContext context, FirmwareUpdateState state) {
    final scheme = Theme.of(context).colorScheme;
    final newVersion = state.activeBank?.version ?? '—';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: scheme.primary, size: 24),
              AppGap.sm(),
              AppText.titleMedium(loc(context).updateComplete),
            ],
          ),
          AppGap.md(),
          AppText.bodyMedium(loc(context).nowRunningVersion(newVersion)),
        ],
      ),
    );
  }

  Widget _buildFailedCard(BuildContext context, FirmwareUpdateState state) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: scheme.error, size: 24),
              AppGap.sm(),
              AppText.titleMedium(loc(context).updateFailed),
            ],
          ),
          AppGap.md(),
          AppText.bodyMedium(state.errorMessage ?? loc(context).unknownError),
          AppGap.xl(),
          AppButton(
            label: loc(context).tryAgain,
            onTap: () =>
                ref.read(firmwareUpdateNotifierProvider.notifier).cancel(),
          ),
        ],
      ),
    );
  }

  Future<void> _onCheckForUpdates(BuildContext context) async {
    final notifier = ref.read(firmwareUpdateNotifierProvider.notifier);

    try {
      final params = await notifier.buildOtaCheckParams();
      if (params == null) {
        if (context.mounted) {
          showFailedSnackBar(context, loc(context).unableToGatherDeviceInfo);
        }
        return;
      }

      final info = await notifier.checkForOtaUpdate(params);

      if (!context.mounted) return;

      if (info != null) {
        await _showOtaUpdateDialog(context, info);
      }
    } on FirmwareOtaCheckException catch (e) {
      if (context.mounted) {
        showFailedSnackBar(context, e.message);
      }
    }
  }

  Future<void> _showOtaUpdateDialog(
      BuildContext context, FirmwareOtaInfo info) async {
    final state = ref.read(firmwareUpdateNotifierProvider);
    final currentVersion = state.activeBank?.version ?? '—';
    final target = state.targetBank;

    if (target == null) {
      showFailedSnackBar(context, loc(context).noTargetBankAvailable);
      return;
    }

    final confirmed = await showConfirmActionDialog(
      context,
      title: loc(context).updateAvailable,
      message: '${loc(context).currentVersion(currentVersion)}\n'
          '${loc(context).availableVersionLabel(info.version)}\n\n'
          '${loc(context).doYouWantToUpdateNow}',
      confirmLabel: loc(context).update,
    );

    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(firmwareUpdateNotifierProvider.notifier);

    try {
      await notifier.triggerOtaInstall(
        targetInstance: target.instance,
        firmwareUrl: info.downloadUrl,
      );
    } catch (e, st) {
      logger.e('[FirmwareUpdate] triggerOtaInstall error: $e',
          error: e, stackTrace: st);
      if (context.mounted) {
        showFailedSnackBar(context, loc(context).failedToStartOtaUpdate);
      }
      return;
    }

    if (!context.mounted) return;

    // Wait for OTA download + flash before entering recovery
    await Future<void>.delayed(_otaInstallDelayBeforeReboot);
    if (!context.mounted) return;

    // Hand off to the shared recovery framework
    final expectedVersion = info.version;
    notifier.enterRecoveryWaiting();
    await showFirmwareUpdateRecoveryDialog(context, ref);
    if (!context.mounted) return;

    final connState = ref.read(appConnectionStateProvider);
    if (connState != AppConnectionState.authenticated) {
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
      showFailedSnackBar(context, loc(context).noTargetBankAvailable);
      return;
    }
    final confirmed = await showConfirmActionDialog(
      context,
      title: loc(context).updateFirmware,
      message: loc(context).firmwareInstallConfirmMessage,
      confirmLabel: loc(context).update,
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
    } catch (e, st) {
      logger.e('[FirmwareUpdate] runUpload error: $e',
          error: e, stackTrace: st);
      return;
    }
    if (!context.mounted) return;
    try {
      await notifier.triggerInstall(targetInstance: target.instance);
    } catch (e, st) {
      logger.e('[FirmwareUpdate] triggerInstall error: $e',
          error: e, stackTrace: st);
      return;
    }
    if (!context.mounted) return;

    // Let user see the "Installing firmware" screen before transitioning to
    // reboot. The actual flash write is happening in the background on the
    // router; we have no status feedback (B2 blocker), so a fixed delay is
    // the best we can do.
    await Future<void>.delayed(_localInstallDelayBeforeReboot);
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

/// Card for checking OTA firmware updates.
class _OtaCheckCard extends StatelessWidget {
  const _OtaCheckCard({
    required this.state,
    required this.onCheck,
  });

  final FirmwareUpdateState state;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final isChecking = state.phase == FirmwareUpdatePhase.checkingOta;
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).otaUpdate),
          AppGap.md(),
          Row(
            children: [
              if (isChecking)
                AppButton.primaryOutline(
                  label: loc(context).checking,
                  onTap: null,
                  icon: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                AppButton.primaryOutline(
                  label: loc(context).checkForUpdates,
                  onTap: onCheck,
                ),
              if (state.otaUpToDate && !isChecking) ...[
                AppGap.md(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 18,
                      color: scheme.primary,
                    ),
                    AppGap.sm(),
                    AppText.bodyMedium(
                      loc(context).firmwareUpToDate,
                      color: scheme.primary,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Combined router info + firmware banks card.
class _RouterStatusCard extends StatelessWidget {
  const _RouterStatusCard({
    required this.systemInfo,
    required this.banks,
    required this.isLoadingBanks,
  });

  final SystemInfoUIModel? systemInfo;
  final List<FirmwareImageUIModel> banks;
  final bool isLoadingBanks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRouterHeader(context),
          Divider(height: AppSpacing.xl * 2, color: scheme.outlineVariant),
          AppText.labelLarge(loc(context).firmwareBanks),
          AppGap.md(),
          if (isLoadingBanks)
            _buildLoadingBanks(context)
          else if (banks.isEmpty)
            AppText.bodyMedium(loc(context).noFirmwareBanksReported)
          else
            _buildBanksList(context),
        ],
      ),
    );
  }

  Widget _buildRouterHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (systemInfo == null) {
      return const SizedBox.shrink();
    }
    final iconName = routerIconTestByModel(
      modelNumber: systemInfo!.modelName,
      hardwareVersion: systemInfo!.hardwareVersion,
    );
    return Row(
      children: [
        Image(
          image: DeviceImageHelper.getRouterImage(iconName, xl: false),
          width: 56,
          height: 56,
        ),
        AppGap.md(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.titleMedium(systemInfo!.modelName),
              AppGap.xs(),
              AppText.bodySmall(
                systemInfo!.serialNumber,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingBanks(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16, height: 16, child: AppLoader()),
        AppGap.md(),
        AppText.bodyMedium(loc(context).loading),
      ],
    );
  }

  Widget _buildBanksList(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < banks.length; i++) ...[
          _BankRow(bank: banks[i]),
          if (i < banks.length - 1) AppGap.sm(),
        ],
      ],
    );
  }
}

/// Single bank row with left accent bar indicating active status.
class _BankRow extends StatelessWidget {
  const _BankRow({required this.bank});

  final FirmwareImageUIModel bank;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = bank.isActive;
    final accentColor = isActive ? scheme.primary : scheme.outlineVariant;
    final bgColor = isActive
        ? scheme.primaryContainer.withValues(alpha: 0.15)
        : scheme.surfaceContainerLowest;
    final version = bank.version.isEmpty ? '(empty)' : bank.version;
    final slot = bank.instance;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left accent bar
            Container(width: 4, color: accentColor),
            AppGap.md(),
            // Slot badge
            _SlotBadge(number: slot, isActive: isActive),
            AppGap.md(),
            // Version + status
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText.bodyMedium(version),
                    AppGap.xs(),
                    _StatusLabel(isActive: isActive),
                  ],
                ),
              ),
            ),
            AppGap.md(),
          ],
        ),
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  const _SlotBadge({required this.number, required this.isActive});

  final int number;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isActive ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = isActive ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: AppText.labelLarge(
        number.toString(),
        color: fg,
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = isActive ? Icons.check_circle : Icons.circle_outlined;
    final color = isActive ? scheme.primary : scheme.outline;
    final label = isActive ? loc(context).active : loc(context).standby;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        AppText.labelSmall(label, color: color),
      ],
    );
  }
}
