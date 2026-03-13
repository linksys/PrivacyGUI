import 'dart:async';
import 'dart:ui';

import 'package:privacy_gui/core/utils/logger.dart';

import 'sse_connection_manager.dart';
import 'sse_event_router.dart';
import 'sse_subscription_registry.dart';
import 'usp_bridge_client.dart';
import 'usp_service.dart';

/// Facade that composes [SseConnectionManager], [SseSubscriptionRegistry],
/// and [SseEventRouter] into a single entry point.
///
/// This is the primary class that Riverpod providers interact with.
///
/// Usage:
/// ```dart
/// final manager = SseManager(usp: usp, bridge: bridge);
/// await manager.connect();
///
/// // Register a subscription with handler
/// final cleanup = await manager.subscribe(
///   subscriptionId: 'wifi-ssid-valuechange',
///   notifType: 'ValueChange',
///   referenceList: 'Device.WiFi.SSID.',
///   onNotification: (notification) { ... },
/// );
///
/// // Later: cleanup removes handler AND unregisters subscription
/// await cleanup();
///
/// // Shutdown
/// await manager.dispose();
/// ```
class SseManager {
  final UspService _usp;
  final SseConnectionManager connection;
  final SseSubscriptionRegistry registry;
  final SseEventRouter router;

  SseManager({
    required UspService usp,
    required UspBridgeClient bridge,
  })  : _usp = usp,
        connection = SseConnectionManager(bridge),
        registry = SseSubscriptionRegistry(usp, bridge),
        router = SseEventRouter() {
    // Wire connection events to router
    connection.onEvent = router.routeEvent;

    // Wire reconnection to bridge-only re-registration
    connection.onConnected = () {
      logger.d('[SseManager] Connected — re-registering subscriptions on bridge');
      registry.resubscribeAll();
    };

    connection.onDisconnected = () {
      logger.d('[SseManager] Disconnected');
    };

    // Inject SSE delegate so codegen subscribe() routes through SSE
    _usp.onSseSubscribe = _handleSseSubscribe;
  }

  /// Registers a subscription and adds a notification handler in one call.
  ///
  /// Returns an async cleanup function that:
  /// 1. Removes the handler from the router
  /// 2. Unregisters the subscription from both OBUSPA and bridge
  ///
  /// This is the primary API for consumers.
  Future<Future<void> Function()> subscribe({
    required String subscriptionId,
    required String notifType,
    required String referenceList,
    required SseNotificationHandler onNotification,
  }) async {
    // Register on both OBUSPA + bridge layers
    await registry.register(
      subscriptionId: subscriptionId,
      notifType: notifType,
      referenceList: referenceList,
    );

    // Add handler to event router
    final removeHandler = router.addHandler(subscriptionId, onNotification);

    // Return combined cleanup
    return () async {
      removeHandler();
      await registry.unregister(subscriptionId);
    };
  }

  /// Adds a handler that receives ALL notifications regardless of
  /// subscription_id. Useful for invalidation signals.
  ///
  /// Returns a [VoidCallback] that removes the handler.
  VoidCallback addWildcardHandler(SseNotificationHandler handler) {
    return router.addWildcardHandler(handler);
  }

  /// SSE delegate implementation injected into [UspService].
  ///
  /// Uses wildcard handler + path prefix matching because the CPE delivers
  /// events using its own internal subscription_id (e.g., "cpe-5"), not the
  /// client-assigned one.
  Future<({void Function() removeHandler, Future<void> Function() unregister})>
      _handleSseSubscribe({
    required String subscriptionId,
    required String notifType,
    required String referenceList,
    required void Function() onNotification,
  }) async {
    // Register OBUSPA + bridge subscription
    await registry.register(
      subscriptionId: subscriptionId,
      notifType: notifType,
      referenceList: referenceList,
    );

    // Wildcard handler: match by type + path prefix
    final removeHandler = router.addWildcardHandler((notification) {
      if (notification.type != notifType) return;
      final path = _extractNotifPath(notification);
      if (path != null && path.startsWith(referenceList)) {
        onNotification();
      }
    });

    return (
      removeHandler: removeHandler,
      unregister: () => registry.unregister(subscriptionId),
    );
  }

  /// Extracts the TR-181 path from a notification for delegate matching.
  static String? _extractNotifPath(SseNotification notification) {
    final payload = notification.payload;
    switch (notification.type) {
      case 'ValueChange':
        return (payload['value_change'] as Map<String, dynamic>?)
            ?['param_path'] as String?;
      case 'ObjectCreation':
        return (payload['obj_creation'] as Map<String, dynamic>?)
            ?['obj_path'] as String?;
      case 'ObjectDeletion':
        return (payload['obj_deletion'] as Map<String, dynamic>?)
            ?['obj_path'] as String?;
      default:
        return null;
    }
  }

  /// Starts the SSE connection.
  Future<void> connect() => connection.connect();

  /// Disconnects SSE (intentional, stops reconnection).
  Future<void> disconnect() => connection.disconnect();

  /// Whether the SSE connection is currently active.
  bool get isConnected =>
      connection.connectionState.value == SseConnectionState.connected;

  /// Clean shutdown: disconnect SSE, unregister all subscriptions, dispose.
  Future<void> dispose() async {
    _usp.onSseSubscribe = null;
    await connection.disconnect();
    await registry.unregisterAll();
    router.dispose();
    connection.dispose();
  }
}
