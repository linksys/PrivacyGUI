import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'sse_operation_strategy.dart';
import 'usp_bridge_client.dart';

/// SSE connection lifecycle states.
enum SseConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,

  /// Reconnection gave up after [SseConnectionManager._maxRetries] consecutive
  /// failures. Call [SseConnectionManager.tryReconnect] to retry.
  suspended,
}

/// Manages a single SSE connection to the usp-bridge `/api/v1/notifications`
/// endpoint.
///
/// Responsibilities:
/// - Owns the SSE stream lifecycle (connect / disconnect)
/// - Exponential backoff reconnection (1s → 60s cap)
/// - Heartbeat watchdog (45s timeout = 30s bridge heartbeat + 15s grace)
/// - Delegates auth retry to [UspBridgeClient]'s existing 401 handling
///
/// Does NOT manage subscriptions or event routing — those are handled by
/// [SseSubscriptionRegistry] and [SseEventRouter] respectively.
class SseConnectionManager {
  final UspBridgeClient _bridge;
  final HeartbeatConfig _heartbeatConfig;

  SseConnectionManager(
    this._bridge, {
    HeartbeatConfig? heartbeatConfig,
    Duration? initialBackoff,
    Duration? maxBackoff,
    int? maxRetries,
  })  : _heartbeatConfig = heartbeatConfig ?? HeartbeatConfig.local,
        _initialBackoff = initialBackoff ?? _defaultInitialBackoff,
        _maxBackoff = maxBackoff ?? _defaultMaxBackoff,
        _maxRetries = maxRetries ?? _defaultMaxRetries {
    assert(!_initialBackoff.isNegative, 'initialBackoff must not be negative');
    assert(!_maxBackoff.isNegative, 'maxBackoff must not be negative');
    assert(_maxRetries >= 0, 'maxRetries must not be negative');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Configuration
  // ══════════════════════════════════════════════════════════════════════════
  static const Duration _defaultInitialBackoff = Duration(seconds: 1);
  static const Duration _defaultMaxBackoff = Duration(seconds: 60);
  static const int _defaultMaxRetries = 5;
  final Duration _initialBackoff;
  final Duration _maxBackoff;
  final int _maxRetries;

  // ══════════════════════════════════════════════════════════════════════════
  // State
  // ══════════════════════════════════════════════════════════════════════════

  final ValueNotifier<SseConnectionState> connectionState =
      ValueNotifier(SseConnectionState.disconnected);

  StreamSubscription<SseEvent>? _sseSubscription;
  Timer? _heartbeatWatchdog;
  Timer? _reconnectTimer;
  Completer<void>? _connectInProgress;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _intentionalDisconnect = false;

  /// Number of consecutive failed reconnect attempts since the last successful
  /// connection. Resets to 0 on successful connect or intentional disconnect.
  int get reconnectAttempt => _reconnectAttempt;

  /// Guards [_handleStreamEnd] against double-fire when both _onError and
  /// _onDone trigger for the same stream failure. Reset in [connect].
  bool _streamEndHandled = false;

  // ══════════════════════════════════════════════════════════════════════════
  // Callbacks (wired by SseManager)
  // ══════════════════════════════════════════════════════════════════════════

  /// Called for every SSE event (heartbeat, notification, connected, etc.).
  void Function(SseEvent event)? onEvent;

  /// Called when connection transitions to [SseConnectionState.connected].
  /// Used by [SseManager] to trigger [SseSubscriptionRegistry.resubscribeAll].
  VoidCallback? onConnected;

  /// Called when connection transitions away from [SseConnectionState.connected].
  VoidCallback? onDisconnected;

  /// Called on each reconnect failure with the current attempt number.
  /// Used by app-level recovery to detect sustained disconnection earlier
  /// than waiting for [SseConnectionState.suspended].
  void Function(int attempt)? onReconnectFailed;

  // ══════════════════════════════════════════════════════════════════════════
  // Connect / Disconnect
  // ══════════════════════════════════════════════════════════════════════════

  /// Opens the SSE connection. Safe to call multiple times — if a connect
  /// is already in progress, subsequent calls await the existing attempt.
  Future<void> connect() async {
    if (_disposed) return;

    // E2E mock build: the USP bridge is mocked at the browser JS boundary and
    // the real SSE stream cannot establish. Treat the connection as online and
    // skip stream setup entirely, so the connecting/reconnecting/suspended
    // banner never renders and downstream UI reads "online". (P0-1)
    if (BuildConfig.e2eMock) {
      connectionState.value = SseConnectionState.connected;
      return;
    }

    // Lock: if connect is already in progress, await it and return.
    if (_connectInProgress != null) {
      logger.d('[SSE]: connect() already in progress — awaiting');
      await _connectInProgress!.future;
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _connectInProgress = Completer<void>();
    try {
      await _cancelExistingStream();
      _intentionalDisconnect = false;
      _streamEndHandled = false;
      connectionState.value = SseConnectionState.connecting;

      logger.d('[SSE]: Connecting...');

      final stream = _bridge.notifications();
      _sseSubscription = stream.listen(
        _onEvent,
        onError: _onError,
        onDone: _onDone,
      );
      _connectInProgress!.complete();
    } catch (e) {
      logger.w('[SSE]: Failed to open stream: $e');
      if (!_connectInProgress!.isCompleted) {
        _connectInProgress!.completeError(e);
      }
      _scheduleReconnect();
    } finally {
      _connectInProgress = null;
    }
  }

  /// Intentionally disconnects and stops reconnection attempts.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _cancelExistingStream();
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    _reconnectAttempt = 0;

    if (connectionState.value == SseConnectionState.connected) {
      onDisconnected?.call();
    }
    connectionState.value = SseConnectionState.disconnected;
    logger.d('[SSE]: Disconnected (intentional)');
  }

  /// Attempts to reconnect from [SseConnectionState.suspended] or
  /// non-intentional [SseConnectionState.disconnected].
  ///
  /// Returns `true` if a reconnect attempt was started.
  Future<bool> tryReconnect() async {
    if (_disposed || _intentionalDisconnect) return false;
    final state = connectionState.value;
    if (state == SseConnectionState.connected ||
        state == SseConnectionState.connecting ||
        state == SseConnectionState.reconnecting) {
      return false;
    }
    logger.d('[SSE]: Manual reconnect requested (was: ${state.name})');
    _reconnectAttempt = 0;
    await connect();
    return true;
  }

  /// Releases all resources. Call on app shutdown / logout.
  void dispose() {
    _disposed = true;
    _intentionalDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    connectionState.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Event Handling
  // ══════════════════════════════════════════════════════════════════════════

  void _onEvent(SseEvent event) {
    // Skip debug events from UspBridgeClient internal diagnostics FIRST —
    // these are synthetic events emitted before the Fetch returns and must
    // NOT trigger a connected transition or subscription re-registration.
    // Skip synthetic _debug events — they are for development diagnostics only
    if (event.event == '_debug') return;

    // Reset heartbeat watchdog on real events only
    _resetHeartbeatWatchdog();

    // Transition to connected on first real event (heartbeat, notification)
    if (connectionState.value != SseConnectionState.connected) {
      connectionState.value = SseConnectionState.connected;
      _reconnectAttempt = 0;
      logger.d('[SSE]: Connected (event: ${event.event})');
      onConnected?.call();
    }

    // Forward to SseEventRouter via callback
    onEvent?.call(event);
  }

  void _onError(Object error) {
    logger.w('[SSE]: Stream error: $error');
    _handleStreamEnd();
  }

  void _onDone() {
    logger.d('[SSE]: Stream done (server closed connection)');
    _handleStreamEnd();
  }

  void _handleStreamEnd() {
    // Guard: _onError and _onDone can both fire for the same stream failure
    // (e.g. controller.addError() + controller.close() on 429). Only handle
    // the first call; subsequent calls for the same connection are no-ops.
    if (_streamEndHandled) return;
    _streamEndHandled = true;

    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;

    if (connectionState.value == SseConnectionState.connected) {
      onDisconnected?.call();
    }

    if (!_intentionalDisconnect && !_disposed) {
      _scheduleReconnect();
    } else {
      connectionState.value = SseConnectionState.disconnected;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Heartbeat Watchdog
  // ══════════════════════════════════════════════════════════════════════════

  void _resetHeartbeatWatchdog() {
    _heartbeatWatchdog?.cancel();

    // Skip watchdog if heartbeat monitoring is disabled (e.g., Remote mode)
    if (!_heartbeatConfig.enabled) return;

    final timeout = _heartbeatConfig.timeout;
    _heartbeatWatchdog = Timer(timeout, () {
      logger.w('[SSE]: Heartbeat timeout (${timeout.inSeconds}s) '
          '— connection may be stale');
      _sseSubscription?.cancel();
      _handleStreamEnd();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Reconnection with Exponential Backoff
  // ══════════════════════════════════════════════════════════════════════════

  Duration get _nextBackoff {
    final exponent = _reconnectAttempt.clamp(0, 6);
    final delay = _initialBackoff * pow(2, exponent);
    return delay > _maxBackoff ? _maxBackoff : delay;
  }

  void _scheduleReconnect() {
    if (_disposed || _intentionalDisconnect) return;

    // Cancel any existing reconnect timer to prevent timer accumulation.
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    _reconnectAttempt++;
    onReconnectFailed?.call(_reconnectAttempt);

    // Callback may have triggered disconnect(); bail out if so.
    if (_disposed || _intentionalDisconnect) return;

    if (_reconnectAttempt > _maxRetries) {
      connectionState.value = SseConnectionState.suspended;
      logger.w('[SSE]: Max retries ($_maxRetries) reached — suspended. '
          'Call tryReconnect() or wait for lifecycle resume.');
      return;
    }

    connectionState.value = SseConnectionState.reconnecting;

    final delay = _nextBackoff;
    logger.d('[SSE]: Reconnecting in ${delay.inSeconds}s '
        '(attempt #$_reconnectAttempt/$_maxRetries)');

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (!_disposed && !_intentionalDisconnect && _connectInProgress == null) {
        connect();
      }
    });
  }

  Future<void> _cancelExistingStream() async {
    await _sseSubscription?.cancel();
    _sseSubscription = null;
  }
}
