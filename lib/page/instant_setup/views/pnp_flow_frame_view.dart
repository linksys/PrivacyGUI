import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_notifier.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_install_phase_card.dart';
import 'package:privacy_gui/page/firmware_update/views/components/firmware_update_warning_note.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_setting_step_pages.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/util/qr_code.dart';
import 'package:privacy_gui/util/wifi_credential.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// What the PnP shell draws around the page the URL names (#1511 P4): the top
/// bar, the stepper, and the flow's status screens.
///
/// **The stepper is here so that it stays mounted.** A shell's widget is not
/// rebuilt when the user moves between its child routes, and on web every page
/// change fades the page (`app.dart`'s `FadePageTransitionsBuilder`): drawn by
/// a step's page, the stepper would fade on every step, and its segments would
/// not animate because its `State` would not survive. It shows from the first
/// setting step to Your Network, including while saving and reconnecting
/// (D4), and not on the entry checks, the firmware stage or the completion
/// screen. Its segments, their order and their labels come from the plan.
///
/// **The status screens are drawn over the page, and have no URL.** Saving,
/// reconnecting, the firmware stage, the completion screen and a wizard that
/// could not start are phases of the flow, not places: [child] — the step
/// where Save was pressed — stays mounted underneath, hidden, so a save that
/// comes back to the form shows that step as the user left it, and Back can
/// never land on "Saving".
///
/// A page view by the layout gate's rule (`views/*_view.dart`) although it is
/// not a route's page: the gate pumps it around a step's page to sweep the
/// stepper and the status screens, which a step's page pumped alone does not
/// show. The flow's own logic — phase-driven navigation, the save-error message —
/// is `PnpFlowShell`'s; the frame's status screens only carry their buttons (the
/// reconnect step's Next, Try again, the completion screen's Print and Done).
class PnpFlowFrameView extends ConsumerWidget {
  const PnpFlowFrameView({
    super.key,
    required this.stepId,
    required this.child,
  });

  /// The wizard step the URL names, or `null` off the steps (the entry).
  final String? stepId;

