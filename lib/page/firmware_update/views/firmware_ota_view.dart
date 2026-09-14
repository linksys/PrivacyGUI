import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/admin/views/dialogs/confirm_action_dialog.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_info.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/services/firmware_ota_check_service.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_update_warning_note.dart';
import 'package:privacy_gui/page/firmware_update/views/dialogs/firmware_update_recovery_dialog.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Over-the-air firmware update: ask the router to fetch an image itself.
///
/// #1549 split the single firmware page in two along the line the two flows
/// actually differ on — where the image comes from. This page owns the check
/// against the cloud OTA API and the install it can start; the manual page owns
/// picking a file out of this browser and pushing it. What they share, once an
/// install is running, is [FirmwareInstallPhaseCard].
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
  /// Delay after triggering OTA install before showing recovery dialog.
  /// Router needs to download (~50-100MB) + flash, typically ~120 seconds.
  static const _otaInstallDelayBeforeReboot = Duration(seconds: 120);

  @override
  void initState() {
    super.initState();
    // Not optional here, and not merely a mirror of the manual page: the install
    // this page starts reads `state.targetBank` for the instance to download
    // into, and `state.activeBank` for the "current version" line in the confirm
    // dialog. Both are populated only by `loadBanks`, and the notifier is shared
    // session state that this page may well be the first to mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The future is handled rather than dropped. `loadBanks` records the
      // failure in state *and* rethrows — pinned by
      // `firmware_update_notifier_test.dart:181` — so a fire-and-forget call
      // turns a slow or busy router into an uncaught async error on a page that
      // has already rendered the failure it describes. The state is the channel
      // this page reads; the log line is so the swallow is not silent.
      ref
          .read(firmwareUpdateNotifierProvider.notifier)
          .loadBanks()
          .catchError((Object error) {
        logger.d('[FirmwareOta] loadBanks reported $error, '
            'already in notifier state');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(firmwareUpdateNotifierProvider);

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
          child: _buildBody(childContext, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, FirmwareUpdateState state) {
    final install = _buildInstallCard(state);
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
          _OtaCheckCard(
            state: state,
            onCheck: () => _onCheckForUpdates(context),
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
}

/// Card for checking OTA firmware updates.
class _OtaCheckCard extends StatelessWidget {
  const _OtaCheckCard({
    required this.state,
    required this.onCheck,
  });

  final FirmwareUpdateState state;
  final VoidCallback onCheck;

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
    final scheme = Theme.of(context).colorScheme;

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
              // `onTap` stays wired: `AppButton._isEnabled` is
              // `onTap != null && !isLoading`, so the tap is already ignored, and
              // passing null as well would only re-state it in a second place.
              final button = AppButton.primaryOutline(
                label: loc(context).checkForUpdates,
                identifier: 'firmware-check',
                onTap: onCheck,
                size: size,
                isLoading: isChecking,
              );
              // `Expanded` on the label rather than `MainAxisSize.min` on the row:
              // the sentence is what made this line unshrinkable, and letting it wrap
              // is the only way the line fits 256px in any locale. Alignment moves to
              // `start` because it now has more than one line to align to.
              final upToDate = state.otaUpToDate && !isChecking
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: scheme.primary,
                        ),
                        AppGap.sm(),
                        Expanded(
                          child: AppText.bodyMedium(
                            loc(context).firmwareUpToDate,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    )
                  : null;

              if (stacked) {
                // `stretch` gives the button the whole line, so its label has the
                // card's full width to render in instead of ellipsizing inside
                // ui_kit's `Flexible`. The gate pins that it does not ellipsize.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    button,
                    if (upToDate != null) ...[
                      AppGap.md(),
                      upToDate,
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  button,
                  if (upToDate != null) ...[
                    AppGap.md(),
                    Expanded(child: upToDate),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
