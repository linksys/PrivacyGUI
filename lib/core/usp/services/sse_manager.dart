import 'dart:async';
import 'dart:ui';

import 'package:privacy_gui/core/utils/logger.dart';

import 'sse_connection_manager.dart';
import 'sse_event_router.dart';
import 'sse_subscription_registry.dart';
import 'sse_unload_handler.dart';
import 'usp_bridge_client.dart';
import 'usp_client.dart';

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
  final UspClient _usp;
  final UspBridgeClient _bridge;
  final SseConnectionManager connection;
  final SseSubscriptionRegistry registry;
  final SseEventRouter router;
  final SseUnloadHandler _unloadHandler = SseUnloadHandler();
  List<(String id, String notifType, String referenceList)> _coreSubscriptions =
      [];
  bool _coreSubsDeferred = false;

  /// Delegate for proactive auth check on heartbeat. Set by provider layer
  /// to wire [UspAuthCoordinator.ensureAuth].
  Future<void> Function()? onHeartbeatAuth;

  SseManager({
    required UspClient usp,
    required UspBridgeClient bridge,
  })  : _usp = usp,
        _bridge = bridge,
        connection = SseConnectionManager(bridge),
        registry = SseSubscriptionRegistry(bridge),
        router = SseEventRouter() {
    // Wire connection events to router
    connection.onEvent = router.routeEvent;

    // Wire heartbeat → proactive auth check (fire-and-forget)
    router.onHeartbeat = () {
      final authCheck = onHeartbeatAuth;
      if (authCheck != null) {
        authCheck().catchError((e) {
          logger.w('[USP][SSE]Heartbeat auth check error: $e');
        });
      }
    };

    // On connect (first or reconnect): register/re-register subscriptions.
    // First connect: registers core subscriptions set via setCoreSubscriptions().
    // Reconnect: re-registers existing subscriptions on the bridge.
    connection.onConnected = () {
      logger.d('[USP][SSE]Connected — registering/re-registering '
          'subscriptions on bridge');
      _registerOrResubscribe();
    };

    connection.onDisconnected = () {
      logger.d('[USP][SSE]Disconnected');
    };

    // Inject SSE delegate so codegen subscribe() routes through SSE
    _usp.onSseSubscribe = _handleSseSubscribe;

    // Force SSE reconnect after full re-login to ensure the new session's
    // subscription routing is active (prevents silent notification failure).
    _usp.onTokenRefreshed = () {
      logger.d('[USP][SSE]Token refreshed (full re-login) '
          '— forcing SSE reconnect');
      connection.disconnect().then((_) => connection.connect());
    };

    // Register browser unload handler to abort SSE on page refresh/close.
    // abortSse() is synchronous — critical because `beforeunload` does NOT
    // wait for async operations. disconnect() is best-effort async cleanup.
    _unloadHandler.onUnload = () {
      logger.d('[USP][SSE]Page unload — aborting SSE');
      _bridge.abortSse();
      connection.disconnect();
    };
    _unloadHandler.register();
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

  /// SSE delegate implementation injected into [UspClient].
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
        return (payload['value_change'] as Map<String, dynamic>?)?['param_path']
            as String?;
      case 'ObjectCreation':
        return (payload['obj_creation'] as Map<String, dynamic>?)?['obj_path']
            as String?;
      case 'ObjectDeletion':
        return (payload['obj_deletion'] as Map<String, dynamic>?)?['obj_path']
            as String?;
      default:
        return null;
    }
  }

  /// Sets the core subscriptions to register when SSE first connects.
  ///
  /// Called once from [sseBootstrapProvider]. Subscriptions are registered
  /// from the [onConnected] callback after the first heartbeat, rather than
  /// during bootstrap, to reduce the HTTP request burst on the bridge.
  void setCoreSubscriptions(List<(String, String, String)> subscriptions) {
    _coreSubscriptions = subscriptions;
  }

  /// Handles subscription registration on SSE connect/reconnect.
  ///
  /// - Reconnect (registry has entries): re-registers immediately via bridge
  /// - First connect (registry empty): registers core subscriptions directly.
  ///   [onConnected] fires on the first real heartbeat (~30s after stream
  ///   opens), by which time dashboard HTTP requests have already completed —
  ///   no HTTP/1.1 connection pool contention.
  Future<void> _registerOrResubscribe() async {
    if (registry.activeIds.isNotEmpty) {
      // Reconnect path: re-register existing subscriptions on bridge
      await registry.resubscribeAll();
    } else if (_coreSubscriptions.isNotEmpty) {
      // First connect: register directly (no contention at heartbeat time)
      await registerDeferredSubscriptions(force: true);
    }
  }

  /// Registers core subscriptions on the bridge.
  ///
  /// In normal flow, called from [_registerOrResubscribe] when SSE first
  /// connects (on heartbeat). In the post-reload path, the orchestrator
  /// calls this with [force] = true to register before onConnected fires.
  ///
  /// Pass [force] = true to skip the deferral check and register immediately.
  Future<void> registerDeferredSubscriptions({bool force = false}) async {
    if (!force && !_coreSubsDeferred) return;
    _coreSubsDeferred = false;

    for (final (id, notifType, referenceList) in _coreSubscriptions) {
      try {
        await registry.register(
          subscriptionId: id,
          notifType: notifType,
          referenceList: referenceList,
        );
        // Small breathing room for embedded router between requests
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        logger.w('[USP][SSE]Failed to register core sub $id: $e');
      }
    }
    logger.d('[USP][SSE]Registered ${registry.activeIds.length} '
        'core subscriptions (deferred)');
  }

  /// Starts the SSE connection.
  Future<void> connect() => connection.connect();

  /// Disconnects SSE (intentional, stops reconnection).
  Future<void> disconnect() => connection.disconnect();

  /// Attempts to reconnect from suspended/disconnected state.
  /// Returns `true` if a reconnect attempt was started.
  Future<bool> tryReconnect() => connection.tryReconnect();

  /// Whether the SSE connection is currently active.
  bool get isConnected =>
      connection.connectionState.value == SseConnectionState.connected;

  /// Clean shutdown: disconnect SSE, unregister all subscriptions, dispose.
  Future<void> dispose() async {
    _unloadHandler.unregister();
    _usp.onSseSubscribe = null;
    _usp.onTokenRefreshed = null;
    router.onHeartbeat = null;
    onHeartbeatAuth = null;
    // Synchronous abort first — critical for hot restart where async may not complete.
    _bridge.abortSse();
    await connection.disconnect();
    await registry.unregisterAll();
    router.dispose();
    connection.dispose();
  }
}
