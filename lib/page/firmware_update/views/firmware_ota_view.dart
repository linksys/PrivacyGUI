import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart'
    hide FirmwareImageUIModel;
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_router_status_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_state_unreadable_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_update_warning_note.dart';
import 'package:privacy_gui/page/firmware_update/views/dialogs/firmware_update_recovery_dialog.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Over-the-air firmware update: ask the router to fetch an image itself.
///
/// #1549 split the single firmware page in two along the line the two flows
/// actually differ on — where the image comes from. This page owns the check for a
/// newer image; the manual page owns picking a file out of this browser and
/// pushing it. What they share, once an install is running, is
/// [FirmwareInstallPhaseCard].
///
/// #1550 moved the check itself off the cloud OTA API and onto the router
/// (`FirmwareImage.{ota}.Download()` with no URL). The install this page used to
/// start went with it: it needed a `downloadUrl` that only the cloud answer
/// carried. #1551 gave it back, dispatched the same way the check is — the same
/// `Download()` with `AutoActivate` flipped, which on this firmware selects
/// `fwupd -m 2`: check, download, flash, reboot.
///
/// So this page now has three jobs rather than one, and the third is the one that
/// is easy to miss: it **watches an update it did not start**. Auto-update can
/// begin a flash on its own, so the page can be opened in the middle of one and
/// has to show it rather than offer to start a second (REQ-A6).
///
/// The split is why this page exists at all rather than a tab: the two entry
/// points have different audiences. Manual update is hidden in remote assistance
/// (a support agent has no file to give the router), while an OTA check is
/// exactly what a support agent wants — so the admin page needs an OTA entry that
/// survives a mode where the manual one does not.
class FirmwareOtaView extends ConsumerStatefulWidget {
  const FirmwareOtaView({super.key});

  @override
  ConsumerState<FirmwareOtaView> createState() => _FirmwareOtaViewState();
}

