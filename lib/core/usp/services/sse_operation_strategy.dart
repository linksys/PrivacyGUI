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

  /// Called when the SSE **stream is opened**, before any event has arrived.
  ///
  /// Local: no-op. The bridge sends a heartbeat every 30s whether or not
  /// anything is subscribed, so a reopened local stream always produces an event
  /// and always reaches [SseConnectionState.connected] — which is where local
  /// does its resubscribe, in [onSseConnected].
  ///
  /// Remote: re-register the existing subscriptions. This exists **because that
  /// last sentence is false for Guardian**, and the difference is not cosmetic:
  /// `connected` is inferred from traffic — `SseConnectionManager._onEvent`
  /// promotes the state on the first non-`_debug` event — and Guardian sends no
  /// heartbeats, so the only traffic on a remote stream is a subscription
  /// notification. A reopened stream carries no subscriptions, therefore no
  /// notifications, therefore never reaches `connected`, therefore never fires
  /// [onSseConnected]. Hanging the remote re-registration off that edge (which
  /// #1497 did at first) produces a hook that cannot run in the one mode it was
  /// written for: after Guardian's ~10-minute close the manager reopens the
  /// stream, settles in `connecting`, and stays there — the dashboard silently
  /// stops updating for the rest of the session and even the banner's
  /// "Reconnect" cannot help, because `tryReconnect()` refuses while
  /// `connecting`.
  ///
  /// Registering here breaks the deadlock in the right direction: the
  /// subscriptions come back, their notifications arrive, and the state reaches
  /// `connected` on its own, so the recovery is automatic rather than something
  /// the support engineer has to notice and press a button for.
  Future<void> onSseStreamOpened(List<SseSubscriptionRecord> existingRecords);

  /// Called when SSE connection is established — that is, when the first real
  /// event has arrived and the state became [SseConnectionState.connected].
  ///
  /// Local: Auto resubscribe existing subscriptions (idempotent). Reachable on
  /// every reconnect, because heartbeats arrive regardless of subscriptions.
  ///
  /// Remote: **no-op, deliberately**, and not for the reason the old comment
  /// gave ("orchestrator controls"). Reaching this edge at all requires a
  /// notification, which requires a live subscription — so by the time it fires
  /// the subscriptions are already working, and re-registering them here would
  /// unsubscribe and re-subscribe a stream that is currently delivering. See
  /// [onSseStreamOpened], which is where the remote arm belongs.
  ///
  /// Both are no-ops on the first connect, where there is nothing registered yet
  /// and the orchestrator is registering.
  Future<void> onSseConnected(List<SseSubscriptionRecord> existingRecords);

  /// Called when SSE disconnects (intentional or not).
  ///
  /// Local: No-op (bridge handles cleanup).
  /// Remote: Fire-and-forget cleanup if intentional disconnect.
  Future<void> onSseDisconnected({required bool intentional});

  /// Disposes resources.
  void dispose();
}
