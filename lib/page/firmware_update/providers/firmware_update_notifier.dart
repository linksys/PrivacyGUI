import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/operation_guard.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/mode/disruption_class.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_file_picker_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_local_upload_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_router_ota_check_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_router_ota_install_service.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_validation_service.dart';
import 'package:privacy_gui/page/firmware_update/services/usp_firmware_update_service.dart';

final firmwareUpdateNotifierProvider =
    AutoDisposeNotifierProvider<FirmwareUpdateNotifier, FirmwareUpdateState>(
  FirmwareUpdateNotifier.new,
);

/// State-machine notifier driving the manual firmware update flow.
///
/// Phases (PR-1 wires the skeleton; later PRs fill in upload / trigger /
/// reboot detect):
///
/// idle → picking → validating → uploading → triggering → installing
///                                                      ↓
///                                              rebooting → verifying → done
///                                                      ↘ failed
class FirmwareUpdateNotifier extends AutoDisposeNotifier<FirmwareUpdateState> {
  UspFirmwareUpdateService get _svc =>
      ref.read(uspFirmwareUpdateServiceProvider);
  FirmwareFilePickerService get _picker =>
      ref.read(firmwareFilePickerServiceProvider);
  FirmwareValidationService get _validator =>
      ref.read(firmwareValidationServiceProvider);
  FirmwareLocalUploadService get _uploader =>
      ref.read(firmwareLocalUploadServiceProvider);
  FirmwareRouterOtaCheckService get _otaChecker =>
      ref.read(firmwareRouterOtaCheckServiceProvider);
  FirmwareRouterOtaInstallService get _otaInstaller =>
      ref.read(firmwareRouterOtaInstallServiceProvider);

  /// Holds the picked image bytes off-state. Kept off [FirmwareUpdateState]
  /// because a 70 MB Uint8List does not belong in an equatable comparison
  /// and would dominate any state-diff cost.
  Uint8List? _pickedBytes;

  Uint8List? get pickedBytes => _pickedBytes;

  bool _cancelRequested = false;

  /// Whether a reading of an update actually running has been seen on the watch
  /// that is in flight.
  ///
  /// See [_applyInstallOutcome] for what it decides, and
  /// [FirmwareOtaInstallProgress.namesAnUpdatePhase] for why `checking` and
  /// `unknown` do not set it. Reset by whichever watch starts, and by [cancel].
  bool _sawUpdateRunning = false;

  /// Whether an observe watch is already polling.
  ///
  /// One watch at a time, and this is the only entry point that needs saying so.
  /// [observeRunningOtaInstall] is called on page open **and** by the read-failure
  /// card's retry, so a router that is slow to answer gets a second twenty-minute
  /// poll loop per tap — all of them publishing into one `otaProgress`, and each of
  /// them resetting the `_cancelRequested` flag the others terminate on, so a
  /// `cancel()` in between is undone rather than obeyed.
  bool _observing = false;

  /// Whether an install this page dispatched is still being watched.
  ///
  /// The two watches overlap by design — the OTA page opens with `loadBanks` and
  /// `observeRunningOtaInstall` in flight together, and the observe loop keeps
  /// polling for its whole window — so the observe watch can land a verdict about a
  /// router that *this* app has since told to flash. This is how the arm that would
  /// otherwise undo it knows. See [_applyInstallOutcome]'s `idle` case.
  bool _dispatching = false;

  /// Set once, on dispose.
  ///
  /// **Not a crash guard**, despite what this comment used to say. Assigning to a
  /// disposed `Notifier` was measured to be silently tolerated on riverpod 2.6.1 —
  /// both when the whole container goes and when autoDispose collects the provider
  /// under a live one — so the `StateError` the guards were credited with
  /// preventing does not happen. What they prevent is *work*: this notifier's poll
  /// loop can outlive the page by up to twenty minutes, and publishing readings
  /// into a state nobody reads is pointless rather than dangerous. Worth keeping,
  /// and worth not being described as load-bearing safety — the riverpod 3 upgrade
  /// (#1512) is where that distinction gets re-measured.
  bool _disposed = false;

  @override
  FirmwareUpdateState build() {
    ref.onDispose(() {
      _pickedBytes = null;
      // The OTA poll loop's termination condition, from the page's side: it can
      // run for twenty minutes and nothing else would stop it when the page that
      // started it goes away. The upload loop reads the same flag and gains the
      // same property — it could already outlive this notifier, and the first
      // progress callback after disposal is a `StateError`.
      _disposed = true;
      _cancelRequested = true;
    });
    return const FirmwareUpdateState();
  }

  /// Sets state and logs the phase transition.
  void _setState(FirmwareUpdateState newState) {
    final oldPhase = state.phase;
    final newPhase = newState.phase;
    if (oldPhase != newPhase) {
      logger.i('[FirmwareUpdate] phase: $oldPhase → $newPhase');
    }
    state = newState;
  }