class _FirmwareOtaViewState extends ConsumerState<FirmwareOtaView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _readRouterState());
  }

  /// The two questions this page opens with, and re-asks when a read failed.
  ///
  /// `loadBanks` is what puts the L1 banks provider into `AsyncData` — the
  /// tri-state below reads that provider to decide whether this router can be asked
  /// about firmware at all. `observeRunningOtaInstall` is REQ-A6: it looks for an
  /// update that is already running, and it is called unconditionally rather than
  /// behind a cheaper pre-read because it *is* the cheap read —
  /// `FirmwareRouterOtaInstallService.observe` takes no startup grace and does not
  /// wait before its first `Get`, so an idle router costs one request and answers
  /// `idle`.
  ///
  /// Concurrent rather than sequential: neither answer depends on the other, and
  /// the bridge throttler already serialises what has to be serialised.
  ///
  /// [refresh] is passed by the read-failure card's retry. See
  /// [FirmwareUpdateNotifier.loadBanks] for why it cannot be left off there.
  /// Returns the **banks** read's future, and only that one.
  ///
  /// The retry button spins on what this returns, so the twenty-minute poll loop
  /// cannot be part of it: `observe()` keeps reading for as long as the router is
  /// flashing, and a spinner tied to that would be indistinguishable from a hung
  /// button. Nothing is dropped by leaving it out — [_swallow] is the handler on
  /// both futures.
  Future<void> _readRouterState({bool refresh = false}) {
    final notifier = ref.read(firmwareUpdateNotifierProvider.notifier);
    // The observe path's result is **read**, and this is REQ-A6's headline case
    // rather than symmetry with the dispatch. An auto-update that started on its own
    // reaches `flashing` here, and `flashing` is the one verdict with work left for
    // the view: `enterRecoveryWaiting()`, the recovery dialog, then `verify()`.
    // Discarded, the page sat at `installing` — which is `isUpdating`, which
    // `_firmwareExitGuard` **silently** vetoes the back arrow on — for the rest of
    // the session, watching a router that had already rebooted.
    _swallow('observeRunningOtaInstall', () async {
      final result = await notifier.observeRunningOtaInstall();
      if (!result.isFlashing || !mounted) return;
      await _awaitRebootAndVerify(context);
    });
    return _swallow('loadBanks', () => notifier.loadBanks(refresh: refresh));
  }

  /// Runs a read whose failure is already in notifier state.
  ///
  /// The future is handled rather than dropped: both calls record the failure in
  /// state *and* rethrow — pinned by `firmware_update_notifier_test.dart:181` — so
  /// a fire-and-forget call turns a slow or busy router into an uncaught async
  /// error on a page that has already rendered the failure it describes. The state
  /// is the channel this page reads; the log line is so the swallow is not silent.
  ///
  /// **`try`/`catch` around an `await`, not `.catchError`**, and that is not a style
  /// choice. `observeRunningOtaInstall` returns a `Future<FirmwareOtaInstallResult>`,
  /// which satisfies this parameter because a narrower return type is a subtype —
  /// but `Future<T>.catchError` checks its handler's return value against the
  /// **runtime** `T`, so a void handler on that future throws `ArgumentError` out of
  /// the error path. That is precisely the path this method exists for: the swallow
  /// worked on every success and raised an uncaught async error on the one failure
  /// the page draws a card for. Pinned by
  /// `firmware_state_unreadable_widget_test.dart`.
  Future<void> _swallow(String what, Future<void> Function() read) async {
    try {
      await read();
    } catch (error) {
      logger.d('[FirmwareOta] $what reported $error, '
          'already in notifier state');
    }
  }

  /// Every read this page makes, and everything derived from them — read **once**,
  /// here, and passed down.
  ///
  /// `child:` below is a builder that `UiKitPageView` hands to a layout widget, so
  /// anything it calls may run during layout rather than during build. A `ref.watch`
  /// reached from there registers a dependency whose change calls `markNeedsBuild`
  /// mid-layout, and — the reason this is worth the parameters rather than left as a
  /// hazard — it invites exactly the drift that had already happened: the install
  /// offer read `valueOrNull` with no `hasError` check while [_readOtaSupport] read
  /// the same provider with one, so two answers about one row were being derived by
  /// two different rules.
  ///
  /// `systemInfoDataProvider` is watched for the router header only, and it is
  /// deliberately **not** folded into [_stateIsUnreadable]: that decision is about
  /// the two reads the *notifier* makes and records in one `stateReadError`, and a
  /// missing model name is not a reason to replace a working Check button. The card
  /// draws no header when this is null and keeps the banks half.
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(firmwareUpdateNotifierProvider);
    final banks = ref.watch(firmwareBanksDataProvider);
    final systemInfo = ref.watch(systemInfoDataProvider).valueOrNull?.model;
    final support = _readOtaSupport(banks);
    // Null in both non-`present` arms, so the offer cannot be built off a row whose
    // absence is established *or* unknown.
    final ota =
        support == _OtaSupport.present ? banks.requireValue.otaInstance : null;

    return UiKitPageView.withSliver(
      identifier: 'firmware-ota',
      scrollable: true,
      title: loc(context).otaUpdate,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspAdmin,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child:
              _buildBody(childContext, state, banks, systemInfo, support, ota),
        );
      },
    );
  }

  /// Whether this router has the virtual `ota` row, as three answers rather than
  /// two.
  ///
  /// REQ-A1: a router with no `ota` row can never be asked about firmware, and
  /// that is permanent — OEM and rebadged builds do not ship the fwup stack. So
  /// the button is not shown at all, rather than shown and then failing.
  ///
  /// [_OtaSupport.unknown] is the third answer and the one worth having: while the
  /// banks read is in flight, or after it failed, the row's absence is not
  /// established. Collapsing that into `absent` would tell a user with a perfectly
  /// capable router that their router cannot do this, off a read that was merely
  /// slow.
  ///
  /// `hasError` is checked before `valueOrNull` because Riverpod attaches the
  /// previous value to an `AsyncError` whether asked to or not — see
  /// `FirmwareBanksDataNotifier.refresh`. Reading the value first would show the
  /// last good answer for a read that has since failed.
  _OtaSupport _readOtaSupport(AsyncValue<FirmwareBanksData> banks) {
    if (banks.hasError) return _OtaSupport.unknown;
    final data = banks.valueOrNull;
    if (data == null) return _OtaSupport.unknown;
    return data.otaInstance == null ? _OtaSupport.absent : _OtaSupport.present;
  }

  /// Whether the page has nothing to show because the router did not answer.
  ///
  /// **Both halves are required, and that is the point.** `loadBanks()` and
  /// `observeRunningOtaInstall()` run at the same time and record their failures in
  /// one [FirmwareUpdateState.stateReadError], so keying on that field alone would
  /// replace a working Check button whenever the *observe* read failed after the
  /// banks read had succeeded — taking away a control that works. The conjunction
  /// covers the case the card is for (nothing could be read), and
  /// [_OtaSupport.unknown] on its own is not it either: a read still in flight is
  /// not a read that failed, and the card would flash on every page open.
  ///
  /// **And not while there is an install to draw**, which is a third condition
  /// rather than a fourth reading. `stateReadError` is never cleared by the observe
  /// path, so a page opened during a flash whose *banks* read failed had both cards
  /// at once — and the top one read "Firmware status unavailable — nothing on the
  /// router has been changed" directly above "the router is writing the image, do
  /// not power it off". The banks read having failed is true and is not the story;
  /// the card exists to stop someone power-cycling a router mid-flash, so it must
  /// not be the thing that tells them nothing is happening.
  bool _stateIsUnreadable(FirmwareUpdateState state, _OtaSupport support) =>
      support == _OtaSupport.unknown &&
      state.stateReadError != null &&
      !FirmwareInstallPhaseCard.handles(state.phase);

  /// The install offer's action, or null when there is nothing to offer.
  ///
  /// Three independent facts have to line up, and each is a different failure if
  /// dropped: without the virtual `ota` row there is nothing to dispatch
  /// `Download()` on, without a verdict the dispatch is a check the user did not ask
  /// for, and in any phase but `idle` it starts a second update on top of the first.
  ///
  /// Decided here rather than inside the card because the *instance number* is one
  /// of the three, and it comes from the banks read.
  ///
  /// [ota] is passed in rather than watched here: this runs from `build`'s `child:`
  /// builder, which may execute during layout. See [build].
  VoidCallback? _installAction(BuildContext context, FirmwareUpdateState state,
      _OtaSupport support, FirmwareImageUIModel? ota) {
    if (support != _OtaSupport.present) return null;
    if (state.otaCheck.verdict != FirmwareOtaCheckVerdict.updateAvailable) {
      return null;
    }
    if (state.phase != FirmwareUpdatePhase.idle) return null;
    // Non-null whenever `support == present`, since [build] derives the two from one
    // read — so this is a null check for the compiler rather than a case that happens.
    if (ota == null) return null;
    return () => _onConfirmOtaInstall(context, state, ota.instance);
  }

  Widget _buildBody(
    BuildContext context,
    FirmwareUpdateState state,
    AsyncValue<FirmwareBanksData> asyncBanks,
    SystemInfoUIModel? systemInfo,
    _OtaSupport support,
    FirmwareImageUIModel? ota,
  ) {
    final install = _buildInstallCard(state);
    // `physicalBanks`: one row per boot slot. The virtual OTA instance is not a
    // slot, and on this page in particular it would print the version being
    // offered as a bank the router already holds — beside a card offering to go
    // and fetch it.
    final banks = asyncBanks.valueOrNull?.physicalBanks ?? const [];
    // One `firmware-phase-*` boundary per page, for the reason the manual page
    // gives: the E2E phase-sequence walk (PrivacyGUI-USP-E2E#114) keys on the
    // phase name rather than the translatable copy inside each card, and
    // `FirmwareInstallPhaseCard` deliberately carries no boundary of its own so
    // that there is exactly one anchor per frame across both pages.
    //
    // Around the whole body rather than around the install card, which is where
    // the manual page puts it. The two phases *this* page owns — `idle` and
    // `checkingOta` — draw no install card at all, so an anchor scoped to that
    // slot would be a 0x0 node for the one state the page exists in: invisible to
    // Playwright, and prunable from the browser a11y tree. The body is on screen
    // in every phase, so here the anchor always has a box.
    return Semantics(
      identifier: 'firmware-phase-${state.phase.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Same card, same position as the manual page — the two pages differ in
          // where the image comes from, not in which router they are about, and a
          // router-side install lands in the standby slot this draws. Without it
          // the page never said what firmware the router was currently running.
          //
          // Above the action rather than below it, matching the manual page. The
          // check card is the entry point, but the version it is offering is only
          // meaningful next to the version already installed.
          FirmwareRouterStatusCard(
            systemInfo: systemInfo,
            banks: banks,
            isLoadingBanks: asyncBanks.isLoading && banks.isEmpty,
            // An `AsyncError` leaves `banks` empty and `isLoading` false, which
            // reads as "No firmware banks reported" — a claim about the router's
            // slots — directly above a card saying the router could not be asked
            // anything.
            banksUnreadable: asyncBanks.hasError,
          ),
          AppGap.xl(),
          if (_stateIsUnreadable(state, support))
            FirmwareStateUnreadableCard(
              onRetry: () => _readRouterState(refresh: true),
            )
          else
            _OtaCheckCard(
              state: state,
              support: support,
              onCheck: () => _onCheckForUpdates(context),
              onInstall: _installAction(context, state, support, ota),
            ),
          // The gap belongs to the card, not to the column, for the reason
          // `usp_admin_view.dart` gives about its own gated card: a gap left
          // outside would spend `AppGap.xl` on a card that is not there, and on
          // this page "not there" is the resting state rather than an edge case —
          // idle would show two stacked gaps of dead space under the check card.
          if (install != null) ...[
            AppGap.xl(),
            install,
          ],
          AppGap.xl(),
          const FirmwareUpdateWarningNote(),
        ],
      ),
    );
  }

  /// The install-progress card for phases that have one, `null` for the phases
  /// this page draws nothing extra for.
  Widget? _buildInstallCard(FirmwareUpdateState state) {
    switch (state.phase) {
      case FirmwareUpdatePhase.idle:
      case FirmwareUpdatePhase.checkingOta:
        // The entry point for this page is the check card above — it holds
        // `firmware-check`, and while checking that button carries its own busy
        // state. Nothing extra belongs here, and unlike the manual page's matching
        // arm this one is not mode-gated: an OTA check is offered on every surface.
        return null;
      case FirmwareUpdatePhase.picking:
      case FirmwareUpdatePhase.validating:
      case FirmwareUpdatePhase.uploading:
        // Manual-only phases. Unreachable rather than merely unwanted: all three
        // are `isUpdating`, so the manual page's `onExit` refuses to let go of a
        // user who is in one, and they cannot arrive here to see this.
        return null;
      case FirmwareUpdatePhase.triggering:
      case FirmwareUpdatePhase.installing:
      case FirmwareUpdatePhase.rebooting:
      case FirmwareUpdatePhase.verifying:
      case FirmwareUpdatePhase.done:
      case FirmwareUpdatePhase.failed:
        return FirmwareInstallPhaseCard(state: state);
    }
  }

  /// Run a check and let the card render the verdict.
  ///
  /// No dialog on success, which is the visible change from the cloud path. That
  /// path opened a confirm dialog offering to install the version it had just been
  /// told about, because it *had* a `downloadUrl` to install from; the router
  /// answers with `Available`/`Version` and nothing to fetch, so the offer belongs
  /// to #1551 and the result stays on the card where the button is.
  ///
  /// The verdict is not read here at all — [FirmwareUpdateNotifier.checkForUpdate]
  /// publishes it into state and this widget is watching. Reading the return value
  /// as well would give the card two sources for one fact.
  Future<void> _onCheckForUpdates(BuildContext context) async {
    try {
      await ref.read(firmwareUpdateNotifierProvider.notifier).checkForUpdate();
    } on ServiceError catch (e) {
      // The snack bar, not the card. A check that failed leaves the card in
      // `notChecked` — deliberately saying nothing rather than "up to date" — so
      // the transient channel is the one that can say what went wrong without the
      // page carrying a stale error after the next successful check.
      logger.e('[FirmwareOta] check failed', error: e);
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
    }
  }

  /// Ask the router to fetch and install the image its check found.
  ///
  /// Deliberately the same shape as `_onConfirmInstall` on the manual page —
  /// confirm, dispatch, hand off to the recovery framework, verify — because it is
  /// the same reboot and the same verification, only with the router doing the
  /// fetching. What differs is that there is no fixed delay before the reboot wait:
  /// the manual path waits blind because it has no status to read, and this one has
  /// watched `fwup_state` reach 3 or 4 and stop answering.
  ///
  /// [otaInstance] is passed in rather than read here so that the offer and the
  /// dispatch cannot disagree about which row they mean.
  Future<void> _onConfirmOtaInstall(
      BuildContext context, FirmwareUpdateState state, int otaInstance) async {
    // Before the dialog, not after. The router picks the slot it flashes into, so
    // the only slot it can boot from is the one that was not active — and that is
    // what `verify()` checks. Without it a successful update would be reported as
    // "expected firmware bank not present" *after* the reboot, so refusing while
    // nothing has happened is the honest ordering.
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
    final FirmwareOtaInstallResult result;
    try {
      result = await notifier.triggerRouterOtaInstall(otaInstance: otaInstance);
    } on UnauthorizedError catch (e) {
      // #1496's firmware half, and the reason this arm cannot be folded into the
      // one below: `OperationGuard.enforce` throws *above* the phase change, on
      // purpose, so a refusal leaves the page in `idle` with no failure card to
      // read. Logging alone would make the button appear to do nothing at all.
      logger.e('[FirmwareOta] router OTA install refused', error: e);
      if (context.mounted) {
        showFailedSnackBar(context, localizeServiceError(context, e));
      }
      return;
    } on ServiceError catch (e) {
      // The notifier has already written the failure into the phase card, so this
      // snack bar is not the only channel — but it names the operation, which the
      // card's raw firmware text does not.
      logger.e('[FirmwareOta] router OTA install failed', error: e);
      if (context.mounted) {
        showFailedSnackBar(context, loc(context).failedToStartOtaUpdate);
      }
      return;
    }

    // Every other verdict is already on the card: `idle` means mode 2 checked and
    // found nothing (it checks before it downloads, so an accepted dispatch can
    // still come back empty), and `failed`/`timedOut` have failed the phase. Only
    // `flashing` means the router has committed and stopped answering, which is the
    // one outcome with something left for the view to do.
    if (!result.isFlashing || !context.mounted) return;
    await _awaitRebootAndVerify(context);
  }

  /// Wait out the reboot, then say whether the router came back on the new image.
  ///
  /// Shared by the two things that can reach `flashing`, and sharing it is the
  /// point: a flash this app dispatched and a flash it merely *found* running end
  /// identically — the router is committed, it has stopped answering, and the only
  /// question left is which bank it boots. An update started by auto-update
  /// therefore gets the same reboot dialog and the same verification as one started
  /// from this button, rather than a card that says "installing" forever.
  ///
  /// The state is re-read rather than passed in. Both callers reach here across an
  /// `await` that can last minutes, and `targetBank` / `otaCheck` are readings of
  /// the router that other things refresh in the meantime; the dispatch path's own
  /// pre-flight `targetBank` check is a refusal before anything happens, not a value
  /// to carry through a flash.
  Future<void> _awaitRebootAndVerify(BuildContext context) async {
    final notifier = ref.read(firmwareUpdateNotifierProvider.notifier);
    final state = ref.read(firmwareUpdateNotifierProvider);
    final target = state.targetBank;
    // The version the check named, which may be empty — the router publishes
    // `Available=true` with no `Version`, and an update nobody here started has no
    // check behind it at all. `verify()` treats a version mismatch as a warning and
    // the bank flip as the verdict, so an empty one costs nothing.
    final expectedVersion = state.otaCheck.version;

    notifier.enterRecoveryWaiting();
    await showFirmwareUpdateRecoveryDialog(context, ref);
    if (!context.mounted) return;

    if (ref.read(appConnectionStateProvider) !=
        AppConnectionState.authenticated) {
      // The user bailed out, or the serial fingerprint did not match. The recovery
      // framework and the route redirect own the page from here.
      return;
    }

    if (target == null) {
      // Only reachable on the observe path: nothing told this page which slot the
      // image went into, so there is no bank flip to check. The page goes back to
      // idle rather than claiming an outcome — and it must go somewhere, because
      // `rebooting` is `isUpdating` and would leave the back arrow vetoed.
      logger
          .w('[FirmwareOta] the router rebooted after an update this page did '
              'not start, and no target bank is known — nothing to verify');
      notifier.cancel();
      return;
    }

    try {
      await notifier.verify(
        expectedVersion: expectedVersion,
        expectedActiveInstance: target.instance,
      );
    } catch (_) {
      // The notifier has already moved to `failed` and published the message.
    }
  }
}

