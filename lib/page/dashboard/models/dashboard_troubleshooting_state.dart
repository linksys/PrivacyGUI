import 'package:equatable/equatable.dart';

/// Troubleshooting step when accessed from Dashboard (not PnP wizard).
enum TroubleshootingStep {
  /// Idle — no troubleshooting in progress.
  idle,

  /// No internet detected.
  noInternet,

  /// Modem restart countdown (150s → 0s).
  modemCountdown,

  /// Checking internet after modem restart.
  checkingInternet,

  /// Saving ISP settings.
  ispSaving,
}

/// State for Dashboard troubleshooting flow.
///
/// Separate from [PnpState] because:
/// 1. Completion returns to Dashboard, not PnP wizard
/// 2. No WiFi configuration step
/// 3. Simpler lifecycle
class DashboardTroubleshootingState extends Equatable {
  final TroubleshootingStep step;
  final int? countdownSeconds;
  final int? totalSeconds;
  final int? attemptCount;
  final int? maxAttempts;
  final String? ssid;
  final String? errorMessage;

  const DashboardTroubleshootingState({
    this.step = TroubleshootingStep.idle,
    this.countdownSeconds,
    this.totalSeconds,
    this.attemptCount,
    this.maxAttempts,
    this.ssid,
    this.errorMessage,
  });

  DashboardTroubleshootingState copyWith({
    TroubleshootingStep? step,
    int? countdownSeconds,
    int? totalSeconds,
    int? attemptCount,
    int? maxAttempts,
    String? ssid,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardTroubleshootingState(
      step: step ?? this.step,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      attemptCount: attemptCount ?? this.attemptCount,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      ssid: ssid ?? this.ssid,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        step,
        countdownSeconds,
        totalSeconds,
        attemptCount,
        maxAttempts,
        ssid,
        errorMessage,
      ];
}