  /// Read the router's firmware banks into state.
  ///
  /// A failure here is [FirmwareUpdateState.stateReadError] and **not** `_fail`.
  /// It used to be `_fail`, which both pages render as "Update failed" with a
  /// `firmware-retry` button wired to `cancel()` — so a router that was merely
  /// unreachable reported a failed update on a page where nothing had been
  /// attempted, and offered a retry that reset the flow instead of re-reading.
  /// Rethrown either way: both call sites handle this and rely on the state
  /// carrying the detail.
  ///
  /// [refresh] is what the read-error card's retry passes, and it is not optional
  /// politeness: once the L1 provider is in `AsyncError`, `ref.read(.future)`
  /// rethrows the *cached* error without going near the router, so a retry that
  /// did not ask for a refetch would redraw the same failure forever. The default
  /// stays `false` because the page-open call wants the cache when there is one.
  ///
  /// **`catch`, not `on ServiceError`.** The bridge does not only fail with one:
  /// `UspMutationLock.withLock` throws a bare `TimeoutException` after 30 s by
  /// design, and a codegen parse of an unexpected payload throws a `TypeError`.
  /// Neither reached the old arm, so neither set `stateReadError` — and the page's
  /// card needs both that field and an unreadable banks provider, so the result was
  /// a firmware page with no card, no error and nothing to retry.
  Future<void> loadBanks({bool refresh = false}) async {
    try {
      // Read from L1 provider (Single Source of Truth)
      final banksData = refresh
          ? await ref.read(firmwareBanksDataProvider.notifier).refresh()
          : await ref.read(firmwareBanksDataProvider.future);
      _setState(state.copyWith(
        activeBank: banksData.activeBank,
        targetBank: banksData.availableBank,
        clearStateReadError: true,
      ));
    } catch (e) {
      logger.e('[FirmwareUpdate] loadBanks failed', error: e);
      _setState(state.copyWith(stateReadError: e.toString()));
      rethrow;
    }
  }