/// Whether this router has the virtual `ota` instance — with a third answer for
/// "nobody knows yet".
///
/// See `_FirmwareOtaViewState._readOtaSupport` for why the unknown arm is not
/// folded into either of the other two.
enum _OtaSupport { unknown, present, absent }

/// The check button, whatever the last check said, and the offer to act on it.
///
/// **Four visibly different renderings, and the ticket's requirement is that no
/// two of them collapse into each other:**
///
/// * no `ota` row → a sentence saying checks are not available here, and **no
///   button**. Permanent, so there is nothing to retry.
/// * checked, found something → "Update available" plus the version, and the
///   install offer below it. #1550 could report this and not act on it; #1551 is
///   the button that closes that gap.
/// * checked, found nothing → a conservative line. Not "you are up to date": that
///   verdict is inferred from a timeout, see
///   [FirmwareRouterOtaCheckService.defaultDeadline].
/// * not checked, or a check that failed → the button and nothing else. A failure
///   is reported in a snack bar and leaves no line here, because every line here
///   is a claim about the firmware and a failed check supports none of them.
///
/// A fifth rendering does **not** live here: a router that could not be read at all
/// gets [FirmwareStateUnreadableCard] in this card's place, because every state
/// above is an answer and that one is the absence of any.
class _OtaCheckCard extends StatelessWidget {
  const _OtaCheckCard({
    required this.state,
    required this.support,
    required this.onCheck,
    required this.onInstall,
  });

