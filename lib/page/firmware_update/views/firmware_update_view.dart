import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/surface_strategy.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart'
    hide FirmwareImageUIModel;
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/firmware_update/localizations/firmware_failure_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_router_status_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_state_unreadable_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _readBanks());
  }

  /// The one read this page opens with, and re-runs when it failed.
  ///
  /// Handled rather than dropped, for the reason the OTA page's copy of this call
  /// spells out: `loadBanks` records the failure in state *and* rethrows, and the
  /// rethrow lands nowhere from a post-frame callback. The state is the channel
  /// this page reads; the log line is so the swallow is not silent.
  ///
  /// `try`/`catch` around an `await` rather than `.catchError`, which is what this
  /// used to be. That worked here only because `loadBanks` returns
  /// `Future<void>` — `Future<T>.catchError` validates its handler's return value
  /// against the runtime `T`, and the OTA page's copy of the same shape threw
  /// `ArgumentError` on the error path once it was handed a future with a real `T`.
  /// Same shape, one accident away from the same defect.
  ///
  /// [refresh] is passed by the read-failure card's retry — see
  /// [FirmwareStateUnreadableCard.onRetry] for why it cannot be left off there.
  Future<void> _readBanks({bool refresh = false}) async {
    try {
      await ref
          .read(firmwareUpdateNotifierProvider.notifier)
          .loadBanks(refresh: refresh);
    } catch (error) {
      logger.d('[FirmwareUpdate] loadBanks reported $error, '
          'already in notifier state');
    }
  }

  /// Everything watched, watched **here**.
  ///
  /// `child:` below is a builder that `UiKitPageView` hands to a layout widget, so
  /// anything it calls may run during layout rather than during build — and a
  /// `ref.watch` reached from there registers a dependency whose change calls
  /// `markNeedsBuild` mid-layout. All three reads used to sit further down, one of
  /// them inside `_buildActionCardBody`; they are parameters now so that the rule
  /// for this page is checkable by looking at one method.
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(firmwareUpdateNotifierProvider);
    final systemInfo = ref.watch(systemInfoDataProvider).valueOrNull?.model;
    final banks = ref.watch(firmwareBanksDataProvider);
    final surface = ref.watch(surfaceStrategyProvider);

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
          child: _buildBody(childContext, state, systemInfo, banks, surface),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    FirmwareUpdateState state,
    SystemInfoUIModel? systemInfo,
    AsyncValue<FirmwareBanksData> asyncBanks,
    SurfaceStrategy surface,
  ) {
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
        FirmwareRouterStatusCard(
          systemInfo: systemInfo,
          banks: banks,
          isLoadingBanks: isLoadingBanks,
          // An `AsyncError` leaves `banks` empty and `isLoading` false, which the
          // card used to read as an answer: "No firmware banks reported" — a claim
          // about the router's boot slots — directly above the card that says the
          // router could not be asked anything. Two cards for one fact, and the
          // upper one was the false and more alarming reading.
          banksUnreadable: asyncBanks.hasError,
        ),
        AppGap.xl(),
        _buildActionCard(context, state, asyncBanks.hasError, surface),
        AppGap.xl(),
        const FirmwareUpdateWarningNote(),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, FirmwareUpdateState state,
      bool banksUnreadable, SurfaceStrategy surface) {
    // Anchor every phase card by its phase name so the E2E phase-sequence walk
    // (PrivacyGUI-USP-E2E#114) keys on a stable identifier rather than the
    // translatable, live-updating copy inside each card — in particular so the
    // whole-flow verdict `done` vs `failed` is distinguishable structurally.
    // One boundary here covers all phases via `_buildActionCardBody`.
    return Semantics(
      identifier: 'firmware-phase-${state.phase.name}',
      child: _buildActionCardBody(context, state, banksUnreadable, surface),
    );
  }

  Widget _buildActionCardBody(BuildContext context, FirmwareUpdateState state,
      bool banksUnreadable, SurfaceStrategy surface) {
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
        //
        // The read-failure card goes **inside** this closure, not above the
        // switch: a surface that does not offer manual update has nothing to say
        // about a read this page only makes in order to offer it. Hoisting the
        // decision out is how #1497's first attempt lost the phase machine.
        return surface.firmwareManualEntry(
          picker: () => banksUnreadable
              // `asyncBanks.hasError`, and no conjunction — unlike the OTA page,
              // which needs one. There two reads record into a single
              // `stateReadError`, so that field alone cannot say *which* failed;
              // here there is one read, and its own `AsyncError` is the answer.
              // If a second read is ever added to this page, this is the line to
              // revisit.
              //
              // Not `state.stateReadError`, which would also be the leftover of a
              // failed `observeRunningOtaInstall` from the OTA page — the same
              // notifier serves both, and a message about a poll this page never
              // ran would replace a picker whose banks are perfectly readable.
              ? FirmwareStateUnreadableCard(
                  onRetry: () => _readBanks(refresh: true),
                )
              : _buildIdleCard(context, state),
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
      // The second of the two places a firmware failure becomes words — the first
      // being `FirmwareInstallPhaseCard`. A cancelled picker is not a failure and
      // leaves the field null, so the null check is what tells the two apart; it is
      // not a guard against blank copy.
      final failure = ref.read(firmwareUpdateNotifierProvider).failure;
      if (failure != null) {
        showFailedSnackBar(context, localizeFirmwareFailure(context, failure));
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
      // that renders `failure` is never reached because the phase never
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

    // The same 60 s the "Installing firmware" screen was always shown for — but spent
    // watching the router instead of ignoring it (#1572). `fwup_error_code` is the
    // only thing a refused image produces (no reboot, no bank change, and measured:
    // not one log line), and the router writes it within seconds. Waiting the delay
    // out blind and then entering a 60 s recovery cooldown meant a refusal took over
    // two minutes to reach the user, who by then had watched a progress bar and a
    // recovery dialog for an update that was already over.
    //
    // The comment this replaces said "we have no status feedback (B2 blocker), so a
    // fixed delay is the best we can do". There is status feedback now.
    if (await notifier.awaitInstallRefusal(
        window: _localInstallDelayBeforeReboot)) {
      // The router named the reason and the notifier has published it. Nothing is
      // rebooting, so the recovery wait below would be a two-minute wait for an
      // event that is not coming.
      return;
    }
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
