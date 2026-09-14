import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart'
    hide FirmwareImageUIModel;
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_update_warning_note.dart';
import 'package:privacy_gui/page/firmware_update/views/dialogs/firmware_update_recovery_dialog.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Manual firmware update: push an image from this browser to the router.
///
/// #1549 split the OTA check out to [FirmwareOtaView], leaving this page the
/// half that needs a file — pick, validate, chunked push, install, reboot,
/// verify. The install phases from `triggering` onwards are not this page's:
/// both entry points drive the same ones, so they live in
/// [FirmwareInstallPhaseCard].
class FirmwareUpdateView extends ConsumerStatefulWidget {
  const FirmwareUpdateView({super.key});

  @override
  ConsumerState<FirmwareUpdateView> createState() => _FirmwareUpdateViewState();
}

class _FirmwareUpdateViewState extends ConsumerState<FirmwareUpdateView> {
  /// Delay after triggering local install before showing recovery dialog.
  /// Router typically takes ~60-90 seconds to write firmware before reboot.
  static const _localInstallDelayBeforeReboot = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Handled, for the reason the OTA page's copy of this call spells out:
      // `loadBanks` records the failure in state and rethrows as well, and the
      // rethrow lands nowhere from here.
      ref
          .read(firmwareUpdateNotifierProvider.notifier)
          .loadBanks()
          .catchError((Object error) {
        logger.d('[FirmwareUpdate] loadBanks reported $error, '
            'already in notifier state');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(firmwareUpdateNotifierProvider);

    return UiKitPageView.withSliver(
      identifier: 'firmware-update',
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
    // `physicalBanks`: this card draws one boot slot per row, and the virtual
    // OTA instance is not a slot — rendered here it would claim a third bank
    // and print the downloadable version as if the router already held it.
    final banks = asyncBanks.valueOrNull?.physicalBanks ?? const [];
    final isLoadingBanks = asyncBanks.isLoading && banks.isEmpty;

    // Every card on this page exists in every mode. What the mode decides is
    // whether the *manual entry point* is offered, and that decision lives one
    // level down in `_buildActionCardBody` — see `firmwareManualEntry`. Deciding
    // it here instead is what made #1497's first attempt drop the install phase
    // machine along with the affordance that starts it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RouterStatusCard(
          systemInfo: systemInfo,
          banks: banks,
          isLoadingBanks: isLoadingBanks,
        ),
        AppGap.xl(),
        _buildActionCard(context, state),
        AppGap.xl(),
        const FirmwareUpdateWarningNote(),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, FirmwareUpdateState state) {
    // Anchor every phase card by its phase name so the E2E phase-sequence walk
    // (PrivacyGUI-USP-E2E#114) keys on a stable identifier rather than the
    // translatable, live-updating copy inside each card — in particular so the
    // whole-flow verdict `done` vs `failed` is distinguishable structurally.
    // One boundary here covers all phases via `_buildActionCardBody`.
    return Semantics(
      identifier: 'firmware-phase-${state.phase.name}',
      child: _buildActionCardBody(context, state),
    );
  }

  Widget _buildActionCardBody(BuildContext context, FirmwareUpdateState state) {
    switch (state.phase) {
      case FirmwareUpdatePhase.idle:
      case FirmwareUpdatePhase.checkingOta:
        // The only mode-dependent arm, because it is the only one that is an
        // *entry point* rather than the state of an install already running: it
        // holds `firmware-pick-file` and `firmware-install-confirm` and nothing
        // else. A surface without manual update renders nothing here.
        //
        // `checkingOta` is grouped in for shape rather than for reachability:
        // since #1549 the check runs on the OTA page, whose `onExit` refuses to
        // release a user while it does, so this page cannot be on screen in that
        // phase. Kept as `idle` because that is what it would have to look like
        // if it ever were — a picker, with no OTA spinner this page could own.
        return ref.watch(surfaceStrategyProvider).firmwareManualEntry(
              picker: () => _buildIdleCard(context, state),
            );
      case FirmwareUpdatePhase.picking:
      case FirmwareUpdatePhase.validating:
        return _buildPickingOrValidatingCard(context, state);
      case FirmwareUpdatePhase.uploading:
        return _buildUploadingCard(context, state);
      case FirmwareUpdatePhase.triggering:
      case FirmwareUpdatePhase.installing:
      case FirmwareUpdatePhase.rebooting:
      case FirmwareUpdatePhase.verifying:
      case FirmwareUpdatePhase.done:
      case FirmwareUpdatePhase.failed:
        // An install already running looks the same whichever page started it,
        // so from here on this page has nothing of its own to draw.
        return FirmwareInstallPhaseCard(state: state);
    }
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
                identifier: 'firmware-pick-file',
                onTap: () => _onPickFile(context),
              ),
              if (hasPickedFile)
                AppButton(
                  label: loc(context).updateFirmware,
                  identifier: 'firmware-install-confirm',
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
            // The only exit from `isUpdating`, so it is the release side of the
            // firmware `onExit` route guard (PrivacyGUI-USP-E2E#114). As a click
            // target it cannot be driven by localized text under lint:ids
            // Rules 1/2, unlike the read-only fields on this page.
            identifier: 'firmware-upload-cancel',
            onTap: () =>
                ref.read(firmwareUpdateNotifierProvider.notifier).cancel(),
          ),
        ],
      ),
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
    } on UnauthorizedError catch (e) {
      // #1496: the mode refused the operation, and unlike every other failure
      // here that refusal leaves the notifier in `idle` — `OperationGuard.enforce`
      // throws above `_setState`, on purpose, so no upload screen appears for an
      // upload that will not happen. The generic arm below only logs, which for a
      // refusal means the Update button does nothing at all: the failed-phase UI
      // that renders `errorMessage` is never reached because the phase never
      // moved. The admin view's factory-reset arm already surfaces this the same
      // way; this is the firmware half of it.
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
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

    return Semantics(
      // Per-row E2E anchor so "slot N became Active" is expressible instead of
      // the whole banks card flattening to one string (PrivacyGUI-USP-E2E#114).
      // Matches the dynamic-hook convention (`pf-rule-enable-${...}`,
      // `admin-timezone-item-${...}`). The version/status/label inside stay
      // text-asserted: lint:ids exempts assertions once the row is anchorable.
      identifier: 'firmware-bank-${bank.instance}',
      child: Container(
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