  final FirmwareUpdateState state;
  final _OtaSupport support;
  final VoidCallback onCheck;

  /// Starts the router-side install, or null when there is nothing to install.
  ///
  /// Nullable rather than a bool beside it: the offer needs the virtual `ota` row's
  /// instance number to dispatch on, so "there is something to offer" and "here is
  /// what to do about it" are one fact. See
  /// `_FirmwareOtaViewState._installAction`.
  final VoidCallback? onInstall;

  /// Card-content width below which the button and the status line stack.
  ///
  /// The row held two children that could neither shrink nor wrap: a button whose
  /// width is a localized label plus padding, and an up-to-date line whose
  /// `MainAxisSize.min` made it as wide as its own localized sentence. It overflowed
  /// in **all 26 locales** at 320px, 19 at 480px and 5 at 601px — worst `ru` at
  /// +357px, and +160px in `en` (#1380, 50 of 234 cells). `_buildIdleCard` in
  /// `firmware_update_view.dart` — the card this one used to sit above, before #1549
  /// put the two flows on separate pages — lays its two buttons out in a `Wrap` for
  /// the same reason; a `Wrap` cannot carry this pair because neither of *these*
  /// children fits a 256px line on its own, and a `RenderWrap` reports no overflow
  /// when one doesn't — it just paints past the card, which is worse than the bug it
  /// replaced.
  ///
  /// 600 is picked against measurement, not against the mobile breakpoint it
  /// coincides with: the widest locale needs ~580px for the pair, and the card grants
  /// ~473px at a 601px screen (which overflowed) and ~809px at 905px (which did not).
  ///
  /// Measured on the page this card used to live on. It moved to this page whole,
  /// under the same card padding at the same breakpoints, so the numbers carry —
  /// and #1549's own gate row re-measures them here rather than inheriting them.
  static const _stackBelow = 600.0;

