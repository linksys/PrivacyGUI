import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/speed_test/models/speed_test_state.dart';

import 'diagnostic_result.dart';

/// Problem type selected by user at the start of diagnostics.
enum ProblemType {
  /// No internet connection (WAN down, DHCP failure, etc.)
  noInternet,

  /// Internet connected but slow performance.
  slowNetwork,
}

/// Step in the diagnostic flow.
enum DiagnosticStep {
  /// Initial state — no diagnostics in progress.
  idle,

  /// User selects problem type (noInternet or slowNetwork).
  selectProblem,

  // ─── Scenario A: No Internet ───────────────────────────────

  /// Checking WAN interface status.
  checkingWanStatus,

  /// Checking DHCP lease status.
  checkingDhcp,

  /// Pinging default gateway.
  pingGateway,

  /// Pinging DNS servers (8.8.8.8, 1.1.1.1).
  pingDns,

  /// Pinging external host to verify internet.
  pingInternet,

  // ─── Scenario B: Slow Network ──────────────────────────────

  /// Running download/upload speed test.
  runningSpeedTest,

  /// Checking WiFi signal strength and channel.
  checkingWifiSignal,

  /// Checking connected device count and bandwidth usage.
  checkingConnectedDevices,

  /// Running traceroute to identify bottleneck.
  runningTraceroute,

  // ─── Shared ────────────────────────────────────────────────

  /// Analyzing all collected results.
  analyzing,

  /// Displaying findings and recommendations.
  showingResults,

  /// Applying a user-triggered fix action.
  applyingFix,

  /// Diagnostic flow completed.
  completed,
}

/// Recommendation action the user can take.
class Recommendation extends Equatable {
  /// Unique identifier for this recommendation.
  final String id;

  /// Localization key for the recommendation title.
  final String titleKey;

  /// Localization key for the recommendation description.
  final String descriptionKey;

  /// Priority level (lower = more important).
  final int priority;

  /// Optional action callback identifier (e.g., 'renewDhcp', 'restartModem').
  final String? actionId;

  const Recommendation({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    this.priority = 0,
    this.actionId,
  });

  @override
  List<Object?> get props => [id, titleKey, descriptionKey, priority, actionId];
}

/// State for the unified diagnostics feature.
class UnifiedDiagnosticsState extends Equatable {
  /// Current step in the diagnostic flow.
  final DiagnosticStep step;

  /// Problem type selected by user (null if not yet selected).
  final ProblemType? problemType;

  /// Results collected from each diagnostic step.
  final List<DiagnosticStepResult> results;

  /// Speed test results (for slowNetwork scenario).
  final SpeedTestResult? speedTest;

  /// Recommendations based on diagnostic results.
  final List<Recommendation> recommendations;

  /// Error message if a step failed.
  final String? errorMessage;

  /// Progress of current step (0.0–1.0).
  final double? progress;

  const UnifiedDiagnosticsState({
    this.step = DiagnosticStep.idle,
    this.problemType,
    this.results = const [],
    this.speedTest,
    this.recommendations = const [],
    this.errorMessage,
    this.progress,
  });

  /// Whether any diagnostic is in progress.
  bool get isRunning =>
      step != DiagnosticStep.idle &&
      step != DiagnosticStep.selectProblem &&
      step != DiagnosticStep.showingResults &&
      step != DiagnosticStep.completed;

  /// Whether we're in the "no internet" diagnostic flow.
  bool get isNoInternetFlow => problemType == ProblemType.noInternet;

  /// Whether we're in the "slow network" diagnostic flow.
  bool get isSlowNetworkFlow => problemType == ProblemType.slowNetwork;

  UnifiedDiagnosticsState copyWith({
    DiagnosticStep? step,
    ProblemType? problemType,
    List<DiagnosticStepResult>? results,
    SpeedTestResult? speedTest,
    List<Recommendation>? recommendations,
    String? errorMessage,
    double? progress,
    bool clearError = false,
    bool clearSpeedTest = false,
  }) {
    return UnifiedDiagnosticsState(
      step: step ?? this.step,
      problemType: problemType ?? this.problemType,
      results: results ?? this.results,
      speedTest: clearSpeedTest ? null : (speedTest ?? this.speedTest),
      recommendations: recommendations ?? this.recommendations,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
        step,
        problemType,
        results,
        speedTest,
        recommendations,
        errorMessage,
        progress,
      ];
}
