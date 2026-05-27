import 'dart:async';

import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';

const _tag = '[TurboSession]:';

/// Turbo channel session states.
enum TurboSessionState {
  /// No active turbo session.
  idle,

  /// Turbo session is active; heartbeat timer is running.
  active,

  /// Session is being released.
  releasing,
}

/// Manages the turbo channel lifecycle for exclusive WebSocket access.
///
/// The turbo channel provides a lock mechanism that:
/// 1. Pauses SSE notifications while active
/// 2. Grants exclusive access for high-throughput operations (firmware upload)
/// 3. Requires periodic heartbeats to maintain the session
///
/// ## Usage
/// ```dart
/// final manager = TurboSessionManager(bridgeClient);
///
/// // Start session before WebSocket operations
/// await manager.start();
///
/// // Perform WebSocket operations...
///
/// // Release when done (always call, even on error)
/// await manager.release();
/// ```
///
/// ## Lifecycle
/// ```
/// idle -> start() -> active (heartbeat every 12s) -> release() -> idle
/// ```
class TurboSessionManager {
  TurboSessionManager(this._bridgeClient);

  final UspBridgeClient _bridgeClient;

  TurboSessionState _state = TurboSessionState.idle;
  String? _sessionId;
  Timer? _heartbeatTimer;

  /// Heartbeat interval. Bridge requires heartbeat within 15s; we use 12s for safety buffer.
  static const heartbeatInterval = Duration(seconds: 12);

  /// Current session state.
  TurboSessionState get state => _state;

  /// Current session ID (null if not active).
  String? get sessionId => _sessionId;

  /// Whether a turbo session is currently active.
  bool get isActive => _state == TurboSessionState.active;

  /// Start a turbo channel session.
  ///
  /// Returns the session ID on success.
  /// Throws if the session cannot be started (e.g., already in use by another client).
  Future<String> start() async {
    if (_state == TurboSessionState.active) {
      logger.w(
          '$_tag start() called while already active (session: $_sessionId)');
      return _sessionId!;
    }

    if (_state == TurboSessionState.releasing) {
      throw StateError('Cannot start turbo session while releasing');
    }

    logger.d('$_tag Starting turbo session...');
    try {
      final response = await _bridgeClient.turboStart();
      final status = response['status'] as String?;

      if (status != 'granted') {
        final error = response['error'] ?? 'Unknown error';
        throw TurboSessionException('Turbo session not granted: $error');
      }

      _sessionId = response['session_id'] as String?;
      _state = TurboSessionState.active;
      // Note: Heartbeat timer disabled — firmware upload completes within
      // turbo max_duration (300s), and heartbeat 403 errors can interrupt upload.
      // Uncomment if longer operations are needed:
      // _startHeartbeatTimer();

      logger.i('$_tag Turbo session started (id: $_sessionId)');
      return _sessionId ?? '';
    } catch (e) {
      logger.e('$_tag Failed to start turbo session: $e');
      _state = TurboSessionState.idle;
      rethrow;
    }
  }

  /// Send a heartbeat to keep the session alive.
  ///
  /// Called automatically by the internal timer. Can also be called manually
  /// if needed (e.g., before a long operation).
  Future<void> heartbeat() async {
    if (_state != TurboSessionState.active) {
      logger.w('$_tag heartbeat() called but session not active');
      return;
    }

    try {
      final response =
          await _bridgeClient.turboHeartbeat(sessionId: _sessionId);
      final status = response['status'] as String?;

      if (status != 'ok') {
        logger.w('$_tag Heartbeat returned unexpected status: $status');
      } else {
        logger.d('$_tag Heartbeat OK');
      }
    } catch (e) {
      logger.e('$_tag Heartbeat failed: $e');
      // Don't change state on heartbeat failure — let the caller decide
      // whether to release or retry
    }
  }

  /// Release the turbo channel session.
  ///
  /// Always call this when done, even if errors occurred during operations.
  /// Safe to call multiple times (idempotent).
  Future<void> release() async {
    if (_state == TurboSessionState.idle) {
      logger.d('$_tag release() called but already idle');
      return;
    }

    if (_state == TurboSessionState.releasing) {
      logger.d('$_tag release() already in progress');
      return;
    }

    _state = TurboSessionState.releasing;
    _stopHeartbeatTimer();

    logger.d('$_tag Releasing turbo session (id: $_sessionId)...');
    try {
      final response = await _bridgeClient.turboRelease(sessionId: _sessionId);
      final status = response['status'] as String?;

      if (status == 'released' || status == 'ok') {
        logger.i('$_tag Turbo session released');
      } else {
        logger.w('$_tag Release returned unexpected status: $status');
      }
    } catch (e) {
      logger.e('$_tag Failed to release turbo session: $e');
      // Continue to idle state even on error — we tried our best
    } finally {
      _sessionId = null;
      _state = TurboSessionState.idle;
    }
  }

  /// Get the current turbo channel status from the bridge.
  Future<TurboStatus> getStatus() async {
    final response = await _bridgeClient.turboStatus();
    return TurboStatus.fromJson(response);
  }

  // ignore: unused_element
  void _startHeartbeatTimer() {
    _stopHeartbeatTimer();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      heartbeat();
    });
    logger.d(
        '$_tag Heartbeat timer started (interval: ${heartbeatInterval.inSeconds}s)');
  }

  void _stopHeartbeatTimer() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Dispose the manager. Releases any active session.
  Future<void> dispose() async {
    _stopHeartbeatTimer();
    if (_state == TurboSessionState.active) {
      await release();
    }
  }
}

/// Current turbo channel status from the bridge.
class TurboStatus {
  const TurboStatus({
    required this.state,
    this.owner,
    this.sessionId,
    this.remainingSeconds,
  });

  /// Turbo state: "IDLE", "IN_USE", etc.
  final String state;

  /// Current owner endpoint ID (if in use).
  final String? owner;

  /// Active session ID (if in use).
  final String? sessionId;

  /// Seconds remaining before auto-release (if in use).
  final int? remainingSeconds;

  /// Whether the turbo channel is currently idle (available).
  bool get isIdle {
    final s = state.toUpperCase();
    return s == 'IDLE' || s == 'AVAILABLE';
  }

  /// Whether the turbo channel is currently in use.
  bool get isInUse => state.toUpperCase() == 'IN_USE';

  factory TurboStatus.fromJson(Map<String, dynamic> json) {
    return TurboStatus(
      state: json['state'] as String? ?? 'UNKNOWN',
      owner: json['owner'] as String?,
      sessionId: json['session_id'] as String?,
      remainingSeconds: json['remaining_seconds'] as int?,
    );
  }

  @override
  String toString() =>
      'TurboStatus(state: $state, owner: $owner, sessionId: $sessionId, remaining: ${remainingSeconds}s)';
}

/// Exception thrown when turbo session operations fail.
class TurboSessionException implements Exception {
  const TurboSessionException(this.message);

  final String message;

  @override
  String toString() => 'TurboSessionException: $message';
}
