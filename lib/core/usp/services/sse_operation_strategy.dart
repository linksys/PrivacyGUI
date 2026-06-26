import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

/// Configuration for auth failure handling on 401 responses.
class AuthBehavior {
  /// Whether to attempt reauth and retry on 401.
  final bool shouldRetryOnFailure;

  const AuthBehavior._({required this.shouldRetryOnFailure});

  /// Local mode: attempt WASM reauth and retry once.
  static const local = AuthBehavior._(shouldRetryOnFailure: true);

  /// Remote mode: no retry (temporaryAccessToken cannot refresh).
  static const remote = AuthBehavior._(shouldRetryOnFailure: false);
}

/// Configuration for SSE heartbeat monitoring.
class HeartbeatConfig {
  final bool enabled;
  final Duration timeout;
  final bool authCheckEnabled;

  const HeartbeatConfig({
    required this.enabled,
    required this.timeout,
    required this.authCheckEnabled,
  });

  static const local = HeartbeatConfig(
    enabled: true,
    timeout: Duration(seconds: 45), // 30s bridge interval + 15s grace
    authCheckEnabled: true,
  );

  static const remote = HeartbeatConfig(
    enabled: false,
    timeout: Duration.zero,
    authCheckEnabled: false,
  );
}

/// Subscription definition for registration.
class SubscriptionDef {
  final String subscriptionId;
  final String notifType;
  final String referenceList;

  const SubscriptionDef({
    required this.subscriptionId,
    required this.notifType,
    required this.referenceList,
  });
}

/// Strategy interface for SSE operations.
///
/// Abstracts the differences between local (usp-bridge) and remote (Guardian)
/// SSE subscription management.
abstract class SseOperationStrategy {
  /// Configuration for heartbeat monitoring.
  HeartbeatConfig get heartbeatConfig;

  /// Configuration for auth failure handling.
  AuthBehavior get authBehavior;

  /// Registers subscriptions on the backend.
  ///
  /// Local: Direct register (bridge is idempotent).
  /// Remote: Unregister first → delay → register (to avoid ID conflicts).
  Future<List<SseSubscriptionRecord>> registerSubscriptions(
    List<SubscriptionDef> subscriptions,
  );

  /// Unregisters subscriptions from the backend.
  Future<void> unregisterSubscriptions(List<String> subscriptionIds);

  /// Called when SSE connection is established.
  ///
  /// Local: Auto resubscribe existing subscriptions (idempotent).
  /// Remote: No-op (orchestrator controls registration).
  Future<void> onSseConnected(List<SseSubscriptionRecord> existingRecords);

  /// Called when SSE disconnects (intentional or not).
  ///
  /// Local: No-op (bridge handles cleanup).
  /// Remote: Fire-and-forget cleanup if intentional disconnect.
  Future<void> onSseDisconnected({required bool intentional});

  /// Disposes resources.
  void dispose();
}
