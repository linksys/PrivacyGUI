import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/localizations/firmware_failure_localizations.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_install_progress.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The phases an install passes through once it has started, drawn the same way
/// whichever entry point started it.
///
/// #1549 split one firmware page into two — a manual page that uploads an image
/// from this browser, and an OTA page that asks the router to fetch one — and
/// these six phases are the part the split does **not** divide. `triggerInstall`
/// and `triggerOtaInstall` walk the same notifier through `triggering →
/// installing`, `enterRecoveryWaiting` sets `rebooting`, and `verify` ends at
/// `done` or `failed`. A user who starts an OTA update needs the same progress,
/// the same failure copy and the same retry button as one who uploaded a file,
/// and both are reading one `firmwareUpdateNotifierProvider`.
///
/// So this is shared rather than copied. #1497 already recorded what copying
/// costs here: it dropped the phase machine along with a mode-gated entry point,
/// and every test passed because they all pumped `idle`, the one phase where the
/// entry point and the machine are the same widget.
///
/// **No `Semantics` boundary of its own.** `firmware-phase-${phase.name}` is
/// emitted once per page by whichever page is mounted, so that the E2E
/// phase-sequence walk sees exactly one anchor per frame. Wrapping here as well
/// would put two on screen for the six phases below.
class FirmwareInstallPhaseCard extends ConsumerWidget {
  const FirmwareInstallPhaseCard({super.key, required this.state});

  final FirmwareUpdateState state;

  /// The phases [build] draws. Exposed so a caller's `switch` and this widget
  /// cannot drift apart silently: a page that delegates a phase not in here gets
  /// an empty card rather than a compile error, so the set is the contract.
  ///
  /// It is a contract because something reads it —
  /// `test/page/firmware_update/firmware_install_phase_card_contract_test.dart`
  /// pumps both pages at all eleven phases and asserts this card appears exactly
  /// where [handles] says it should. Without that walk these two members would be
  /// a comment with braces, guaranteeing nothing.
  static const Set<FirmwareUpdatePhase> phases = {
    FirmwareUpdatePhase.triggering,
    FirmwareUpdatePhase.installing,
    FirmwareUpdatePhase.rebooting,
    FirmwareUpdatePhase.verifying,
    FirmwareUpdatePhase.done,
    FirmwareUpdatePhase.failed,
  };

