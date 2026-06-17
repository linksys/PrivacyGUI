import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/unified_diagnostics/models/speed_test_state.dart';

import 'diagnostic_result.dart';

/// Diagnostic flow type — covers all diagnostic scenarios.
enum DiagnosticFlow {
  /// Internet diagnostics — connectivity + speed test.
  /// Combines the old noInternet and slowNetwork flows.
  internet,

  /// WiFi coverage problems — weak signal in certain areas.
  wifiCoverage,

  /// Mesh backhaul health — node-to-node link quality.
  meshBackhaul,

  /// Specific device has connection or performance issues.
  deviceIssues,

  /// Intermittent connection — on-and-off connectivity.
  intermittent,
}

/// Pre-qualifier result — quick check before showing flow menu.
enum PreQualifierResult {
  /// Internet is working (WAN up + can ping external host).
  internetOk,

  /// WAN is down or has no IP address.
  wanDownNoIp,

  /// WAN is up but DNS resolution fails.
  dnsFailure,

  /// Internet works but latency is high (>500ms).
  internetSlow,
}

/// Step in the diagnostic flow.
enum DiagnosticStep {
  /// Initial state — no diagnostics in progress.
  idle,

  /// Running pre-qualifier check (WAN status + ping).
  preQualifying,

  /// User selects diagnostic flow from menu.
  selectFlow,

  // ─── Scenario A: No Internet ───────────────────────────────

  /// Checking WAN interface status.
  checkingWanStatus,

  /// Checking DHCP lease status.
  checkingDhcp,

  /// Checking DHCP pool capacity / usage.
  checkingDhcpPool,

  /// Pinging default gateway.
  pingGateway,

  /// Pinging DNS servers (8.8.8.8, 1.1.1.1).
  pingDns,

  /// Pinging external host to verify internet.
  pingInternet,

  /// Running DNS lookup (NSLookupDiagnostics) to validate name resolution.
  dnsLookup,

  // ─── Scenario B: Slow Network ──────────────────────────────

  /// Running download/upload speed test.
  runningSpeedTest,

  /// Checking WiFi signal strength and channel.
  checkingWifiSignal,

  /// Checking connected device count and bandwidth usage.
  checkingConnectedDevices,

  /// Running traceroute to identify bottleneck.
  runningTraceroute,

  // ─── Scenario C: Mesh / Backhaul ───────────────────────────

  /// Inspecting mesh node backhaul health (PHY rate, signal, media type).
  checkingMeshBackhaul,

  // ─── Manual Tools ──────────────────────────────────────────

  /// User is using manual ping/traceroute tools.
  manualTools,

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
class RecommendationUIModel extends Equatable {
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

  const RecommendationUIModel({
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

  /// Selected diagnostic flow (null if not yet selected).
  final DiagnosticFlow? flow;

  /// Pre-qualifier result (null if not yet run).
  final PreQualifierResult? preQualifierResult;

  /// Results collected from each diagnostic step.
  final List<DiagnosticStepUIModel> results;

  /// Speed test results (for slowNetwork scenario).
  final SpeedTestResult? speedTest;

  /// Recommendations based on diagnostic results.
  final List<RecommendationUIModel> recommendations;

  /// Error if a step failed.
  final ServiceError? error;

  /// Progress of current step (0.0–1.0).
  final double? progress;

  const UnifiedDiagnosticsState({
    this.step = DiagnosticStep.idle,
    this.flow,
    this.preQualifierResult,
    this.results = const [],
    this.speedTest,
    this.recommendations = const [],
    this.error,
    this.progress,
  });

  /// Whether any diagnostic is in progress.
  bool get isRunning =>
      step != DiagnosticStep.idle &&
      step != DiagnosticStep.selectFlow &&
      step != DiagnosticStep.manualTools &&
      step != DiagnosticStep.showingResults &&
      step != DiagnosticStep.completed;

  /// Whether we're in the combined internet diagnostic flow.
  bool get isInternetFlow => flow == DiagnosticFlow.internet;

  /// Whether pre-qualifier detected a critical issue.
  bool get preQualifierHasCriticalIssue =>
      preQualifierResult == PreQualifierResult.wanDownNoIp ||
      preQualifierResult == PreQualifierResult.dnsFailure;

  UnifiedDiagnosticsState copyWith({
    DiagnosticStep? step,
    DiagnosticFlow? flow,
    PreQualifierResult? preQualifierResult,
    List<DiagnosticStepUIModel>? results,
    SpeedTestResult? speedTest,
    List<RecommendationUIModel>? recommendations,
    ServiceError? error,
    double? progress,
    bool clearError = false,
    bool clearSpeedTest = false,
    bool clearFlow = false,
    bool clearPreQualifier = false,
    bool clearProgress = false,
    bool clearRecommendations = false,
  }) {
    return UnifiedDiagnosticsState(
      step: step ?? this.step,
      flow: clearFlow ? null : (flow ?? this.flow),
      preQualifierResult: clearPreQualifier
          ? null
          : (preQualifierResult ?? this.preQualifierResult),
      results: results ?? this.results,
      speedTest: clearSpeedTest ? null : (speedTest ?? this.speedTest),
      recommendations: clearRecommendations
          ? const []
          : (recommendations ?? this.recommendations),
      error: clearError ? null : (error ?? this.error),
      progress: clearProgress ? null : (progress ?? this.progress),
    );
  }

  @override
  List<Object?> get props => [
        step,
        flow,
        preQualifierResult,
        results,
        speedTest,
        recommendations,
        error,
        progress,
      ];
}
