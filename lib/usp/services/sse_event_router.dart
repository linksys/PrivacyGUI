import 'dart:convert';
import 'dart:ui';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp/models/sse_notification.dart';

import 'usp_bridge_client.dart';

export 'package:privacy_gui/usp/models/sse_notification.dart';

/// Demultiplexes raw [SseEvent] instances from the SSE stream and routes
/// them to registered handlers by `subscription_id`.
///
/// Supports:
/// - Per-subscription handlers (matched by exact subscription_id)
/// - Wildcard handlers (receive ALL notifications regardless of subscription_id)
///
/// Events that are not `notification` type (heartbeat, connected, turbo_channel)
/// are silently ignored — they are handled by [SseConnectionManager].
class SseEventRouter {
  /// subscription_id → list of handlers
  final Map<String, List<SseNotificationHandler>> _handlers = {};

  /// Handlers that receive ALL notifications regardless of subscription_id.
  final List<SseNotificationHandler> _wildcardHandlers = [];

  /// Register a handler for a specific [subscriptionId].
  ///
  /// Returns a [VoidCallback] that removes the handler when called.
  VoidCallback addHandler(
      String subscriptionId, SseNotificationHandler handler) {
    _handlers.putIfAbsent(subscriptionId, () => []).add(handler);
    return () {
      _handlers[subscriptionId]?.remove(handler);
      if (_handlers[subscriptionId]?.isEmpty ?? false) {
        _handlers.remove(subscriptionId);
      }
    };
  }

  /// Register a handler that receives ALL notifications.
  ///
  /// Returns a [VoidCallback] that removes the handler when called.
  VoidCallback addWildcardHandler(SseNotificationHandler handler) {
    _wildcardHandlers.add(handler);
    return () {
      _wildcardHandlers.remove(handler);
    };
  }

  /// Routes a raw [SseEvent] from the SSE stream to registered handlers.
  ///
  /// Called by [SseConnectionManager.onEvent] for each event.
  void routeEvent(SseEvent event) {
    switch (event.event) {
      case 'notification':
        _routeNotification(event);
        break;
      case 'heartbeat':
      case 'connected':
        // Handled by SseConnectionManager. No routing needed.
        break;
      case 'turbo_channel':
        // Future: route to turbo channel coordinator
        logger.d('[USP][SSE][Router]turbo_channel event: ${event.data}');
        break;
      default:
        logger.d('[USP][SSE][Router]Unknown event type: ${event.event}');
        break;
    }
  }

  void _routeNotification(SseEvent event) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(event.data) as Map<String, dynamic>;
    } catch (e) {
      logger.w('[USP][SSE][Router]Failed to parse notification JSON: $e');
      return;
    }

    final subscriptionId = json['subscription_id'] as String?;
    final type = json['type'] as String?;

    if (subscriptionId == null || type == null) {
      logger
          .w('[USP][SSE][Router]Notification missing subscription_id or type: '
              '${event.data}');
      return;
    }

    final notification = SseNotification(
      subscriptionId: subscriptionId,
      type: type,
      payload: json,
    );

    logger.d('[USP][SSE][Router]Routing: $notification');

    // Route to subscription-specific handlers
    final handlers = _handlers[subscriptionId];
    if (handlers != null) {
      for (final handler in handlers) {
        try {
          handler(notification);
        } catch (e) {
          logger.w('[USP][SSE][Router]Handler error for $subscriptionId: $e');
        }
      }
    }

    // Route to wildcard handlers
    for (final handler in _wildcardHandlers) {
      try {
        handler(notification);
      } catch (e) {
        logger.w('[USP][SSE][Router]Wildcard handler error: $e');
      }
    }
  }

  /// Returns the set of subscription IDs that have registered handlers.
  Set<String> get registeredIds => _handlers.keys.toSet();

  /// Returns the number of wildcard handlers.
  int get wildcardHandlerCount => _wildcardHandlers.length;

  /// Removes all handlers.
  void dispose() {
    _handlers.clear();
    _wildcardHandlers.clear();
  }
}