  static bool handles(FirmwareUpdatePhase phase) => phases.contains(phase);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    switch (state.phase) {
      case FirmwareUpdatePhase.triggering:
        return _triggering(context);
      case FirmwareUpdatePhase.installing:
        return _installing(context);
      case FirmwareUpdatePhase.rebooting:
        return _rebooting(context);
      case FirmwareUpdatePhase.verifying:
        return _verifying(context);
      case FirmwareUpdatePhase.done:
        return _done(context);
      case FirmwareUpdatePhase.failed:
        return _failed(context, ref);
      case FirmwareUpdatePhase.idle:
      case FirmwareUpdatePhase.checkingOta:
      case FirmwareUpdatePhase.picking:
      case FirmwareUpdatePhase.validating:
      case FirmwareUpdatePhase.uploading:
        // Not an install in progress — an entry point, or a step only the manual
        // page has. Whichever page is mounted owns those, so nothing is drawn
        // here rather than something wrong being drawn.
        return const SizedBox.shrink();
    }
  }

  Widget _triggering(BuildContext context) => _progressCard(
        context,
        title: loc(context).preparingToInstall,
        body: loc(context).verifyingFirmwareImage,
      );

  /// The install itself, described by the router when the router is describing it.
  ///
  /// Two renderings off one phase, because two different things reach it. A manual
  /// upload pushed the image from this browser and the router publishes nothing
  /// while it writes, so there is no reading and the copy is the copy this card has
  /// always had. A router-side OTA runs `fwupd -m 2` — **check, download, flash** —
  /// and publishes `fwup_state` throughout, so one wording would claim the image
  /// was being written while the router was still deciding whether one existed.
  ///
  /// `otaProgress == null` is therefore the manual path and not a default: see
  /// [FirmwareUpdateState.otaProgress] for why no value of `fwup_progress` can
  /// stand in for "nothing known yet".
  Widget _installing(BuildContext context) {
    final progress = state.otaProgress;
    if (progress == null) {
      return _progressCard(
        context,
        title: loc(context).installingFirmware,
        body: loc(context).routerWritingImage,
      );
    }
    return _progressCard(
      context,
      title: _otaTitle(context, progress.status),
      body: _otaBody(context, progress.status),
      percent: progress.percent,
    );
  }

  /// What the router is doing, per its own `fwup_state`.
  ///
  /// Exhaustive rather than defaulted: a seventh [FirmwareAutoUpdateStatus] must
  /// not silently inherit a sentence that was written for a different phase.
  ///
  /// The last arm covers three states for two different reasons, and only one of
  /// them is a real rendering. `idle` and `failed` are not `isRunning`, so they
  /// never promote the phase and cannot reach this card — they are in the arm
  /// because the `switch` is exhaustive, not because they are drawn. `unknown` is
  /// drawn, on purpose: REQ-A7 keeps an unrecognised `fwup_state` inside
  /// `isInstalling` because a value that cannot be ruled out being a flash must not
  /// be shown as "nothing is happening". So the neutral pair is that state's
  /// requirement rather than a fallback — a firmware that grows a state reads as
  /// *something happening*, never as the last state this build recognised.
  String _otaTitle(BuildContext context, FirmwareAutoUpdateStatus status) =>
      switch (status) {
        FirmwareAutoUpdateStatus.checking =>
          loc(context).checkingForNewFirmware,
        FirmwareAutoUpdateStatus.downloading =>
          loc(context).downloadingFirmware,
        FirmwareAutoUpdateStatus.installing => loc(context).installingFirmware,
        // `rebooting` borrows the phase card's own pair rather than inventing a
        // sentence: `fwup_state=5` and `FirmwareUpdatePhase.rebooting` are the same
        // event seen from two sides, and the user must not be told two different
        // things while the router restarts once.
        FirmwareAutoUpdateStatus.rebooting => loc(context).rebootingRouter,
        FirmwareAutoUpdateStatus.idle ||
        FirmwareAutoUpdateStatus.unknown =>
          loc(context).updatingFirmware,
      };

  /// The sentence under the title, including the one instruction that matters.
  ///
  /// `installing` reuses `routerWritingImage`, the manual path's own sentence,
  /// because `fwup_state=4` *is* the router writing the image — a second wording
  /// for one fact would be a distinction the firmware does not make.
  String _otaBody(BuildContext context, FirmwareAutoUpdateStatus status) =>
      switch (status) {
        FirmwareAutoUpdateStatus.checking =>
          loc(context).routerCheckingForImage,
        FirmwareAutoUpdateStatus.downloading =>
          loc(context).routerDownloadingImage,
        FirmwareAutoUpdateStatus.installing => loc(context).routerWritingImage,
        FirmwareAutoUpdateStatus.rebooting =>
          loc(context).waitingForRouterOnline,
        FirmwareAutoUpdateStatus.idle ||
        FirmwareAutoUpdateStatus.unknown =>
          loc(context).routerUpdatingFirmware,
      };

  Widget _rebooting(BuildContext context) => _progressCard(
        context,
        title: loc(context).rebootingRouter,
        body: loc(context).waitingForRouterOnline,
      );

  Widget _verifying(BuildContext context) => _progressCard(
        context,
        title: loc(context).verifyingFirmware,
        body: loc(context).confirmingNewFirmware,
      );

  /// The four in-progress phases differ only in their two strings, and saying so
  /// once is what keeps them identical across the two pages.
  ///
  /// [percent] is null for all of them except a router-side download. The number
  /// arrives already clamped — see [FirmwareOtaInstallProgress.percent], which is
  /// non-null in exactly one state because `fwup_progress` has been measured
  /// behaving three different ways in the others.
  ///
  /// **The bar draws the progress as of ui_kit 3.3.2, and it did not before.** Until
  /// then `AppLoader` accepted `value` on a linear loader and discarded it: the only
  /// `_buildLinear` branch that rendered a progress input was an unnamed `default:`
  /// that was unreachable by construction, since the six linear `LoaderType` values
  /// are exactly the six cases the `switch` names and `LoaderStyle`'s own default
  /// sets one of them. So under every theme this app ships, the bar animated
  /// end-to-end regardless of `value`. Fixed upstream in
  /// `linksys/privacyGUI-UI-kit#92`; this file passed `value` throughout, so the bump
  /// is what made it render.
  ///
  /// **The `label` stays, and not as a leftover.** It is the only textual reading of
  /// the number — a bar at 42% is a length, and a length is not something a screen
  /// reader announces or a support call can be told over the phone. The manual upload
  /// card in `firmware_update_view.dart` puts its percentage above the bar instead,
  /// and that is not an inconsistency to fix: it has no body sentence, so there the
  /// percentage *is* the body.
  Widget _progressCard(
    BuildContext context, {
    required String title,
    required String body,
    int? percent,
  }) =>
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(title),
            AppGap.md(),
            AppText.bodyMedium(body),
            AppGap.xl(),
            AppLoader(
              variant: LoaderVariant.linear,
              value: percent == null ? null : percent / 100,
              label: percent == null
                  ? null
                  : loc(context).percentComplete('$percent'),
            ),
          ],
        ),
      );

  Widget _done(BuildContext context) {
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

  Widget _failed(BuildContext context, WidgetRef ref) {
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
          // The one place the failure becomes words. The notifier chose a
          // [FirmwareFailure]; nothing before this line has a `BuildContext`, which
          // is why it used to be able to hand over nothing but English.
          AppText.bodyMedium(localizeFirmwareFailure(context, state.failure)),
          AppGap.xl(),
          AppButton(
            label: loc(context).tryAgain,
            identifier: 'firmware-retry',
            onTap: () =>
                ref.read(firmwareUpdateNotifierProvider.notifier).cancel(),
          ),
        ],
      ),
    );
  }
}
