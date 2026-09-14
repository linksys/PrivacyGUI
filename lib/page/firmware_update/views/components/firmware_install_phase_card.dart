import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
        title: loc(context).preparingToInstall,
        body: loc(context).verifyingFirmwareImage,
      );

  Widget _installing(BuildContext context) => _progressCard(
        title: loc(context).installingFirmware,
        body: loc(context).routerWritingImage,
      );

  Widget _rebooting(BuildContext context) => _progressCard(
        title: loc(context).rebootingRouter,
        body: loc(context).waitingForRouterOnline,
      );

  Widget _verifying(BuildContext context) => _progressCard(
        title: loc(context).verifyingFirmware,
        body: loc(context).confirmingNewFirmware,
      );

  /// The four in-progress phases differ only in their two strings, and saying so
  /// once is what keeps them identical across the two pages.
  Widget _progressCard({required String title, required String body}) =>
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleMedium(title),
            AppGap.md(),
            AppText.bodyMedium(body),
            AppGap.xl(),
            const AppLoader(variant: LoaderVariant.linear),
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
          AppText.bodyMedium(state.errorMessage ?? loc(context).unknownError),
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
