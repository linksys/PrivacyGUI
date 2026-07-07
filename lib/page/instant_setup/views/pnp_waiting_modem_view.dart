import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/customs/circular_countdown_widget.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Step 3 of modem restart flow — plug back in, countdown, check internet.
///
/// Three stages driven by PnpPhase:
/// 1. Initial: "Plug back in" instruction + confirm button
/// 2. ModemRestartCountdown: Circular countdown timer (150s)
/// 3. ModemRestartCheckingInternet: Spinner with attempt counter
class PnpWaitingModemView extends ConsumerWidget {
  const PnpWaitingModemView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pnpProvider);
    final phase = state.phase;

    // Navigate on success or failure
    ref.listen(pnpProvider, (prev, next) {
      if (next.phase is WizardConfiguring || next.phase is WizardInitializing) {
        context.go(RoutePath.pnp);
      } else if (next.phase is NoInternet && prev?.phase is! NoInternet) {
        context.go(RoutePath.pnpNoInternetConnection);
      }
    });

    // Status overlay phases (countdown, checking) — full-screen centered.
    // Same pattern as IspSaving: plain box mode lets MainAxisAlignment.center
    // actually center, instead of withSliver where the column collapses to
    // intrinsic height.
    if (phase is ModemRestartCountdown ||
        phase is ModemRestartCheckingInternet) {
      return UiKitPageView(
        scrollable: false,
        appBarStyle: UiKitAppBarStyle.none,
        useMainPadding: false,
        child: (context, constraints) => phase is ModemRestartCountdown
            ? _buildCountdown(context, phase)
            : _buildChecking(
                context,
                phase as ModemRestartCheckingInternet,
              ),
      );
    }

    // Default: plug back in instruction (a normal scrollable form-like page).
    return UiKitPageView.withSliver(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      onBackTap: () => context.go(RoutePath.pnpNoInternetConnection),
      child: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildPlugBackIn(context, ref),
          ),
        ),
      ),
    );
  }

  /// Initial: instruct user to plug modem back in.
  Widget _buildPlugBackIn(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Assets.images.modemWaiting.svg(width: 160)),
        AppGap.xxxl(),
        AppText.headlineSmall(loc(context).pnpWaitingModemPlugBack),
        AppGap.md(),
        AppText.bodyMedium(loc(context).pnpWaitingModemDesc),
        AppGap.xxxl(),
        AppButton.primary(
          label: loc(context).pnpWaitingModemPluggedIn,
          onTap: () =>
              ref.read(pnpProvider.notifier).startModemRestartCountdown(),
        ),
      ],
    );
  }

  /// Countdown: circular timer showing remaining time.
  Widget _buildCountdown(BuildContext context, ModemRestartCountdown phase) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularCountdownWidget(
            totalSeconds: phase.totalSeconds,
            remainingSeconds: phase.remainingSeconds,
            child: AppText.headlineMedium(
              CircularCountdownWidget.formatTime(phase.remainingSeconds),
            ),
          ),
          AppGap.xxxl(),
          AppText.headlineSmall(loc(context).pnpWaitingModemWaitStartUp),
          AppGap.md(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: AppText.bodyMedium(
              loc(context).pnpWaitingModemDesc,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Checking: spinner with attempt counter.
  Widget _buildChecking(
      BuildContext context, ModemRestartCheckingInternet phase) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: AppLoader(strokeWidth: 6),
          ),
          AppGap.xxxl(),
          AppText.headlineSmall(loc(context).checkingForInternet),
          AppGap.md(),
          AppText.bodySmall('${phase.attemptCount} / ${phase.maxAttempts}'),
        ],
      ),
    );
  }
}