  /// The page the URL names — in the app, the PnP shell's navigator.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(pnpProvider);
    final phase = flow.phase;
    final plan = flow.plan;
    final status = _status(context, ref, phase);
    final steps = plan?.stepIds ?? const <String>[];
    final current = stepId == null ? -1 : steps.indexOf(stepId!);
    final showStepper = current >= 0 &&
        switch (phase) {
          WizardConfiguring() ||
          WizardSaving() ||
          WizardSaved() ||
          WizardNeedsReconnect() ||
          WizardTestingReconnect() =>
            true,
          _ => false,
        };

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: false,
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showStepper) ...[
              AppStepper(
                steps: [
                  for (final id in steps)
                    StepperStep(id: id, label: pnpStepLabel(context, id)),
                ],
                currentStep: current,
                completedSteps: {for (var i = 0; i < current; i++) i},
                indicatorType: StepIndicatorType.bar,
                stepSize: 4.0,
                interactive: false,
              ),
              AppGap.xl(),
            ],
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hidden, not removed: the step's page and its fields stay
                  // as the user left them under the status (1.x did the same
                  // with Opacity + IgnorePointer).
                  Visibility(
                    visible: status == null,
                    maintainState: true,
                    maintainAnimation: true,
                    child: child,
                  ),
                  if (status != null)
                    LayoutBuilder(
                      builder: (context, box) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: box.maxHeight),
                          child: Center(child: status),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The status screen [phase] draws over the page, or `null` for none.
  Widget? _status(BuildContext context, WidgetRef ref, PnpPhase phase) =>
      switch (phase) {
        WizardSaving() ||
        WizardSaved() ||
        WizardCheckingFirmware() =>
          _buildSavingOverlay(context),
        WizardNeedsReconnect(newSsid: final ssid) =>
          _buildReconnectView(context, ref, ssid),
        WizardTestingReconnect(
          attemptCount: final count,
          maxAttempts: final max,
        ) =>
          _buildTestingReconnect(context, count, max),
        WizardUpdatingFirmware() => _buildFirmwareUpdate(context, ref, phase),
        WizardWifiReady() => _buildComplete(context, phase),
        WizardError(message: final msg) => _buildError(context, ref, msg),
        _ => null,
      };

  // ── Saving / Loading ──────────────────────────────────────

  Widget _buildSavingOverlay(BuildContext context) {
    return Center(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoader(),
              AppGap.lg(),
              AppText.bodyMedium(
                loc(context).pnpSavingChangesDesc,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reconnect ─────────────────────────────────────────────

  Widget _buildReconnectView(BuildContext context, WidgetRef ref, String ssid) {
    return Center(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(Icons.wifi, size: 48),
              AppGap.lg(),
              AppText.titleMedium(loc(context).pnpReconnectWiFi),
              AppGap.md(),
              // The new network is not on the air yet when this screen appears:
              // on FLWRT 2.0.2 the router broadcast it ~40 s after the write was
              // sent (bench, 2026-10-05), so "connect now" sent the user looking
              // for a name that was not there.
              AppText.bodyMedium(
                loc(context).pnpReconnectWiFiRestarting,
                textAlign: TextAlign.center,
              ),
              AppGap.sm(),
              AppText.titleSmall(ssid),
              AppGap.xxxl(),
              AppButton(
                label: loc(context).next,
                onTap: () => ref.read(pnpProvider.notifier).testReconnect(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Testing Reconnect ─────────────────────────────────────

  Widget _buildTestingReconnect(
      BuildContext context, int attempt, int maxAttempts) {
    return Center(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoader(),
              AppGap.lg(),
              AppText.bodyMedium(
                '${loc(context).checkingForInternet} ($attempt/$maxAttempts)',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Firmware Update ───────────────────────────────────────

  /// The first-connection firmware update: the version, the progress, and no way
  /// out (REQ-B2).
  ///
  /// **W5's card, not a copy of it.** `FirmwareInstallPhaseCard` already renders the
  /// six install phases — including the two-pass `fwup_state` progress that mode 2
  /// produces — off `firmwareUpdateNotifierProvider`, which is the same notifier the
  /// PnP stage drives. Anything drawn here instead would be a second phase machine
  /// reading the same fields, and #1497 already recorded what that costs.
  ///
  /// **No Skip, and nothing else to press.** The card's only control is the retry on
  /// its failure card, and a failure does not reach this screen: the notifier catches
  /// it and finishes setup. So this phase has zero affordances by construction rather
  /// than by hiding buttons — first connection's only two ways past a firmware update
  /// are "there is none" and "there is no internet", and both are decided before the
  /// phase is published. That is half of REQ-B2's lock and the load-bearing half:
  /// this frame has no app bar, so the other half is the route's `onExit` guard and
  /// the shell's back policy rather than anything in this file.
  Widget _buildFirmwareUpdate(
      BuildContext context, WidgetRef ref, WizardUpdatingFirmware phase) {
    final firmwareState = ref.watch(firmwareUpdateNotifierProvider);

    return Semantics(
      // One anchor per page, the same shape the two firmware pages emit and for the
      // same reason (the E2E phase-sequence walk keys on the phase name rather than
      // on translated copy). Prefixed, because this is a different page: the walk
      // must be able to tell an update during setup from one on the admin page.
      identifier: 'pnp-firmware-phase-${firmwareState.phase.name}',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText.headlineSmall(
                loc(context).updatingFirmware,
                textAlign: TextAlign.center,
              ),
              // Omitted rather than blank when the router published `Available=true`
              // with no `Version`, which it does on some builds.
              if (phase.version.isNotEmpty) ...[
                AppGap.sm(),
                AppText.bodyMedium(
                  loc(context).availableVersionLabel(phase.version),
                  textAlign: TextAlign.center,
                ),
              ],
              AppGap.xl(),
              FirmwareInstallPhaseCard(state: firmwareState),
              AppGap.lg(),
              // The bound this phase otherwise does not have: it can sit on
              // `rebooting` for up to `pnpFirmwareRebootDeadlineProvider` (six
              // minutes) with no Skip and no way back, and a spinner with no stated
              // duration is what makes a user power-cycle a router mid-flash. The
              // existing note is reused rather than a new string written — it
              // already says both halves ("approximately 5–8 minutes", "do not power
              // off"), in 26 locales, and it is shared for exactly this reason.
              const FirmwareUpdateWarningNote(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Complete ──────────────────────────────────────────────

  Widget _buildComplete(BuildContext context, WizardWifiReady phase) {
    if (phase.isSplitMode) {
      return _buildCompleteSplitMode(context, phase);
    }
    return _buildCompleteUnifiedMode(context, phase.ssid, phase.password);
  }

  /// Leaves the wizard for the dashboard.
  ///
  /// Nothing to tidy up on the way out since 2026-09-16: the credentials this screen
  /// shows live in the phase object and nowhere else, so leaving the screen is the
  /// whole of forgetting them. It used to `await completeSetup()` to delete a
  /// persisted copy before navigating — see `WizardWifiReady` for why that copy is
  /// gone.
  void _onDone(BuildContext context) {
    context.go(RoutePath.uspDashboard);
  }

  Widget _buildCompleteUnifiedMode(
      BuildContext context, String ssid, String password) {
    final wifiString = WiFiCredential(
      ssid: ssid,
      password: password,
      type: SecurityType.wpa,
    ).generate();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Assets.images.pnpFinishDesktop.svg(width: 120),
                AppGap.lg(),
                AppText.headlineSmall(loc(context).pnpWiFiReady(ssid)),
                AppGap.xl(),

                // QR Code
                QrImageView(
                  data: wifiString,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
                AppGap.xl(),

                // WiFi Name
                _buildCredentialRow(
                  context,
                  label: loc(context).wifiName,
                  value: ssid,
                ),
                AppGap.sm(),

                // WiFi Password
                _buildCredentialRow(
                  context,
                  label: loc(context).wifiPassword,
                  value: password,
                ),
                AppGap.xl(),

                // Actions
                //
                // A `Wrap`, not a `Row`: at 320px the two buttons at their intrinsic
                // widths overflowed in all 26 locales (#1602), and the honest
                // degradation for a pair of actions is a second line rather than two
                // squeezed labels — `Print` and `Done` are what the screen is for.
                // Above ~480px this lays out exactly as the `Row` did.
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton.text(
                      label: loc(context).print,
                      icon: AppIcon.font(Icons.print_outlined, size: 18),
                      onTap: () async {
                        final imageBytes = await createWiFiQRCode(
                          WiFiCredential(
                            ssid: ssid,
                            password: password,
                            type: SecurityType.wpa,
                          ),
                        );
                        if (context.mounted) {
                          await printWiFiQRCode(
                              context, imageBytes, ssid, password);
                        }
                      },
                    ),
                    AppButton(
                      label: loc(context).done,
                      onTap: () => _onDone(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompleteSplitMode(BuildContext context, WizardWifiReady phase) {
    final bands = phase.bands;
    // Unreachable: `WizardWifiReady.isSplitMode` is `bands.length > 1`, so an empty
    // list never gets here. Kept because the old signature took the whole config and
    // this guard was load-bearing then — and because falling back is what the caller
    // would want if the invariant ever moved. It takes the **phase** rather than the
    // band list so that the fallback has the real credentials to fall back to: a
    // placeholder chosen to satisfy a signature would be drawn on the one screen
    // where these two strings exist nowhere else.
    if (bands.isEmpty) {
      logger.w('[PnP] split mode with no bands — falling back to unified mode');
      return _buildCompleteUnifiedMode(context, phase.ssid, phase.password);
    }
    // Use first band for title display
    final firstBand = bands.first;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Assets.images.pnpFinishDesktop.svg(width: 120),
                AppGap.lg(),
                AppText.headlineSmall(
                    loc(context).pnpWiFiReady(firstBand.ssid)),
                AppGap.xl(),

                // Per-band credentials
                ...bands.map((band) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: LayoutBlock(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.labelLarge(band.bandName),
                            AppGap.md(),
                            _buildCredentialRow(
                              context,
                              label: loc(context).wifiName,
                              value: band.ssid,
                            ),
                            AppGap.xs(),
                            _buildCredentialRow(
                              context,
                              label: loc(context).wifiPassword,
                              value: band.password,
                            ),
                          ],
                        ),
                      ),
                    )),

                AppGap.md(),

                // Actions
                AppButton(
                  label: loc(context).done,
                  onTap: () => _onDone(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Both texts are `Flexible` rather than one of them, and neither
        // ellipsizes: the value is an SSID or a passphrase the user has to read off
        // this screen and type into another device, so dropping characters is not a
        // degradation here. `FlexFit.loose` keeps every layout that already fitted
        // byte-identical and lets the two strings wrap where they did not — which is
        // the whole of the fix, at 320px in all 26 locales and at 480px in `el` and
        // `fr_CA` (#1602). The copy affordance stays on the row's main axis so it
        // never strands on a line of its own.
        Flexible(child: AppText.bodyMedium('$label: ')),
        Flexible(child: AppText.titleSmall(value)),
        AppGap.xs(),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            AppToast.show(
              context,
              type: ToastType.success,
              title: loc(context).sharedCopied,
            );
          },
          child: AppIcon.font(Icons.copy, size: 16),
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.font(Icons.error_outline, size: 48, color: Colors.red),
              AppGap.lg(),
              AppText.bodyMedium(
                message,
                textAlign: TextAlign.center,
              ),
              AppGap.xl(),
              AppButton.text(
                label: loc(context).tryAgain,
                onTap: () =>
                    ref.read(pnpProvider.notifier).startPostLoginFlow(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
