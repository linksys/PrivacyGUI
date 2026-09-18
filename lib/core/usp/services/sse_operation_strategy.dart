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

  /// **In force today, and deliberately the watchdog-off one.**
  ///
  /// Guardian's own spec says the RA stream sends a `heartbeat` every 20 s, and
  /// [remoteWithHeartbeat] below is that config, written and tested. It is not wired
  /// up, because a spec is not a deployment: if that environment does not actually
  /// send heartbeats, a 35-second watchdog declares the stream dead every 35 seconds
  /// and pushes the app into recovery — strictly worse than having no watchdog at all.
  ///
  /// Flipping this is a one-word change once #1575's verification item 1 is answered:
  /// name [remoteWithHeartbeat] here. `sse_operation_strategy_test.dart` pins both
  /// values and which one is live, so the flip cannot happen by accident either.
  ///
  /// `authCheckEnabled` stays false in both: the heartbeat auth check refreshes a WASM
  /// session token, and a Guardian `temporaryAccessToken` cannot be refreshed.
  static const remote = HeartbeatConfig(
    enabled: false,
    timeout: Duration.zero,
    authCheckEnabled: false,
  );

  /// What [remote] becomes once the 20-second heartbeat is confirmed on QA (#1577).
  ///
  /// 20 s plus a 15-second grace, the same arithmetic as [local]'s 30 + 15.
  ///
  /// Two consequences of switching it on, one wanted and one to guard against:
  ///
  /// * **Wanted.** `SseConnectionManager.connected` is inferred from traffic (the
  ///   first non-`_debug` event), so with heartbeats arriving a reopened remote stream
  ///   reaches `connected` on its own instead of sitting in `connecting` for the rest
  ///   of the session.
  /// * **To guard against.** Re-registering subscriptions stays on
  ///   `onSseStreamOpened`. Its justification weakens from "the only edge that can
  ///   fire" to "the earlier edge", which is not the same as becoming wrong: with
  ///   heartbeats, `onSseConnected` fires on a stream that is *already delivering*, so
  ///   unregister → register there would tear down live subscriptions. #1474 phase 7
  ///   has the full reasoning, and this is the config change that removes its premise
  ///   without removing its conclusion.
  static const remoteWithHeartbeat = HeartbeatConfig(
    enabled: true,
    timeout: Duration(seconds: 35),
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
