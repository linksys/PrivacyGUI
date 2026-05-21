import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';

/// Which diagnostic tool is active.
enum DiagnosticType { ping, traceroute }

/// Lifecycle of a diagnostic run.
enum DiagnosticStatus { idle, running, completed, error }

/// State for the Network Diagnostics page.
///
/// Unlike most USP pages, this does NOT fetch on build — the user must
/// explicitly trigger a diagnostic run. The notifier starts in [idle] state.
class NetworkDiagnosticsState extends Equatable {
  final DiagnosticType activeTab;
  final DiagnosticStatus status;
  final String host;
  final int pingCount;
  final int maxHops;
  final PingResult? pingResult;
  final TracerouteResult? tracerouteResult;
  final String? errorMessage;

  const NetworkDiagnosticsState({
    this.activeTab = DiagnosticType.ping,
    this.status = DiagnosticStatus.idle,
    this.host = '',
    this.pingCount = 3,
    this.maxHops = 30,
    this.pingResult,
    this.tracerouteResult,
    this.errorMessage,
  });

  NetworkDiagnosticsState copyWith({
    DiagnosticType? activeTab,
    DiagnosticStatus? status,
    String? host,
    int? pingCount,
    int? maxHops,
    PingResult? pingResult,
    bool clearPingResult = false,
    TracerouteResult? tracerouteResult,
    bool clearTracerouteResult = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return NetworkDiagnosticsState(
      activeTab: activeTab ?? this.activeTab,
      status: status ?? this.status,
      host: host ?? this.host,
      pingCount: pingCount ?? this.pingCount,
      maxHops: maxHops ?? this.maxHops,
      pingResult: clearPingResult ? null : (pingResult ?? this.pingResult),
      tracerouteResult: clearTracerouteResult
          ? null
          : (tracerouteResult ?? this.tracerouteResult),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isRunning => status == DiagnosticStatus.running;
  bool get hasResult =>
      status == DiagnosticStatus.completed &&
      (pingResult != null || tracerouteResult != null);

  @override
  List<Object?> get props => [
        activeTab,
        status,
        host,
        pingCount,
        maxHops,
        pingResult,
        tracerouteResult,
        errorMessage,
      ];
}
