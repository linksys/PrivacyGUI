import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import 'sse_operation_strategy.dart';
import 'usp_bridge_client.dart';

/// Remote SSE strategy for Guardian proxy.
///
/// Characteristics:
/// - Guardian does NOT allow duplicate subscription IDs (causes conflict)
/// - Must unregister → delay → register
/// - Re-registers existing subscriptions on *re*connect; the first connect is
///   the orchestrator's (see [onSseConnected])
/// - Heartbeat watchdog disabled (Guardian doesn't send heartbeats)
/// - No auth check (temporaryAccessToken cannot refresh)
/// - Uses 'remote-' prefix for subscription IDs to avoid collision with Local
class RemoteSseStrategy implements SseOperationStrategy {
  final UspBridgeClient _bridge;

  /// Prefix for remote subscription IDs to avoid collision with Local mode.
  static const _idPrefix = 'remote-';

  /// Delay between unregister and register to allow Guardian to process.
  static const _unregisterDelay = Duration(milliseconds: 100);

  /// Whether a reconnect re-registration walk is currently running.
  ///
  /// Mirrors `SseManager._registrationInProgress`, which guards the sibling
  /// path — see [onSseStreamOpened] for why the walk needs it.
  bool _reRegistrationInProgress = false;

  RemoteSseStrategy(this._bridge);

  String _toRemoteId(String id) => '$_idPrefix$id';
  bool _isRemoteId(String id) => id.startsWith(_idPrefix);

  @override
  HeartbeatConfig get heartbeatConfig => HeartbeatConfig.remote;

  @override
  AuthBehavior get authBehavior => AuthBehavior.remote;

  @override
  Future<List<SseSubscriptionRecord>> registerSubscriptions(
    List<SubscriptionDef> subscriptions,
  ) async {
    final records = <SseSubscriptionRecord>[];

    for (final sub in subscriptions) {
      final remoteId = _toRemoteId(sub.subscriptionId);
      try {
        logger.d('[SSE]: Registering ${sub.subscriptionId} as $remoteId');

        // Unregister first to avoid ID conflict
        try {
          await _bridge.unsubscribe(subscriptionId: remoteId);
          await Future.delayed(_unregisterDelay);
        } catch (_) {
          // Ignore — subscription may not exist
        }

        await _bridge.subscribe(
          subscriptionId: remoteId,
          path: sub.referenceList,
          notifType: _notifTypeToInt(sub.notifType),
        );

        // Record uses original ID (transparent to Registry/Manager)
        records.add(SseSubscriptionRecord(
          subscriptionId: sub.subscriptionId,
          notifType: sub.notifType,
          referenceList: sub.referenceList,
          createdAt: DateTime.now(),
        ));

        // Breathing room for Guardian between requests
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        logger.w('[SSE]: Failed to register ${sub.subscriptionId}: $e');
      }
    }

    logger.d(
        '[SSE]: Registered ${records.length}/${subscriptions.length} subscriptions');
    return records;
  }

  @override
  Future<void> unregisterSubscriptions(List<String> subscriptionIds) async {
    for (final id in subscriptionIds) {
      final remoteId = _toRemoteId(id);
      try {
        await _bridge.unsubscribe(subscriptionId: remoteId);
        logger.d('[SSE]: Unregistered $id (as $remoteId)');
      } catch (e) {
        logger.w('[SSE]: Failed to unregister $id: $e');
      }
    }
  }

  @override
  Future<void> onSseStreamOpened(
      List<SseSubscriptionRecord> existingRecords) async {
    // Nothing registered yet means this is the first connect, where the
    // orchestrator is the one registering. Every *later* open is a reconnect, and
    // Guardian force-closes the proxied stream at roughly ten minutes, so without
    // this the second stream carries no subscriptions and the dashboard silently
    // stops updating for the rest of the session (#1497 acceptance 7b).
    //
    // Stream-open rather than the `connected` edge, which is where #1497 first
    // put it. `connected` is inferred from traffic and Guardian sends no
    // heartbeats, so a stream with no subscriptions produces no events and the
    // edge never arrives — the hook would have been unreachable in exactly the
    // mode it was written for. The contract's doc comment has the full chain.
    if (existingRecords.isEmpty) {
      logger
          .d('[SSE]: stream opened — no existing subscriptions to re-register');
      return;
    }

    // One walk at a time. Not defensive padding: the walk takes roughly a second
    // for six subscriptions (100ms after each unsubscribe, 50ms between records),
    // `SseManager` invokes it fire-and-forget, and a stream that flaps inside that
    // window starts a second walk over the same records. The two then interleave
    // on one subscription ID — walk B subscribes it, walk A's loop reaches it and
    // unsubscribes — and the loser is absent for the rest of the session with only
    // a swallowed `logger.w` to show for it. `registerSubscriptions` guards each
    // record against throwing; nothing guarded the walk against itself.
    if (_reRegistrationInProgress) {
      logger.d('[SSE]: stream opened — re-registration already in progress, '
          'skipping');
      return;
    }
    _reRegistrationInProgress = true;

    logger.d('[SSE]: stream opened — re-registering '
        '${existingRecords.length} subscriptions');

    try {
      // Through `registerSubscriptions`, not `subscribe` directly: Guardian
      // rejects a duplicate subscription ID, so the unregister → delay → register
      // dance is mandatory here in a way it is not for the local bridge. That also
      // makes the call idempotent, which is what makes it safe to run alongside an
      // orchestrator that may have re-registered already.
      //
      // The returned records are discarded on purpose — the IDs are unchanged, so
      // the registry's existing records still describe what is now on Guardian.
      await registerSubscriptions(existingRecords
          .map((record) => SubscriptionDef(
                subscriptionId: record.subscriptionId,
                notifType: record.notifType,
                referenceList: record.referenceList,
              ))
          .toList());
    } finally {
      _reRegistrationInProgress = false;
    }
  }

  @override
  Future<void> onSseConnected(
      List<SseSubscriptionRecord> existingRecords) async {
    // Deliberately nothing. Reaching this edge requires a notification, which
    // requires a live subscription, so by the time it fires the subscriptions are
    // already delivering — and re-registering would unsubscribe and re-subscribe
    // a stream that is currently working, opening a blackout window for no gain.
    // The reconnect case is handled in `onSseStreamOpened`.
  }

  @override
  Future<void> onSseDisconnected({required bool intentional}) async {
    if (intentional) {
      // Fire-and-forget cleanup: unregister all subscriptions on Guardian
      // Don't await — let it complete in background
      logger.d('[SSE]: onDisconnected (intentional) — '
          'fire-and-forget cleanup');
      _fireAndForgetCleanup();
    } else {
      logger.d('[SSE]: onDisconnected (unintentional) — '
          'will resubscribe on reconnect via orchestrator');
    }
  }

  void _fireAndForgetCleanup() {
    // Query existing subscriptions and unregister only remote ones (best-effort)
    _bridge.listSubscriptions().then((ids) {
      for (final id in ids) {
        if (_isRemoteId(id)) {
          _bridge.unsubscribe(subscriptionId: id).ignore();
        }
      }
    }).ignore();
  }

  @override
  void dispose() {
    // No resources to dispose
  }

  int _notifTypeToInt(String notifType) {
    const mapping = {
      'ValueChange': 1,
      'ObjectCreation': 2,
      'ObjectDeletion': 3,
      'OperationComplete': 4,
      'Event': 5,
    };
    return mapping[notifType] ?? 1;
  }
}
