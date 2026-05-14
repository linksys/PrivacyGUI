import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/dashboard/models/dashboard_troubleshooting_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_service.dart';

final dashboardTroubleshootingProvider = NotifierProvider<
    DashboardTroubleshootingNotifier, DashboardTroubleshootingState>(
  DashboardTroubleshootingNotifier.new,
);

/// Notifier for Dashboard troubleshooting flow.
///
/// Reuses [PnpService] for USP operations but has a simpler lifecycle:
/// - Completion returns to Dashboard (not PnP wizard)
/// - No WiFi configuration step
class DashboardTroubleshootingNotifier
    extends Notifier<DashboardTroubleshootingState> {
  PnpService get _svc => ref.read(pnpServiceProvider);

  @override
  DashboardTroubleshootingState build() =>
      const DashboardTroubleshootingState();

  /// Start troubleshooting (called when user taps offline banner).
  Future<void> startTroubleshooting() async {
    logger.i('[Troubleshoot] Starting from Dashboard');
    final ssid = await _svc.fetchCurrentSsid();
    state = DashboardTroubleshootingState(
      step: TroubleshootingStep.noInternet,
      ssid: ssid,
    );
  }

  /// Retry internet check.
  /// Returns true if internet is now available, false otherwise.
  Future<bool> retryInternetCheck() async {
    logger.d('[Troubleshoot] Retrying internet check');
    final hasInternet = await _svc.checkInternetConnected();
    if (hasInternet) {
      logger.i('[Troubleshoot] Internet restored');
      state = const DashboardTroubleshootingState(
        step: TroubleshootingStep.idle,
      );
      return true;
    }
    return false;
  }

  /// Start modem restart countdown (150s → 0s).
  Future<void> startModemRestartCountdown() async {
    logger.i('[Troubleshoot] Starting modem restart countdown');
    const total = 150;
    for (int s = total; s >= 0; s--) {
      if (state.step != TroubleshootingStep.modemCountdown && s < total) {
        logger.d('[Troubleshoot] Countdown cancelled (step changed)');
        return;
      }
      state = state.copyWith(
        step: TroubleshootingStep.modemCountdown,
        countdownSeconds: s,
        totalSeconds: total,
      );
      if (s > 0) await Future.delayed(const Duration(seconds: 1));
    }
    await _checkInternetAfterModem();
  }

  Future<void> _checkInternetAfterModem() async {
    const maxAttempts = 30;
    logger.i('[Troubleshoot] Checking internet after modem restart');
    for (int i = 1; i <= maxAttempts; i++) {
      state = state.copyWith(
        step: TroubleshootingStep.checkingInternet,
        attemptCount: i,
        maxAttempts: maxAttempts,
      );
      await Future.delayed(const Duration(seconds: 5));
      try {
        final hasInternet = await _svc.checkInternetConnected();
        if (hasInternet) {
          logger.i('[Troubleshoot] Internet restored after modem restart');
          state = const DashboardTroubleshootingState(
            step: TroubleshootingStep.idle,
          );
          return;
        }
      } catch (e) {
        logger.d('[Troubleshoot] Check attempt $i failed: $e');
      }
    }
    logger.w(
        '[Troubleshoot] Internet still unavailable after $maxAttempts attempts');
    state = state.copyWith(step: TroubleshootingStep.noInternet);
  }

  /// Save ISP settings with progress indication.
  Future<void> saveIspWithProgress(PnpIspConfig config) async {
    logger.i('[Troubleshoot] Saving ISP settings: ${config.type}');
    try {
      state = state.copyWith(step: TroubleshootingStep.ispSaving);

      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.saveIspSettings(config);
      });

      await Future.delayed(const Duration(seconds: 5));

      final hasInternet = await _svc.checkInternetConnected();
      if (hasInternet) {
        logger.i('[Troubleshoot] Internet restored after ISP settings');
        state = const DashboardTroubleshootingState(
          step: TroubleshootingStep.idle,
        );
      } else {
        logger.w('[Troubleshoot] Internet still unavailable after ISP save');
        state = state.copyWith(step: TroubleshootingStep.noInternet);
      }
    } catch (e) {
      logger.e('[Troubleshoot] ISP save failed: $e');
      state = state.copyWith(
        step: TroubleshootingStep.noInternet,
        errorMessage: '$e',
      );
    }
  }

  /// Dismiss troubleshooter and return to idle.
  void dismiss() {
    logger.d('[Troubleshoot] Dismissed');
    state = const DashboardTroubleshootingState(step: TroubleshootingStep.idle);
  }
}
