import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/network_diagnostics_executor.dart';

/// Provider for [DiagnosticsScopeService].
///
/// Returns null if the [NetworkDiagnosticsExecutor] is not available.
final diagnosticsScopeServiceProvider = Provider<DiagnosticsScopeService?>(
  (ref) {
    final executor = ref.watch(networkDiagnosticsExecutorProvider);
    if (executor == null) return null;
    return DiagnosticsScopeService(executor);
  },
);

/// Service layer wrapper for [NetworkDiagnosticsExecutor] scope operations.
///
/// This service handles error mapping for scope acquisition and diagnostic
/// operations, ensuring that providers only receive [ServiceError] types
/// (per Article XIII of the constitution).
///
/// Usage:
/// ```dart
/// final svc = ref.read(diagnosticsScopeServiceProvider);
/// final scope = await svc!.acquireScope();
/// try {
///   final result = await svc.ping(scope, host: '8.8.8.8');
///   // ...
/// } finally {
///   await svc.releaseScope(scope);
/// }
/// ```
class DiagnosticsScopeService {
  final NetworkDiagnosticsExecutor _executor;

  DiagnosticsScopeService(this._executor);

  /// Acquires a diagnostic scope with error handling.
  ///
  /// Throws [ServiceError] on failure (not raw exceptions).
  Future<DiagnosticScope> acquireScope() async {
    try {
      return await _executor.acquireScope();
    } catch (e) {
      if (e is ServiceError || e is TimeoutException) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Releases the given scope. Safe to call even if already released.
  Future<void> releaseScope(DiagnosticScope scope) async {
    if (scope.isReleased) return;
    try {
      await scope.release();
    } catch (e) {
      // Swallow release errors — scope cleanup is best-effort.
    }
  }

  /// Ping a host using the given scope.
  ///
  /// Throws [ServiceError] on failure.
  Future<OperateResult> ping(
    DiagnosticScope scope, {
    required String host,
    int numberOfRepetitions = 3,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await scope.ping(
        host: host,
        numberOfRepetitions: numberOfRepetitions,
        timeout: timeout,
      );
    } catch (e) {
      if (e is ServiceError || e is TimeoutException) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Run traceroute using the given scope.
  ///
  /// Throws [ServiceError] on failure.
  Future<OperateResult> traceRoute(
    DiagnosticScope scope, {
    required String host,
    int? maxHopCount,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    try {
      return await scope.traceRoute(
        host: host,
        maxHopCount: maxHopCount,
        timeout: timeout,
      );
    } catch (e) {
      if (e is ServiceError || e is TimeoutException) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Run NS lookup using the given scope.
  ///
  /// Throws [ServiceError] on failure.
  Future<OperateResult> nsLookup(
    DiagnosticScope scope, {
    required String hostName,
    String? dnsServer,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await scope.nsLookup(
        hostName: hostName,
        dnsServer: dnsServer,
        timeout: timeout,
      );
    } catch (e) {
      if (e is ServiceError || e is TimeoutException) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Run download diagnostic using the given scope.
  ///
  /// Throws [ServiceError] on failure.
  Future<OperateResult> downloadDiagnostic(
    DiagnosticScope scope, {
    required String downloadUrl,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    try {
      return await scope.downloadDiagnostic(
        downloadUrl: downloadUrl,
        timeout: timeout,
      );
    } catch (e) {
      if (e is ServiceError || e is TimeoutException) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }
}
