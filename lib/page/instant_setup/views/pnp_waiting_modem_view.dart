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

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      onBackTap: () => context.go(RoutePath.pnpNoInternetConnection),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: _buildContent(context, ref, phase),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, PnpPhase phase) {
    if (phase is ModemRestartCountdown) {
      return _buildCountdown(context, phase);
    }
    if (phase is ModemRestartCheckingInternet) {
      return _buildChecking(context, phase);
    }
    // Default: plug back in instruction
    return _buildPlugBackIn(context, ref);
  }

  /// Initial: instruct user to plug modem back in.
  Widget _buildPlugBackIn(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Assets.images.modemWaiting.svg(width: 200)),
        AppGap.xxxl(),
        AppText.headlineSmall(loc(context).pnpWaitingModemPlugBack),
        AppGap.md(),
        AppText.bodyMedium(loc(context).pnpWaitingModemDesc),
        AppGap.xxxl(),
        Center(
          child: AppButton(
            label: loc(context).pnpWaitingModemPluggedIn,
            onTap: () =>
                ref.read(pnpProvider.notifier).startModemRestartCountdown(),
          ),
        ),
      ],
    );
  }

  /// Countdown: circular timer showing remaining time.
  Widget _buildCountdown(BuildContext context, ModemRestartCountdown phase) {
    return Column(
      children: [
        AppGap.xxxl(),
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
        AppText.bodyMedium(loc(context).pnpWaitingModemDesc),
      ],
    );
  }

  /// Checking: spinner with attempt counter.
  Widget _buildChecking(
      BuildContext context, ModemRestartCheckingInternet phase) {
    return Column(
      children: [
        AppGap.xxxl(),
        const SizedBox(
          width: 80,
          height: 80,
          child: AppLoader(strokeWidth: 6),
        ),
        AppGap.xxxl(),
        AppText.headlineSmall(loc(context).pnpWaitingModemCheckingInternet),
        AppGap.md(),
        AppText.bodySmall(
          '${phase.attemptCount} / ${phase.maxAttempts}',
        ),
      ],
    );
  }
}
