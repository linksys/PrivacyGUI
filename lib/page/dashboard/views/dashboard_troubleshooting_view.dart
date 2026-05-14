import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_troubleshooting_state.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_troubleshooting_notifier.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Dashboard troubleshooting view when internet is unavailable.
///
/// Reuses the same UI structure as [PnpNoInternetView] but:
/// - Uses separate [DashboardTroubleshootingNotifier] state
/// - Returns to Dashboard on completion (not PnP wizard)
/// - Has a "Back to Dashboard" option
class DashboardTroubleshootingView extends ConsumerWidget {
  const DashboardTroubleshootingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardTroubleshootingProvider);

    // Listen for internet restoration → auto-navigate back to dashboard.
    ref.listen(dashboardTroubleshootingProvider, (prev, next) {
      if (next.step == TroubleshootingStep.idle &&
          prev?.step != TroubleshootingStep.idle) {
        context.goNamed(RouteNamed.uspDashboard);
      }
    });

    return switch (state.step) {
      TroubleshootingStep.idle => _buildLoading(context),
      TroubleshootingStep.noInternet => _buildNoInternetHub(context, ref, state),
      TroubleshootingStep.modemCountdown =>
        _buildModemCountdown(context, ref, state),
      TroubleshootingStep.checkingInternet =>
        _buildCheckingInternet(context, ref, state),
      TroubleshootingStep.ispSaving => _buildSavingIsp(context),
    };
  }

  Widget _buildLoading(BuildContext context) {
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      child: (context, constraints) => const Center(child: AppLoader()),
    );
  }

  Widget _buildNoInternetHub(
    BuildContext context,
    WidgetRef ref,
    DashboardTroubleshootingState state,
  ) {
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: state.ssid ?? loc(context).pnpUnplugModemTitle,
      scrollable: true,
      onBackTap: () => _returnToDashboard(context, ref),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Assets.images.noInternetConnection.svg(width: 200)),
            AppGap.lg(),
            AppText.headlineSmall(loc(context).pnpErrorForStaticIpAndDhcp),
            AppGap.xxxl(),

            // Option 1: Restart modem
            AppCard(
              child: InkWell(
                onTap: () => context.goNamed(RouteNamed.pnpUnplugModem),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      AppIcon.font(Icons.power_settings_new),
                      AppGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.titleSmall(
                              loc(context).pnpNoInternetConnectionRestartModem,
                            ),
                            AppGap.xs(),
                            AppText.bodySmall(
                              loc(context)
                                  .pnpNoInternetConnectionRestartModemDesc,
                            ),
                          ],
                        ),
                      ),
                      AppIcon.font(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            AppGap.lg(),

            // Option 2: Enter ISP settings
            AppCard(
              child: InkWell(
                onTap: () => context.goNamed(RouteNamed.pnpIspTypeSelection),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      AppIcon.font(Icons.settings_ethernet),
                      AppGap.md(),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.titleSmall(
                              loc(context).pnpNoInternetConnectionEnterISP,
                            ),
                            AppGap.xs(),
                            AppText.bodySmall(
                              loc(context).pnpNoInternetConnectionEnterISPDesc,
                            ),
                          ],
                        ),
                      ),
                      AppIcon.font(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            AppGap.xxxl(),

            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton.text(
                  label: loc(context).tryAgain,
                  onTap: () => ref
                      .read(dashboardTroubleshootingProvider.notifier)
                      .retryInternetCheck(),
                ),
                AppGap.lg(),
                AppButton.text(
                  label: loc(context).cancel,
                  onTap: () => _returnToDashboard(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModemCountdown(
    BuildContext context,
    WidgetRef ref,
    DashboardTroubleshootingState state,
  ) {
    final remaining = state.countdownSeconds ?? 0;
    final total = state.totalSeconds ?? 150;
    final progress = (total - remaining) / total;

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: loc(context).pnpWaitingModemTitle,
      scrollable: true,
      onBackTap: () => _returnToDashboard(context, ref),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                    ),
                    Center(
                      child: AppText.displaySmall(
                        '$remaining',
                      ),
                    ),
                  ],
                ),
              ),
              AppGap.xxxl(),
              AppText.bodyMedium(
                loc(context).pnpWaitingModemDesc,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckingInternet(
    BuildContext context,
    WidgetRef ref,
    DashboardTroubleshootingState state,
  ) {
    final attempt = state.attemptCount ?? 0;
    final max = state.maxAttempts ?? 30;

    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.back,
      title: loc(context).pnpWaitingModemTitle,
      scrollable: true,
      onBackTap: () => _returnToDashboard(context, ref),
      child: (context, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLoader(),
              AppGap.xl(),
              AppText.bodyMedium(
                loc(context).pnpWaitingModemCheckingInternet,
                textAlign: TextAlign.center,
              ),
              AppGap.sm(),
              AppText.bodySmall(
                '$attempt / $max',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavingIsp(BuildContext context) {
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      child: (context, constraints) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(),
            AppGap.xl(),
            AppText.bodyMedium(
              loc(context).save,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _returnToDashboard(BuildContext context, WidgetRef ref) {
    ref.read(dashboardTroubleshootingProvider.notifier).dismiss();
    context.goNamed(RouteNamed.uspDashboard);
  }
}