  /// Ask the router whether a newer firmware exists.
  ///
  /// The cloud OTA API used to answer this, which meant assembling a MAC, a model
  /// number and a hardware revision from three other providers and asking a server
  /// about a router it could not see. The router knows, so it is asked directly —
  /// see [FirmwareRouterOtaCheckService]. `firmware_ota_check_service.dart` and its
  /// `FirmwareOtaInfo` are still in the tree with no caller anywhere in `lib`:
  /// #1550 says the cloud path is parked, not deleted, and when it goes is a
  /// separate decision. There is no coexistence — nothing selects between them.
  ///
  /// Returns [FirmwareOtaCheckVerdict.notChecked] — never an error — when the
  /// router has no `ota` row. That is REQ-A1: OEM and rebadged builds never ship
  /// the row, so it is a permanent property of the device rather than a fault, and
  /// it is logged at warning, not error. The caller reads
  /// `FirmwareBanksData.otaInstance` for the same fact to decide whether to offer
  /// the button at all; this arm exists for the race where the row disappears
  /// between the two reads.
  ///
  /// Rethrows [ServiceError] so the view can say the check failed. It must not be
  /// swallowed into `noUpdateFound`: "we could not ask" and "we asked and there is
  /// nothing" are the same sentence to a user and only one of them is true.
  Future<FirmwareOtaCheckResult> checkForUpdate() async {
    // Refused while an update is in flight, and the reason is the phase this method
    // sets. `checkingOta` is a phase with no install card, so a check started during
    // a flash took the "do not power off" card off the screen — and `Download()` at
    // a router writing NAND is a second update dispatched at a busy one. The OTA
    // page's own button is dead in these phases; this is the same refusal at the
    // layer that owns the phase, so it holds for any caller.
    if (state.isUpdating) {
      logger.w('[FirmwareUpdate] not checking for firmware — an update is '
          'already in progress (${state.phase})');
      return const FirmwareOtaCheckResult.notChecked();
    }
    final otaInstance =
        (await ref.read(firmwareBanksDataProvider.future)).otaInstance;
    if (otaInstance == null) {
      logger.w('[FirmwareUpdate] no ota instance — this router cannot be asked '
          'for firmware updates');
      return const FirmwareOtaCheckResult.notChecked();
    }

    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.checkingOta,
      otaCheck: const FirmwareOtaCheckResult.notChecked(),
      clearFailure: true,
    ));

    try {
      final result = await _otaChecker.check(otaInstance: otaInstance.instance);
      _setState(state.copyWith(
        phase: FirmwareUpdatePhase.idle,
        otaCheck: result,
      ));
      // The check writes `Available`/`Version` on the router, so the L1 cache the
      // dashboard banner and the mascot read from is now stale. Refreshed after
      // the state is published, and guarded: a failed re-read is a stale banner,
      // not a failed check, and turning it into one would report an error for a
      // check the user just watched succeed.
      try {
        await ref.read(firmwareBanksDataProvider.notifier).refresh();
      } on ServiceError catch (e) {
        logger.w('[FirmwareUpdate] post-check banks refresh failed', error: e);
      }
      return result;
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] OTA check failed', error: e);
      _setState(state.copyWith(phase: FirmwareUpdatePhase.idle));
      rethrow;
    } finally {
      // Belt to the `on ServiceError` braces above, and the only thing standing
      // between an unforeseen throw and a button that spins for the rest of the
      // session. `checkingOta` is what makes `AppButton.isLoading` true, and the
      // ticket's own words are that the checking state is driven by this call's
      // lifecycle — so it must not outlive the call, whatever ends it. A no-op on
      // both paths that get here normally: each has already set `idle`.
      if (state.phase == FirmwareUpdatePhase.checkingOta) {
        logger.w('[FirmwareUpdate] OTA check left the phase set — restoring '
            'idle');
        _setState(state.copyWith(phase: FirmwareUpdatePhase.idle));
      }
    }
  }

  /// Open the OS file picker, then run client-side validation. Updates state
  /// to [FirmwareUpdatePhase.validating] then back to a populated
  /// [FirmwareUpdatePhase.idle] on success (caller drives the next phase via
  /// [triggerInstall]). Returns false if the user cancelled the dialog.
  Future<bool> pickAndValidateFile() async {
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.picking,
      clearFailure: true,
    ));
    final picked = await _picker.pickFirmwareImage();
    if (picked == null) {
      _setState(state.copyWith(phase: FirmwareUpdatePhase.idle));
      return false;
    }
    _setState(state.copyWith(phase: FirmwareUpdatePhase.validating));
    try {
      final result = await _validator.validate(
        filename: picked.name,
        bytes: picked.bytes,
      );
      _pickedBytes = picked.bytes;
      _setState(state.copyWith(
        phase: FirmwareUpdatePhase.idle,
        selectedFileName: result.filename,
        selectedFileSize: result.size,
        selectedFileMd5: result.md5,
        clearFailure: true,
      ));
      return true;
    } on FirmwareValidationFailure catch (e) {
      logger.w('[FirmwareUpdate] validation failed', error: e);
      // Mapped by `kind`, not by `message`. `message` is the log line — it is
      // English, and it is the field that made twenty-five locales read English
      // when it was copied straight into the state.
      _fail(switch (e.kind) {
        FirmwareValidationFailureKind.empty =>
          const FirmwareFailure.fileEmpty(),
        FirmwareValidationFailureKind.tooSmall =>
          FirmwareFailure.fileTooSmall(sizeBytes: picked.bytes.length),
        FirmwareValidationFailureKind.tooLarge =>
          FirmwareFailure.fileTooLarge(sizeBytes: picked.bytes.length),
        FirmwareValidationFailureKind.unsupportedExtension =>
          const FirmwareFailure.fileTypeUnsupported(),
      });
      return false;
    }
  }

  /// Abandon the flow and go back to the landing state.
  ///
  /// This is what `firmware-retry` — the Try Again on the failure card — calls, so
  /// "back to the landing state" has to mean a page that can start again.
  ///
  /// **The banks survive, and everything else does not.** They are not part of the
  /// flow being abandoned: they are a reading of the router, and both install paths
  /// need `targetBank` to dispatch anything (`_onConfirmOtaInstall` refuses without
  /// it, before its dialog). Wiping them dead-ended the retry this method exists to
  /// offer — "No target bank available" on the second tap, with no way to get the
  /// reading back short of leaving the page, because nothing re-reads on `cancel`.
  ///
  /// The check verdict deliberately does *not* survive: it is stale the moment an
  /// install has been attempted, and leaving it up would re-offer the image whose
  /// install just failed.
  void cancel() {
    _cancelRequested = true;
    _pickedBytes = null;
    // Cleared with the state it describes. Left set, the next watch would inherit
    // the previous one's sighting and be entitled to report a failure it never saw
    // running.
    _sawUpdateRunning = false;
    _setState(FirmwareUpdateState(
      activeBank: state.activeBank,
      targetBank: state.targetBank,
    ));
  }

  /// Pushes the previously-picked firmware image to the router via Method 1
  /// chunkedPush. Sets uploading phase, drives the progress fields, and
  /// returns once all chunks are accepted. Does NOT trigger the flash —
  /// caller drives [triggerInstall] next so the confirm dialog can sit
  /// between the two stages.
  ///
  /// `transportLoss` — **manual firmware update is a local-only feature**, and
  /// the class doc is worth reading before touching this: the upload is not
  /// broken under Remote Assistance, it is simply not offered there. Cloud OTA is
  /// the remote answer for the same need, and [triggerOtaInstall] below is
  /// allowed in every mode.
  ///
  /// Refused before the state moves, so the view never shows an upload screen for
  /// an upload that will not happen — and refused by throwing, because
  /// `_onConfirmInstall` would otherwise fall straight through to
  /// [triggerInstall] and then to a recovery dialog waiting for a reboot nobody
  /// asked for.
  ///
  /// This is the seam #1496's own analysis could not have used: one line later,
  /// the OTA path and this one converge on the same `enterRecoveryWaiting()` and
  /// the same recovery dialog, so nothing downstream can tell them apart.
  Future<void> runUpload({required String commandKey}) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transportLoss,
        operation: 'local firmware upload');
    final bytes = _pickedBytes;
    final md5 = state.selectedFileMd5;
    if (bytes == null || md5 == null) {
      _fail(const FirmwareFailure.noImageSelected());
      return;
    }
    _cancelRequested = false;
    final total = _uploader.totalFragmentsFor(bytes.length);
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.uploading,
      uploadedChunks: 0,
      totalChunks: total,
      clearFailure: true,
    ));
    try {
      await _uploader.uploadFile(
        bytes: bytes,
        md5: md5,
        commandKey: commandKey,
        isCancelled: () => _cancelRequested,
        onProgress: (sent, t) {
          state = state.copyWith(
            phase: FirmwareUpdatePhase.uploading,
            uploadedChunks: sent,
            totalChunks: t,
            uploadMethod: _uploader.lastUsedMethod,
          );
        },
      );
      // Capture final upload method in state
      _setState(state.copyWith(uploadMethod: _uploader.lastUsedMethod));
    } on FirmwareUploadCancelledException {
      logger.i('[FirmwareUpdate] upload cancelled by user');
      cancel();
      rethrow;
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] upload failed', error: e);
      _fail(FirmwareFailure.serviceError(e));
      rethrow;
    }
  }

  /// Tells the router to install an image it already holds.
  ///
  /// `transientRestart`, and this is not a loophole in the block above: pushing
  /// the bytes is what needs the router's own host, installing them only restarts
  /// the box. Classifying this by the flow it belongs to rather than by what it
  /// costs is exactly the mistake `DisruptionClass` exists to prevent — and in
  /// Remote Assistance it is unreachable regardless, because
  /// `_onConfirmInstall` returns as soon as [runUpload] throws.
  Future<void> triggerInstall({required int targetInstance}) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transientRestart,
        operation: 'local firmware install');
    _setState(state.copyWith(phase: FirmwareUpdatePhase.triggering));
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.triggerLocalDownload(targetInstance: targetInstance);
      });
      _setState(state.copyWith(phase: FirmwareUpdatePhase.installing));
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] triggerInstall failed', error: e);
      _fail(FirmwareFailure.serviceError(e));
      rethrow;
    }
  }

  /// Tells the router to fetch and install an image from the cloud.
  ///
  /// `transientRestart`, allowed everywhere — and it is the half of the firmware
  /// pair that is easy to get wrong. An OTA is the *more* alarming of the two to
  /// watch: the router downloads, flashes and reboots. It is also the one that
  /// works remotely, because the router does the fetching over its own uplink and
  /// nothing on the agent's path is destroyed. Together with [runUpload] above,
  /// the two lines are the whole argument for naming consequences instead of
  /// operations.
  Future<void> triggerOtaInstall({
    required int targetInstance,
    required String firmwareUrl,
  }) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transientRestart,
        operation: 'cloud OTA firmware install');
    _setState(state.copyWith(phase: FirmwareUpdatePhase.triggering));
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.triggerOtaDownload(
          targetInstance: targetInstance,
          firmwareUrl: firmwareUrl,
        );
      });
      _setState(state.copyWith(phase: FirmwareUpdatePhase.installing));
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] triggerOtaInstall failed', error: e);
      _fail(FirmwareFailure.serviceError(e));
      rethrow;
    }
  }

  /// Tells the router to fetch and install a newer firmware over its own uplink.
  ///
  /// The replacement for [triggerOtaInstall] above, which needs a `firmwareUrl`
  /// only the cloud OTA API could supply. This one asks the router the same way
  /// #1550's check does — `FirmwareImage.{ota}.Download()` with no URL — with
  /// `AutoActivate` flipped, which on this firmware selects `fwupd -m 2`: check,
  /// download, flash, reboot. A separate method rather than a relaxed argument,
  /// because the two answer to different servers and only one of them survives.
  ///
  /// Returns the watch's verdict; **`flashing` is not success.** It means the
  /// router is committed and has stopped answering, which is what a reboot looks
  /// like from here. The caller drives the rest — `enterRecoveryWaiting()`, the
  /// recovery dialog, then [verify] — exactly as `_onConfirmInstall` does for the
  /// manual path, because only the view can put a blocking dialog around it.
  ///
  /// `transientRestart`, allowed on every surface. Same argument as
  /// [triggerOtaInstall]: the router does the fetching, so nothing on the agent's
  /// path is destroyed, and this is the half of the firmware pair that works
  /// remotely.
  Future<FirmwareOtaInstallResult> triggerRouterOtaInstall({
    required int otaInstance,
  }) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transientRestart,
        operation: 'router OTA firmware install');
    _cancelRequested = false;
    _sawUpdateRunning = false;
    _dispatching = true;
    _setState(state.copyWith(
      // Not `installing`: mode 2 checks before it downloads, and the router can
      // take a few seconds to start. `triggering` is the phase whose card says
      // "preparing", and the first busy reading moves it on.
      phase: FirmwareUpdatePhase.triggering,
      clearFailure: true,
      clearOtaProgress: true,
    ));
    try {
      final result = await _otaInstaller.install(
        otaInstance: otaInstance,
        // `isRunning`, not `isInstalling`: this dispatch is what started the
        // router's check, so its own `fwup_state=1` is progress on something the
        // user asked for. See [FirmwareOtaInstallProgress.isInstalling].
        onProgress: (progress) =>
            _publishOtaProgress(progress, dispatched: true),
        isCancelled: () => _cancelRequested,
      );
      _applyInstallOutcome(result, dispatched: true);
      return result;
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] router OTA install failed', error: e);
      _fail(FirmwareFailure.serviceError(e));
      rethrow;
    } finally {
      _dispatching = false;
      // The belt [checkForUpdate] has, and the stakes here are higher than a
      // button that spins. `triggering` is `isUpdating`, and `_firmwareExitGuard`
      // in `route_usp_dashboard.dart` returns `!state.isUpdating` — it **silently**
      // vetoes the Navigator pop, so a phase left set by an unforeseen throw traps
      // the user on a page with no card explaining why. `UspMutationLock` throwing
      // its own `TimeoutException` after 30 s is not hypothetical: the dispatch runs
      // under that lock, and a `TimeoutException` is deliberately not a
      // `ServiceError`.
      //
      // A no-op on every path that ends normally — each has set a phase of its own —
      // except `abandoned`, which writes nothing because `cancel()` has already
      // reset the state to `idle`.
      if (!_disposed && state.phase == FirmwareUpdatePhase.triggering) {
        logger.w('[FirmwareUpdate] the OTA install left the phase set — '
            'restoring idle');
        _setState(state.copyWith(phase: FirmwareUpdatePhase.idle));
      }
    }
  }

  /// Watch an update this app did not start (REQ-A6).
  ///
  /// Auto-update can begin a flash on its own, so the OTA page can be opened in
  /// the middle of one and has to show it rather than offering to start a second.
  /// Nothing is dispatched here — see [FirmwareRouterOtaInstallService.observe].
  ///
  /// A read failure lands in [FirmwareUpdateState.stateReadError] rather than
  /// failing a phase, for the same reason as [loadBanks]: nothing was attempted,
  /// so there is no update to report as failed.
  ///
  /// Returns [FirmwareOtaInstallVerdict.abandoned] without polling when a watch is
  /// already running — see [_observing]. `abandoned` because that is already the
  /// verdict meaning "this call is not the one that will answer", and
  /// [_applyInstallOutcome] deliberately writes nothing for it.
  Future<FirmwareOtaInstallResult> observeRunningOtaInstall() async {
    if (_observing) {
      logger.d('[FirmwareUpdate] already watching the router firmware state — '
          'not starting a second poll loop');
      return const FirmwareOtaInstallResult(
          verdict: FirmwareOtaInstallVerdict.abandoned);
    }
    _observing = true;
    _cancelRequested = false;
    _sawUpdateRunning = false;
    try {
      final result = await _otaInstaller.observe(
        // `isInstalling`, not `isRunning`: nothing was dispatched from here, so a
        // reading of `fwup_state=1` is the auto-update daemon's own scheduled check
        // and not an update in progress. See
        // [FirmwareOtaInstallProgress.isInstalling] for what promoting it costs.
        onProgress: (progress) =>
            _publishOtaProgress(progress, dispatched: false),
        isCancelled: () => _cancelRequested,
      );
      _applyInstallOutcome(result, dispatched: false);
      return result;
    } catch (e) {
      // `catch`, not `on ServiceError` — same argument as [loadBanks]: the two
      // reads share one field and one card, and a `TimeoutException` out of the
      // mutation lock leaves the page exactly as unreadable.
      logger.w('[FirmwareUpdate] could not read the router firmware state',
          error: e);
      if (!_disposed) {
        _setState(state.copyWith(stateReadError: e.toString()));
      }
      rethrow;
    } finally {
      _observing = false;
    }
  }

  /// One `fwup_state` reading, published for the progress card to draw.
  ///
  /// The phase moves to `installing` off a reading rather than off a timer: the
  /// card must not claim the router is writing an image while it is still deciding
  /// whether there is one.
  ///
  /// [dispatched] — same word, same meaning as [_applyInstallOutcome]'s: this
  /// reading belongs to an install started from this page. It decides which of the
  /// reading's two predicates promotes the phase, and that follows from the entry
  /// point rather than being a tuning knob —
  /// [FirmwareOtaInstallProgress.isInstalling] carries the argument. Both are false
  /// for `idle` and `failed`, so those always leave the phase where it was and
  /// [_applyInstallOutcome] decides it.
  void _publishOtaProgress(
    FirmwareOtaInstallProgress progress, {
    required bool dispatched,
  }) {
    if (_disposed) return;
    // What was *seen*, recorded separately from what is *drawn*. The two differ on
    // `unknown` — see [FirmwareOtaInstallProgress.namesAnUpdatePhase] — and this is
    // the half [_applyInstallOutcome] is allowed to attribute a failure to.
    // Recorded before the guard below, because it is a sighting either way.
    if (progress.namesAnUpdatePhase) _sawUpdateRunning = true;
    // The two watches run concurrently and write one `otaProgress`, so the loser of
    // that race has to be named. It is the observe one: an install dispatched from
    // here has a percentage and a phase the user is watching, and the observe watch
    // is a second sampler of the same router — one reading behind, and needing only
    // to be idle for a moment to blank the download percentage off the card and
    // leave the generic "updating firmware" copy in its place. The verdict half of
    // this is [_applyInstallOutcome]'s `idle` arm.
    if (!dispatched && _dispatching) return;
    final promote = dispatched ? progress.isRunning : progress.isInstalling;
    _setState(state.copyWith(
      otaProgress: progress,
      phase: promote ? FirmwareUpdatePhase.installing : null,
    ));
  }

  /// What each of the watch's five endings means for the page.
  ///
  /// [dispatched] is the difference between the two entry points, and it decides
  /// two things.
  ///
  /// **Whether an idle router is an *answer*.** On the install path mode 2 ran its
  /// own check and concluded there was nothing to fetch, which is a verdict worth
  /// showing. On the observe path nobody asked the router anything, so publishing
  /// `noUpdateFound` would answer a question that was never put.
  ///
  /// **Whether a failure is *this* update's.** `fwup_state` is a persistent
  /// sysevent scalar, not a per-run field: 5 stays 5 until the next update moves it,
  /// and the anchor that would say *when* — `linksys.fwup.lastsuccess_checktime` —
  /// exists in the sysevent store and is not exposed in the data model (contract
  /// request 6 on #1547). So a 5 read on page open may be weeks old, possibly from
  /// the very update that installed the firmware now running fine, and "Update
  /// failed / Try again" over a page where nothing was attempted is the sentence
  /// that makes someone power-cycle a healthy router.
  ///
  /// [_sawUpdateRunning] is the discriminator for that, and it is sound because of
  /// the ordering: [_publishOtaProgress] runs on every reading *before* this method
  /// sees the verdict, so by the time a verdict lands the flag holds everything the
  /// readings said.
  void _applyInstallOutcome(
    FirmwareOtaInstallResult result, {
    required bool dispatched,
  }) {
    if (_disposed) return;
    switch (result.verdict) {
      case FirmwareOtaInstallVerdict.flashing:
        // Not `rebooting`. That phase belongs to `enterRecoveryWaiting()`, which
        // also parks the SSE channel and starts the probe loop — the view calls it
        // around the dialog, and setting the phase here would show the reboot copy
        // without any of the machinery behind it.
        _setState(state.copyWith(phase: FirmwareUpdatePhase.installing));

      case FirmwareOtaInstallVerdict.idle:
        // Guarded like the two failures below, and for a sharper reason. Both reads
        // this page opens with run concurrently, so an observe loop that was polling
        // a non-idle `fwup_state` can reach `idle` *while a dispatched install is
        // running* — and unguarded this arm would then reset the phase, clear the
        // progress and re-offer "Update Now" on top of a router that is flashing.
        if (!dispatched && _dispatching) {
          // Nothing is written, not even the tidy-up [_discardStaleOutcome] does:
          // the phase and `otaProgress` belong to the dispatched install, and
          // clearing them would drop the download percentage off the card in the
          // middle of the flash.
          logger.i(
              '[FirmwareUpdate] the observe watch read an idle router while '
              'an install dispatched from here is still running — leaving the '
              'install to report itself');
          return;
        }
        _setState(state.copyWith(
          phase: FirmwareUpdatePhase.idle,
          otaCheck:
              dispatched ? const FirmwareOtaCheckResult.noUpdateFound() : null,
          clearOtaProgress: true,
        ));

      case FirmwareOtaInstallVerdict.failed:
        if (!dispatched && !_sawUpdateRunning) {
          _discardStaleOutcome(result, 'a failure', 'nothing was attempted');
          return;
        }
        // The raw state is carried into the sentence on purpose: `5` is the only
        // failure value this firmware publishes and it says nothing about why, so
        // the number is the whole diagnostic a support call has to work from. It
        // rides as a placeholder, so all 26 locales get a translated sentence
        // around the same digit.
        _fail(
            FirmwareFailure.routerReportedFailure(fwupState: result.rawState));

      case FirmwareOtaInstallVerdict.timedOut:
        if (!dispatched && !_sawUpdateRunning) {
          _discardStaleOutcome(
              result, 'a stalled watch', 'nothing was ever seen running');
          return;
        }
        // Never `noUpdateFound`. The router stopped reporting; that is not the
        // same as the router having nothing to report, and substituting one for
        // the other is the failure this work package is arranged to prevent.
        // Two reasons, because "the last state was 3" and "there was never a
        // state" are different sentences. The first version of this passed the
        // literal `unread` into the placeholder, which is an English word in
        // twenty-five translated sentences — a placeholder can only carry a token
        // that reads the same in every language, and `5` is one while a word is not.
        _fail(result.rawState.isEmpty
            ? const FirmwareFailure.progressStalledNoReading()
            : FirmwareFailure.progressStalled(fwupState: result.rawState));

      case FirmwareOtaInstallVerdict.abandoned:
        // Deliberately nothing. The user cancelled or the page went away, and
        // `cancel()` has already replaced the whole state — writing a verdict over
        // it would put a card back on a page that has been left.
        break;
    }
  }

  /// Log an outcome this page is not entitled to report, and undo what watching it
  /// cost.
  ///
  /// The reading is dropped along with the verdict: `otaProgress` is what the
  /// progress card draws, and at `idle` there is no card to draw it on — leaving it
  /// would park a stale `fwup_state` in the state for the next phase change to
  /// render.
  ///
  /// **And the phase goes back**, which is the part that is not tidiness.
  /// [_publishOtaProgress] promotes `installing` off an `unknown` reading on purpose
  /// (REQ-A7), and `installing` is `isUpdating`, which `_firmwareExitGuard` in
  /// `route_usp_dashboard.dart` **silently** vetoes the back arrow on. So a watch
  /// that saw one unrecognised value and then concluded nothing would leave the user
  /// on a page with no card, no error, and a back arrow that does nothing at all.
  /// Only from `installing`: any other phase belongs to something this watch did not
  /// set.
  void _discardStaleOutcome(
      FirmwareOtaInstallResult result, String what, String why) {
    logger.i('[FirmwareUpdate] the router reports $what '
        '(fwup_state=${result.rawState.isEmpty ? 'unread' : result.rawState}) '
        'but $why from here — reporting nothing');
    _setState(state.copyWith(
      clearOtaProgress: true,
      phase: state.phase == FirmwareUpdatePhase.installing
          ? FirmwareUpdatePhase.idle
          : null,
    ));
  }

  /// Hands off recovery to the shared [AppConnectionStateNotifier]:
  /// transitions the connection state to `waitingForRecovery` so the
  /// existing probe loop (health → session restore → fingerprint) runs
  /// and the SSE channel is parked. The view is responsible for showing
  /// the firmware-specific recovery dialog around this call.
  void enterRecoveryWaiting({
    Duration cooldown = const Duration(seconds: 60),
  }) {
    _setState(state.copyWith(phase: FirmwareUpdatePhase.rebooting));
    ref.read(appConnectionStateProvider.notifier).enterWaiting(
          context: RecoveryContext(
            trigger: RecoveryTrigger.operationalFirmwareUpgrade,
            cooldown: cooldown,
          ),
        );
  }

  void enterRebooting(Duration estimated) {
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.rebooting,
      rebootRemaining: estimated,
    ));
  }

  Future<void> verify({
    required String expectedVersion,
    required int expectedActiveInstance,
  }) async {
    _setState(state.copyWith(phase: FirmwareUpdatePhase.verifying));

    try {
      // Post-reboot settle: SSE reconnects and dashboard providers refetch
      logger.d('[FirmwareUpdate] verify: post-reboot settle (3s)...');
      await Future<void>.delayed(const Duration(seconds: 3));

      // Wait for throttler to be idle (SSE reconnect may trigger other requests)
      logger.d('[FirmwareUpdate] verify: waiting for throttler idle...');
      await ref.read(bridgeRequestThrottlerProvider).whenIdle();

      // Fetch banks with retry (also retry if banks empty — TR-181 may not be ready)
      FirmwareBanksData? banksData;
      const maxAttempts = 3;
      for (var attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          logger.d(
              '[FirmwareUpdate] verify: calling notifier.refresh() (attempt $attempt/$maxAttempts)...');
          banksData =
              await ref.read(firmwareBanksDataProvider.notifier).refresh();
          logger.d('[FirmwareUpdate] verify: got '
              '${banksData.physicalBanks.length} banks');
          // Counted over physical banks: a table holding only the virtual OTA
          // row is TR-181 still coming up, and treating it as "banks read"
          // would fail the update with "expected bank not present".
          if (banksData.physicalBanks.isNotEmpty) break;
          // Empty banks — TR-181 not ready yet, retry
          logger.w('[FirmwareUpdate] verify: empty banks, retrying...');
          if (attempt == maxAttempts) {
            _fail(const FirmwareFailure.banksUnreadableAfterReboot());
            return;
          }
          await Future<void>.delayed(const Duration(seconds: 3));
        } catch (e) {
          logger.w(
              '[FirmwareUpdate] verify: refresh failed (attempt $attempt/$maxAttempts)',
              error: e);
          if (attempt == maxAttempts) rethrow;
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }
      // Physical banks only. Every check below is about which slot the router
      // booted from, and the virtual OTA instance is not a slot: it would be
      // counted by the multi-Active consistency check and could be matched as
      // the expected instance if the router renumbers.
      final banks = banksData!.physicalBanks;

      logger.d(
          '[FirmwareUpdate] verify: banks=${banks.map((b) => '${b.instancePath}:${b.status}').join(', ')}'
          ', expectedActiveInstance=$expectedActiveInstance, expectedVersion=$expectedVersion');

      // Verify: check for inconsistent multi-Active state
      final activeBanks = banks.where((b) => b.isActive).toList();
      if (activeBanks.length > 1) {
        _fail(FirmwareFailure.multipleActiveBanks(count: activeBanks.length));
        return;
      }

      // Find the expected bank
      final match =
          banks.where((b) => b.instance == expectedActiveInstance).firstOrNull;
      if (match == null) {
        _fail(FirmwareFailure.expectedBankMissing(
            instance: expectedActiveInstance));
        return;
      }

      // Verify bank flip: expected instance should now be Active
      if (!match.isActive) {
        _fail(FirmwareFailure.bootedOldImage(
            instance: expectedActiveInstance, status: match.status));
        return;
      }

      // Version match check (secondary, optional for manual update)
      // For manual uploads, expectedVersion may be empty (we don't parse the
      // firmware file's embedded version). Bank flip is the primary check.
      if (expectedVersion.isNotEmpty && match.version != expectedVersion) {
        logger.w('[FirmwareUpdate] verify: version mismatch '
            '(expected=$expectedVersion, got=${match.version}), but bank flip succeeded');
      }
      // Bank flip succeeded — mark as done
      _setState(state.copyWith(
        phase: FirmwareUpdatePhase.done,
        activeBank: match,
      ));
    } on ServiceError catch (e) {
      logger.e('[FirmwareUpdate] verify failed', error: e);
      _fail(FirmwareFailure.serviceError(e));
      rethrow;
    }
  }

  void updateUploadProgress(int sent, int total) {
    state = state.copyWith(
      phase: FirmwareUpdatePhase.uploading,
      uploadedChunks: sent,
      totalChunks: total,
    );
  }

  void updateTargetStatus(String status) {
    state = state.copyWith(targetStatus: status);
  }

  void updateRebootCountdown(Duration remaining) {
    state = state.copyWith(rebootRemaining: remaining);
  }

  /// Move to [FirmwareUpdatePhase.failed] carrying a reason the view can translate.
  ///
  /// Took a `String` until this was localized, and that signature was the defect:
  /// this class has no `BuildContext`, so every sentence the thirteen callers passed
  /// was English in all 26 locales. The type is now the guard — there is no
  /// fourteenth caller that can pass copy.
  ///
  /// **And it logs here, once**, which is what the move to a value would otherwise
  /// have cost. The old English string was at least readable in the console; a
  /// reason carrying a count or a bank status is not, unless something writes it
  /// down. Six of the callers log nothing of their own, so without this line the
  /// only record of "three banks claimed to be active" would be a screenshot.
  void _fail(FirmwareFailure failure) {
    logger.w('[FirmwareUpdate] failed: $failure');
    _setState(state.copyWith(
      phase: FirmwareUpdatePhase.failed,
      failure: failure,
    ));
  }

  /// Test-only seam: directly seed an active/target bank pair without hitting
  /// the service, useful for snapshot / golden tests in PR-5.
  @visibleForTesting
  void debugSeedBanks({
    FirmwareImageUIModel? active,
    FirmwareImageUIModel? target,
  }) {
    state = state.copyWith(activeBank: active, targetBank: target);
  }
}
