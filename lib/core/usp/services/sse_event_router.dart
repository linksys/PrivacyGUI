import 'dart:convert';
import 'dart:ui';

import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_notification.dart';

import 'usp_bridge_client.dart';

export 'package:privacy_gui/core/usp/models/sse_notification.dart';

/// Demultiplexes raw [SseEvent] instances from the SSE stream and hands every
/// notification to every handler.
///
/// Not by `subscription_id`, which is not a key to hear by (see
/// [SseNotification.subscriptionId]): a handler picks its own by type and
/// path — [SseNotification.isFor], which `SseManager.subscribe` applies for
/// its callers.
///
/// Events that are not `notification` type (heartbeat, connected)
/// are silently ignored — they are handled by [SseConnectionManager].
class SseEventRouter {
  /// Called on every SSE heartbeat event. Set by [SseManager] to trigger
  /// proactive token refresh via [UspAuthCoordinator.ensureAuth].
  VoidCallback? onHeartbeat;

  /// Handlers that receive ALL notifications regardless of subscription_id.
  final List<SseNotificationHandler> _wildcardHandlers = [];

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
        onHeartbeat?.call();
        break;
      case 'connected':
        break;
      default:
        logger.d('[SSE]: Unknown event type: ${event.event}');
        break;
    }
  }

  void _routeNotification(SseEvent event) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(event.data) as Map<String, dynamic>;
    } catch (e) {
      logger.w('[SSE]: Failed to parse notification JSON: $e');
      return;
    }

    final subscriptionId = json['subscription_id'] as String?;
    final type = json['type'] as String?;

    if (subscriptionId == null || type == null) {
      logger.w('[SSE]: Notification missing subscription_id or type: '
          '${event.data}');
      return;
    }

    final notification = SseNotification(
      subscriptionId: subscriptionId,
      type: type,
      payload: json,
    );

    logger.t('[SSE]: $subscriptionId ($type)\n'
        '  ${const JsonEncoder.withIndent('  ').convert(json).replaceAll('\n', '\n  ')}');

    // A copy: a handler that removes itself while being notified would
    // otherwise change the list being iterated.
    for (final handler in [..._wildcardHandlers]) {
      try {
        handler(notification);
      } catch (e) {
        logger.w('[SSE]: Wildcard handler error: $e');
      }
    }
  }

  /// Returns the number of wildcard handlers.
  int get wildcardHandlerCount => _wildcardHandlers.length;

  /// Removes all handlers.
  void dispose() {
    onHeartbeat = null;
    _wildcardHandlers.clear();
  }
}