  @override
  Widget build(BuildContext context) {
    final isChecking = state.phase == FirmwareUpdatePhase.checkingOta;
    // Live in `idle`, `done` and `failed` — the three phases where a check is the
    // reasonable next thing — and dead in the rest.
    //
    // Not a nicety. `checkForUpdate` sets `phase: checkingOta` unconditionally, and
    // this page can be in `installing` without anybody here having started it
    // (REQ-A6: auto-update flashes on its own and the observe read promotes the
    // phase). A tap during that took the "do not power off" card off the screen —
    // `_buildInstallCard` draws nothing for `checkingOta` — dispatched a second
    // `Download()` at a router writing NAND, and then re-offered "Update Now" on top
    // of the running update when the check came back.
    final blocked = state.isUpdating && !isChecking;
    final scheme = Theme.of(context).colorScheme;

    // No `ota` row: the sentence replaces the whole button line rather than
    // sitting under a disabled button. REQ-A1 — there is nothing to retry, so a
    // control that can only ever fail is worse than no control, and this arm skips
    // the `LayoutBuilder` because a wrapping sentence has nothing to stack against.
    if (support == _OtaSupport.absent) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(loc(context).otaUpdate),
            AppGap.md(),
            _statusLine(
              icon: Icons.info_outline,
              // `outline`, not `error`: this is a property of the router, and the
              // copy must not read as a failure the user could do something about.
              color: scheme.outline,
              child: AppText.bodyMedium(
                loc(context).otaCheckNotSupported,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.titleMedium(loc(context).otaUpdate),
          AppGap.md(),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < _stackBelow;
              // `small` when stacked, and this is a readability fix rather than a
              // taste one. A medium button spends `buttonHeight * 0.5` — 24px — of
              // padding on each side, so a full-width button on a 230px card line
              // grants its label 182px; `fr`'s "Rechercher des mises à jour" needs
              // 194.5px and ui_kit ellipsizes the remainder silently. `small` spends
              // 16px a side and draws `labelMedium`, which fits. Same component, its
              // own compact size, no new API — five other call sites in `lib/` already
              // pass this.
              final size = stacked ? AppButtonSize.small : AppButtonSize.medium;
              // ONE button in both states, busy expressed as `isLoading`.
              //
              // This used to be two buttons chosen by `isChecking`: a second
              // `AppButton` labelled "Checking..." with `onTap: null` and a bare
              // `CircularProgressIndicator` in its icon slot. That predates #1549
              // and moved here with the card; adopting the kit's own state costs
              // four defects that the swap had:
              //
              //   - **`firmware-check` disappeared while checking.** The busy copy
              //     carried no `identifier`, so the one control an E2E spec clicks
              //     left the semantics tree for the duration of the very operation
              //     the spec is waiting on. `AppButton` publishes `identifier`
              //     regardless of `isLoading`.
              //   - **The label stopped naming what was in flight.** "Checking..."
              //     is a state, not an action; ui_kit removed exactly this shape
              //     because a busy frame must not cost the user the name of the
              //     thing they started. Busy is now a layer over this button, so
              //     "Check for Updates" stays readable underneath it.
              //   - **A screen reader heard `enabled: false` and nothing else**,
              //     which cannot tell "working" from "not available". `isLoading`
              //     adds the `Busy` hint on a live region.
              //   - **The spinner ignored the theme and reduce-motion.** A raw
              //     `CircularProgressIndicator` spins forever in one style;
              //     `BusyFigureLayer` draws the active language's figure in the
              //     button's own `busyColor`, clipped to its shape, and parks on a
              //     legible rest frame when motion is reduced.
              //
              // `onTap` stays wired *for the busy state*: `AppButton._isEnabled` is
              // `onTap != null && !isLoading`, so a checking button already ignores
              // the tap, and passing null as well would re-state it in a second
              // place. `blocked` is a different fact — no spinner belongs on this
              // button while some other operation owns the router — so that one does
              // null the callback.
              final button = AppButton.primaryOutline(
                label: loc(context).checkForUpdates,
                identifier: 'firmware-check',
                onTap: blocked ? null : onCheck,
                size: size,
                isLoading: isChecking,
              );
              final status = _verdictLine(context, scheme, isChecking);
              final head = stacked
                  // `stretch` gives the button the whole line, so its label has the
                  // card's full width to render in instead of ellipsizing inside
                  // ui_kit's `Flexible`. The gate pins that it does not ellipsize.
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        button,
                        if (status != null) ...[
                          AppGap.md(),
                          status,
                        ],
                      ],
                    )
                  : Row(
                      children: [
                        button,
                        if (status != null) ...[
                          AppGap.md(),
                          Expanded(child: status),
                        ],
                      ],
                    );

              final install = onInstall;
              if (install == null) return head;

              // Its own full-width line below the check, in both geometries. Not
              // beside the check button: the wide row already holds a button and a
              // sentence that neither shrink nor wrap (#1380, 50 of 234 cells
              // overflowed), and a third child would put the offer back into the
              // pair that could not fit 256px in any locale.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  head,
                  AppGap.lg(),
                  AppButton.primary(
                    label: loc(context).updateNow,
                    // Inline literal, not composed: the E2E harvest reads Dart
                    // source as text, so an id built at runtime never reaches the
                    // specs' identifier list — silently, in both directions.
                    identifier: 'firmware-ota-install',
                    onTap: install,
                    size: size,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// What the last check found, or `null` when there is nothing to say.
  ///
  /// `null` in two cases that must not be confused with each other elsewhere but
  /// look the same here: a check that has not run, and a check that failed. Both
  /// leave the card showing only the button, because every sentence this method can
  /// return is a claim about the firmware on the router and neither state supports
  /// one. The failure is reported in a snack bar instead — see
  /// `_FirmwareOtaViewState._onCheckForUpdates`.
  ///
  /// Also `null` while checking: the in-flight state belongs to the button's own
  /// `isLoading`, and leaving the previous verdict up next to a running spinner
  /// would show the old answer as if it were the new one.
  Widget? _verdictLine(
      BuildContext context, ColorScheme scheme, bool isChecking) {
    if (isChecking) return null;
    switch (state.otaCheck.verdict) {
      case FirmwareOtaCheckVerdict.notChecked:
        return null;
      case FirmwareOtaCheckVerdict.updateAvailable:
        final version = state.otaCheck.version;
        return _statusLine(
          // The same icon `FirmwareUpdateAvailableBanner` uses for the same fact,
          // so the dashboard banner and this line are recognisably one offer.
          icon: Icons.system_update_outlined,
          color: scheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.bodyMedium(
                loc(context).updateAvailable,
                color: scheme.primary,
              ),
              // The version is a detail, and it can be absent: the router
              // publishes `Available=true` with an empty `Version` — see
              // `FirmwareRouterOtaCheckService`. An offer with no name is still an
              // offer, so the headline above never depends on this line.
              if (version.isNotEmpty)
                AppText.bodySmall(loc(context).availableVersionLabel(version)),
            ],
          ),
        );
      case FirmwareOtaCheckVerdict.noUpdateFound:
        return _statusLine(
          icon: Icons.check_circle,
          color: scheme.primary,
          child: AppText.bodyMedium(
            // Deliberately not "your firmware is up to date". This verdict is
            // reached by a deadline expiring, not by the router saying so, and the
            // copy is held to what was observed.
            loc(context).firmwareNoUpdateFound,
            color: scheme.primary,
          ),
        );
    }
  }

  /// An icon and a sentence that is allowed to wrap.
  ///
  /// `Expanded` on the text rather than `MainAxisSize.min` on the row: the sentence
  /// is what made the button line unshrinkable in the first place (#1380), and
  /// letting it wrap is the only way the line fits 256px in every locale. Alignment
  /// is `start` because there is more than one line to align to.
  Widget _statusLine({
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        AppGap.sm(),
        Expanded(child: child),
      ],
    );
  }
}
