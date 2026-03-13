import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

import 'usp_bridge_client.dart';

/// SSE connection lifecycle states.
enum SseConnectionState { disconnected, connecting, connected, reconnecting }

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

  SseConnectionManager(this._bridge);

  // ══════════════════════════════════════════════════════════════════════════
  // Configuration
  // ══════════════════════════════════════════════════════════════════════════

  static const Duration _heartbeatTimeout = Duration(seconds: 45);
  static const Duration _initialBackoff = Duration(seconds: 1);
  static const Duration _maxBackoff = Duration(seconds: 60);

  // ══════════════════════════════════════════════════════════════════════════
  // State
  // ══════════════════════════════════════════════════════════════════════════

  final ValueNotifier<SseConnectionState> connectionState =
      ValueNotifier(SseConnectionState.disconnected);

  StreamSubscription<SseEvent>? _sseSubscription;
  Timer? _heartbeatWatchdog;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _intentionalDisconnect = false;

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

  // ══════════════════════════════════════════════════════════════════════════
  // Connect / Disconnect
  // ══════════════════════════════════════════════════════════════════════════

  /// Opens the SSE connection. Safe to call multiple times — disconnects
  /// any existing connection first.
  Future<void> connect() async {
    if (_disposed) return;

    await _cancelExistingStream();
    _intentionalDisconnect = false;
    connectionState.value = SseConnectionState.connecting;

    logger.d('[SSE] Connecting...');

    try {
      final stream = _bridge.notifications();
      _sseSubscription = stream.listen(
        _onEvent,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      logger.w('[SSE] Failed to open stream: $e');
      _scheduleReconnect();
    }
  }

  /// Intentionally disconnects and stops reconnection attempts.
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _cancelExistingStream();
    _heartbeatWatchdog?.cancel();
    _heartbeatWatchdog = null;
    _reconnectAttempt = 0;

    if (connectionState.value == SseConnectionState.connected) {
      onDisconnected?.call();
    }
    connectionState.value = SseConnectionState.disconnected;
    logger.d('[SSE] Disconnected (intentional)');
  }

  /// Releases all resources. Call on app shutdown / logout.
  void dispose() {
    _disposed = true;
    _intentionalDisconnect = true;
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
    // Reset heartbeat watchdog on ANY event (heartbeat, notification, etc.)
    _resetHeartbeatWatchdog();

    // Transition to connected on first real event
    if (connectionState.value != SseConnectionState.connected) {
      final wasDisconnected =
          connectionState.value != SseConnectionState.connected;
      connectionState.value = SseConnectionState.connected;
      _reconnectAttempt = 0;
      logger.d('[SSE] Connected (event: ${event.event})');
      if (wasDisconnected) {
        onConnected?.call();
      }
    }

    // Skip debug events from UspBridgeClient internal diagnostics
    if (event.event == '_debug') {
      logger.d('[SSE] debug: ${event.data}');
      return;
    }

    // Forward to SseEventRouter via callback
    onEvent?.call(event);
  }

  void _onError(Object error) {
    logger.w('[SSE] Stream error: $error');
    _handleStreamEnd();
  }

  void _onDone() {
    logger.d('[SSE] Stream done (server closed connection)');
    _handleStreamEnd();
  }

  void _handleStreamEnd() {
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
    _heartbeatWatchdog = Timer(_heartbeatTimeout, () {
      logger.w('[SSE] Heartbeat timeout (${_heartbeatTimeout.inSeconds}s) '
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

    connectionState.value = SseConnectionState.reconnecting;
    _reconnectAttempt++;

    final delay = _nextBackoff;
    logger.d('[SSE] Reconnecting in ${delay.inSeconds}s '
        '(attempt #$_reconnectAttempt)');

    Timer(delay, () {
      if (!_disposed && !_intentionalDisconnect) {
        connect();
      }
    });
  }

  Future<void> _cancelExistingStream() async {
    await _sseSubscription?.cancel();
    _sseSubscription = null;
  }
}
