import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_ota_check_result.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_phase.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_update_state.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_update_warning_note.dart';
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
/// carried, and the router's own install is #1551. So for now this page checks and
/// reports; the phase card below still renders an install driven from elsewhere.
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
    // Kept after #1550 took the install off this page, and now for a different
    // reason than the one it was written for. `state.activeBank`/`targetBank` are
    // no longer read here, but `loadBanks` is what puts the L1 banks provider into
    // `AsyncData` — and the tri-state below reads that provider to decide whether
    // this router can be asked about firmware at all.
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
    final support = _readOtaSupport();

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
          child: _buildBody(childContext, state, support),
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
  _OtaSupport _readOtaSupport() {
    final banks = ref.watch(firmwareBanksDataProvider);
    if (banks.hasError) return _OtaSupport.unknown;
    final data = banks.valueOrNull;
    if (data == null) return _OtaSupport.unknown;
    return data.otaInstance == null ? _OtaSupport.absent : _OtaSupport.present;
  }

  Widget _buildBody(
      BuildContext context, FirmwareUpdateState state, _OtaSupport support) {
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
            support: support,
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
}

/// Whether this router has the virtual `ota` instance — with a third answer for
/// "nobody knows yet".
///
/// See `_FirmwareOtaViewState._readOtaSupport` for why the unknown arm is not
/// folded into either of the other two.
enum _OtaSupport { unknown, present, absent }

/// The check button and whatever the last check said.
///
/// **Four visibly different renderings, and the ticket's requirement is that no
/// two of them collapse into each other:**
///
/// * no `ota` row → a sentence saying checks are not available here, and **no
///   button**. Permanent, so there is nothing to retry.
/// * checked, found something → "Update available" plus the version.
/// * checked, found nothing → a conservative line. Not "you are up to date": that
///   verdict is inferred from a timeout, see
///   [FirmwareRouterOtaCheckService.defaultDeadline].
/// * not checked, or a check that failed → the button and nothing else. A failure
///   is reported in a snack bar and leaves no line here, because every line here
///   is a claim about the firmware and a failed check supports none of them.
class _OtaCheckCard extends StatelessWidget {
  const _OtaCheckCard({
    required this.state,
    required this.support,
    required this.onCheck,
  });

  final FirmwareUpdateState state;
  final _OtaSupport support;
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
              final status = _verdictLine(context, scheme, isChecking);

              if (stacked) {
                // `stretch` gives the button the whole line, so its label has the
                // card's full width to render in instead of ellipsizing inside
                // ui_kit's `Flexible`. The gate pins that it does not ellipsize.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    button,
                    if (status != null) ...[
                      AppGap.md(),
                      status,
                    ],
                  ],
                );
              }

              return Row(
                children: [
                  button,
                  if (status != null) ...[
                    AppGap.md(),
                    Expanded(child: status),
                  ],
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
