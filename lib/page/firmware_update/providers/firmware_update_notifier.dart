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
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_failure.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
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

  /// Whether a reading of the router *working* has been seen — the check included.
  ///
  /// [_sawUpdateRunning]'s weaker sibling, and they are two flags because they
  /// license two different claims. That one is evidence an update was in flight, so
  /// a later failure may be attributed to it; this one is evidence `fwupd` ran at
  /// all, which is what the `idle` verdict needs — see
  /// [FirmwareOtaInstallProgress.namesRouterWork] and [_applyInstallOutcome]'s
  /// `idle` arm. Reset at the same three sites as its sibling, for the same reason:
  /// a sighting inherited from the previous watch is a claim about a run that is
  /// over.
  bool _sawRouterWorking = false;

  /// Whether an observe watch is already polling.
  ///
  /// One watch at a time, and this is the only entry point that needs saying so.
  /// [observeRunningOtaInstall] is called on page open **and** by the read-failure
  /// card's retry, so a router that is slow to answer gets a second twenty-minute
  /// poll loop per tap — all of them publishing into one `otaProgress`, and each of
  /// them resetting the `_cancelRequested` flag the others terminate on, so a
  /// `cancel()` in between is undone rather than obeyed.
  bool _observing = false;

  /// `fwup_error_code` as it stood before the install this page dispatched.
  ///
  /// **Load-bearing on the manual path, not a belt.** Measured on FW
  /// `2.0.1.26091601`: `fwcc` — which is what a manual upload is verified and flashed
  /// by — writes `newfirmware_status_details` at four sites and **clears it at none**,
  /// and the only clear in the whole firmware outside `fwupd` is in
  /// `service_autofwup.sh`'s `init_variables()`, which runs on boot. So one failed
  /// upload leaves its code standing for the rest of the boot, and without this
  /// baseline every later manual install — including the ones that work — would report
  /// "the firmware failed the router's security check".
  ///
  /// The OTA path has the same field for the opposite reason: there `fwupd` does clear
  /// at run start, so the diff is a belt over a guarantee.
  ///
  /// Null when the pre-dispatch read failed, which is what makes the comparison
  /// refuse rather than assume — see [_routerNamedFailure].
  FirmwareUpdateErrorCode? _codeBeforeInstall;

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
  /// Three fields, and the third is not a bank: the same read carries the virtual
  /// `ota` row, so an offer the router is already making becomes this page's opening
  /// verdict without anybody pressing Check. See [_offerAlreadyOnTheRouter] for what
  /// it will and will not overwrite. Inert on the manual page, which reads no
  /// verdict.
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
        otaCheck: _offerAlreadyOnTheRouter(banksData),
        clearStateReadError: true,
      ));
    } catch (e) {
      logger.e('[FirmwareUpdate] loadBanks failed', error: e);
      _setState(state.copyWith(stateReadError: e.toString()));
      rethrow;
    }
  }

  /// The offer the router is **already** making, as the page's opening verdict —
  /// or null to leave the verdict alone.
  ///
  /// The OTA page used to open in `notChecked` however much the router had to say,
  /// so a user who arrived from the dashboard banner met a page with a Check button
  /// and no offer, and had to ask a question that had already been answered. The
  /// banner is built from this same `ota` row.
  ///
  /// Not a claim of our own: `Available` on the virtual `ota` row is the router's
  /// record of its last completed check, by the auto-update daemon or by this app,
  /// and `Available=false` is reported both for "checked, nothing new" and for
  /// "never checked" — so the false case seeds nothing and `notChecked` stands. The
  /// predicate is [FirmwareRouterOtaCheckService]'s own, off the L1 cache instead of
  /// a fresh poll, so the seeded verdict and a checked one cannot disagree.
  ///
  /// **Only `notChecked` is replaced**, and null is how `copyWith` is told to leave
  /// the rest. A check that ran in this session is a later answer than the row, and
  /// [loadBanks] is called again by the read-error card's retry — so overwriting
  /// would resurrect the offer a `noUpdateFound` had just ruled out.
  ///
  /// Deliberately **not** gated on `autoupdate_flags`, which is where this parts
  /// company with `firmwareUpdateOfferedVersionProvider`. That gate is there because
  /// the dashboard banner is unsolicited — announcing an update to someone who
  /// turned checking off answers a question they withdrew. This page *is* the
  /// question, and a user who turned auto-update off and then walked to it is asking.
  FirmwareOtaCheckResult? _offerAlreadyOnTheRouter(
      FirmwareBanksData banksData) {
    // `checkFailed` is seedable for the same reason `notChecked` is: a check that
    // failed has said nothing about the firmware on the router, so an offer the router
    // is *still* making is newer information than our failure. Before this it was
    // excluded by being "not notChecked", which left the page unable to ever show a
    // standing offer again — no verdict line, no install action — until another check
    // succeeded. The install path makes the same choice for the same reason: leaving a
    // true, re-tappable offer up beats replacing it with our own denial.
    final verdict = state.otaCheck.verdict;
    if (verdict != FirmwareOtaCheckVerdict.notChecked &&
        verdict != FirmwareOtaCheckVerdict.checkFailed) {
      return null;
    }
    final ota = banksData.otaInstance;
    if (ota == null || !ota.available) return null;
    logger.i('[FirmwareUpdate] the router is already offering '
        '${ota.version.isEmpty ? 'an unnamed image' : ota.version} — showing it '
        'rather than waiting to be asked to check');
    return FirmwareOtaCheckResult.updateAvailable(version: ota.version);
  }

  /// Ask the router whether a newer firmware exists.
  ///
  /// **This app used to be a client of the Linksys cloud OTA API, and no longer
  /// is. That is a change of client, not the removal of a cloud.** The OTA server
  /// is still what a new image comes from — `fwupd` on the router resolves and
  /// fetches it, which is why `Download()` on the virtual `ota` instance needs no
  /// URL (see [UspFirmwareUpdateService.requestOtaCheck]). What went away is the app
  /// asking that server *itself*: doing so meant assembling a MAC, a model number
  /// and a hardware revision from three other providers to ask a server about a
  /// router it could not see, while the router already knew. So the question goes to
  /// the router — see [FirmwareRouterOtaCheckService] — and the router's firmware
  /// goes to the cloud.
  ///
  /// #1550 parked the direct path rather than deleting it and left when it went as a
  /// separate decision; that decision was made on 2026-09-16, so
  /// `firmware_ota_check_service.dart`, its `FirmwareOtaInfo` and the cloud-URL
  /// install are gone. There is one path from here, not a selected one.
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
      final routerFailed =
          result.verdict == FirmwareOtaCheckVerdict.checkFailed;
      // A check the router itself said failed (#1572). It goes into `failure` rather
      // than only into the verdict, because that is where `localizeFirmwareFailure`
      // reads and the reason is the router's own vocabulary — not a `ServiceError`
      // about the transport, which is what the `catch` below handles. The verdict is
      // still published so the card knows to draw no line: a failed check has said
      // nothing about the firmware on the router.
      _setState(state.copyWith(
        phase: FirmwareUpdatePhase.idle,
        otaCheck: result,
        // `clearFailure` is checked first by `copyWith`, so the two are exclusive
        // rather than combined: a router-reported failure sets one, every other
        // verdict clears whatever the last check left.
        failure: routerFailed
            ? FirmwareFailure.routerReported(result.errorCode!)
            : null,
        clearFailure: !routerFailed,
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
      // And the auto-update reading, which the OTA card's history line is built from
      // (#1572). `firmwareAutoUpdateDataProvider` is **not** autoDispose and is built
      // once by the dashboard orchestrator, so without this the line shows a boot-time
      // snapshot for the whole session: a router that had not checked at boot keeps
      // saying "not checked yet" however many checks run, and a code standing at boot
      // keeps saying the last check did not finish — on top of a check the user just
      // watched succeed. A check moves both values, so this is what makes the line
      // describe the router rather than the launch.
      //
      // **`invalidate`, not `refresh`.** Nothing here wants the value, only for the
      // stale one to go; and `refresh()` publishes an `AsyncError` and rethrows, so a
      // re-read that failed would turn a check the user watched succeed into an error
      // — and on a provider with no live listener it escapes as an uncaught async
      // error rather than reaching the `catch` above. Invalidation is lazy: whoever
      // watches next re-reads, which on this page is the very next frame.
      ref.invalidate(firmwareAutoUpdateDataProvider);
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
    _sawRouterWorking = false;
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
  /// broken under Remote Assistance, it is simply not offered there. The router-side
  /// OTA is the remote answer for the same need, and [triggerRouterOtaInstall] below
  /// is allowed in every mode.
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
    // Before the dispatch, and outside the lock: this is a read, and it is the only
    // thing that will let `verify()` tell a reason this upload produced from one an
    // earlier upload left behind. Best-effort — losing it costs the reason, not the
    // install.
    _codeBeforeInstall = await _errorCodeOrNull();
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

  /// Tells the router to fetch and install a newer firmware over its own uplink.
  ///
  /// **The only OTA install.** Until 2026-09-16 a `triggerOtaInstall` sat here too,
  /// taking a `firmwareUrl` that only the cloud OTA API could supply; #1550
  /// replaced the cloud check with the router's own and left that method parked
  /// with no caller, and it is now deleted along with the rest of the cloud path —
  /// there will be no cloud-supplied-URL install. This asks the router the same way
  /// the check does — `FirmwareImage.{ota}.Download()` with no URL — with
  /// `AutoActivate` flipped, which on this firmware selects `fwupd -m 2`: check,
  /// download, flash, reboot.
  ///
  /// Returns the watch's verdict; **`flashing` is not success.** It means the
  /// router is committed and has stopped answering, which is what a reboot looks
  /// like from here. The caller drives the rest — `enterRecoveryWaiting()`, the
  /// recovery dialog, then [verify] — exactly as `_onConfirmInstall` does for the
  /// manual path, because only the view can put a blocking dialog around it.
  ///
  /// `transientRestart`, allowed on every surface, and it is the half of the
  /// firmware pair that is easy to get wrong. An OTA is the *more* alarming of the
  /// two to watch — the router downloads, flashes and reboots — and it is also the
  /// one that works remotely, because the router fetches over its own uplink and
  /// nothing on the agent's path is destroyed. Together with [runUpload], which is
  /// refused there, the two are the whole argument for naming consequences instead
  /// of operations.
  Future<FirmwareOtaInstallResult> triggerRouterOtaInstall({
    required int otaInstance,
  }) async {
    ref.read(operationGuardProvider).enforce(DisruptionClass.transientRestart,
        operation: 'router OTA firmware install');
    _cancelRequested = false;
    _sawUpdateRunning = false;
    _sawRouterWorking = false;
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
    _sawRouterWorking = false;
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
    // What was *seen*, recorded separately from what is *drawn*, and in two
    // strengths because [_applyInstallOutcome] makes two different claims off it: a
    // failure may only be attributed to a phase that could only be an update, while
    // "the router checked and found nothing" needs no more than a check. See
    // [FirmwareOtaInstallProgress.namesAnUpdatePhase] and `namesRouterWork`.
    // Recorded before the guard below, because both are sightings either way.
    if (progress.namesAnUpdatePhase) _sawUpdateRunning = true;
    if (progress.namesRouterWork) _sawRouterWorking = true;
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
  /// showing — but only if that check was actually seen running, see the arm itself.
  /// On the observe path nobody asked the router anything, so publishing
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
        // And `noUpdateFound` only for a check that was **seen**, which is the same
        // rule the two failure arms below follow. The service returns `idle` on the
        // install path for two different reasons: `fwup_state` reached 1 and came
        // back to 0 — mode 2's own check disagreeing with the version we offered,
        // which is a verdict worth showing — or the 15 s startup grace expired with
        // the value never moving at all, which says only that nothing happened.
        //
        // The second is not hypothetical: on `2.0.1.26091319` the install trigger is
        // accepted and never consumed (Architecture#194), so every Update Now ends
        // here. Unsplit, the page answered it with "No new firmware was found" —
        // fabricated out of a timeout, about a router that was still offering the
        // very update the user had just pressed Update on, and it overwrote the
        // offer with its own denial. Leaving the previous verdict alone keeps the
        // offer on the card, which is both true and re-tappable.
        final concluded = dispatched && _sawRouterWorking;
        if (dispatched && !concluded) {
          logger.w('[FirmwareUpdate] the install was dispatched and the router '
              'was never seen working — leaving the last verdict alone rather '
              'than reporting that no update was found');
        }
        _setState(state.copyWith(
          phase: FirmwareUpdatePhase.idle,
          otaCheck:
              concluded ? const FirmwareOtaCheckResult.noUpdateFound() : null,
          clearOtaProgress: true,
        ));

      case FirmwareOtaInstallVerdict.failed:
        // The router named the reason (#1572). Guarded like `timedOut` below and for
        // the identical reason: on the observe path a failure may only be attributed
        // to an update this watch actually saw running, or a code left over from last
        // week becomes "your update failed" on a page where nothing was attempted.
        //
        // The service has its own half of that rule — it will not return this verdict
        // for a code it cannot attribute — so this is a second gate on the weaker
        // evidence rather than a duplicate: the service asks "could this code be this
        // run's", and this asks "was there a run of ours at all".
        if (!dispatched && !_sawUpdateRunning) {
          _discardStaleOutcome(
              result, 'a failed update', 'nothing was ever seen running');
          return;
        }
        _fail(FirmwareFailure.routerReported(result.errorCode!));

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

  /// `fwup_error_code`, or null when it could not be read.
  ///
  /// Null for two reasons that are the same to every caller — the parameter absent, or
  /// the `Get` failing — because neither licenses a claim.
  Future<FirmwareUpdateErrorCode?> _errorCodeOrNull() async {
    try {
      return (await _svc.fetchAutoUpdate()).errorCode;
    } catch (e) {
      logger.d('[FirmwareUpdate] could not read fwup_error_code ($e)');
      return null;
    }
  }

  /// The reason the router gave for the install this page dispatched, or null.
  ///
  /// **The one thing the router says about a failed manual upload.** Measured on
  /// 2026-09-17 with a deliberately bad image: `fwup_error_code` read `5`,
  /// `fwup_state` was `0`, the banks were unchanged, and the failure appeared in
  /// **zero log lines** — so this parameter is not merely the best account of what
  /// went wrong, it is the only one that exists anywhere. Not reading it does not hide
  /// the reason, it loses it.
  ///
  /// Attributed only when the code has **moved** since [_codeBeforeInstall], for the
  /// reason that field documents: on the manual path nothing clears it between runs
  /// inside a boot, so an unchanged code is as likely to be the previous upload's.
  Future<FirmwareUpdateErrorCode?> _routerNamedFailure() async {
    final before = _codeBeforeInstall;
    if (before == null) return null;
    final code = await _errorCodeOrNull();
    if (code == null || !code.isFailure || code == before) return null;
    logger.w('[FirmwareUpdate] the router named the install failure '
        '(${code.name}), which it did not report before the dispatch');
    return code;
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
      //
      // **Bounded, and it has to be.** This runs immediately after a firmware
      // reboot — exactly when in-flight bridge requests were cut off mid-flight —
      // and `whenIdle()` is a bare completer with no timeout of its own, so an
      // `_active` count that never returns to 0 would park the whole verify here
      // with the phase already set to `verifying`. Fifteen seconds and then
      // continue rather than fail: the settle is best-effort, the retry below is
      // what actually copes with TR-181 still coming up, and a settle that timed
      // out is not evidence about the flash.
      logger.d('[FirmwareUpdate] verify: waiting for throttler idle...');
      await ref
          .read(bridgeRequestThrottlerProvider)
          .whenIdle()
          .timeout(const Duration(seconds: 15), onTimeout: () {});

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
      // Structural, not by argument. The loop's three exits all leave this
      // non-null today — break on a non-empty read, return after `_fail`, rethrow
      // on the last attempt — but a fourth exit added later would have turned the
      // `!` this replaces into a `TypeError` thrown inside `verifying`, i.e. into
      // the trap the `finally` below exists to close.
      if (banksData == null) {
        _fail(const FirmwareFailure.banksUnreadableAfterReboot());
        return;
      }
      // Physical banks only. Every check below is about which slot the router
      // booted from, and the virtual OTA instance is not a slot: it would be
      // counted by the multi-Active consistency check and could be matched as
      // the expected instance if the router renumbers.
      final banks = banksData.physicalBanks;

      logger.d(
          '[FirmwareUpdate] verify: banks=${banks.map((b) => '${b.instancePath}:${b.status}').join(', ')}'
          ', expectedActiveInstance=$expectedActiveInstance, expectedVersion=$expectedVersion');

      // **The router's own reason first, when it named one this install produced.**
      // Everything below infers a failure from the *shape* of the bank table, and all
      // three sentences are about a reboot: "restarted but did not start the new
      // firmware", "image N was not reported after the router restarted". An image the
      // router refused at verification never got as far as a reboot, so those
      // sentences are wrong twice — and the true one is sitting in
      // `fwup_error_code`, where a failed manual upload was measured leaving it and
      // leaving nothing else at all.
      final named = await _routerNamedFailure();
      if (named != null) {
        _fail(FirmwareFailure.routerReported(named));
        return;
      }

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
    } catch (e) {
      // `catch`, not the `on ServiceError` this replaces — same argument as
      // [loadBanks] and the running-install observer, and here it was load-bearing:
      // `firmwareBanksDataProvider.refresh()` rethrows whatever it got, so a raw
      // USP error or a bare `TimeoutException` arrived unchanged, missed the arm
      // entirely, and never reached `_fail()`. The call sites' own `catch (_)` then
      // swallowed it on the premise that a failure card had already been
      // published — which for that path was false.
      logger.e('[FirmwareUpdate] verify failed', error: e);
      _fail(e is ServiceError
          ? FirmwareFailure.serviceError(e)
          : const FirmwareFailure.banksUnreadableAfterReboot());
      rethrow;
    } finally {
      // The belt [triggerRouterOtaInstall] carries, for the reason written there:
      // `verifying` is `isUpdating`, and `_firmwareExitGuard` in
      // `route_usp_dashboard.dart` returns `!state.isUpdating` — it **silently**
      // vetoes the Navigator pop, so a phase left set by an unforeseen throw traps
      // the user on a page with no card explaining why.
      //
      // **`failed`, not the `idle` that belt restores.** This one runs after the
      // router has flashed and rebooted; an unverified flash must not read as
      // "nothing happened". `banksUnreadableAfterReboot` is the honest sentence for
      // every way out of here — "The router restarted, but its firmware information
      // could not be read."
      //
      // **Unreachable as written, and kept anyway.** The `catch` above is total
      // now, so every throw already lands on `_fail`; what this guards is the next
      // edit — an early `return` added above without a phase, or a narrowing of
      // that catch back to a type, which is exactly how the trap got here. The
      // consequence of being wrong is a page the user cannot leave and cannot read,
      // which is worth one `if` that normally does nothing.
      if (!_disposed && state.phase == FirmwareUpdatePhase.verifying) {
        logger.w('[FirmwareUpdate] verify left the phase set — reporting the '
            'firmware state as unread rather than leaving the page locked');
        _fail(const FirmwareFailure.banksUnreadableAfterReboot());
      }
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
