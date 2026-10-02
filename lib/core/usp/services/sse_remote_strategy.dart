import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import 'sse_operation_strategy.dart';
import 'usp_bridge_client.dart';

/// Remote SSE strategy for Guardian proxy.
///
/// Characteristics:
/// - Guardian does NOT allow duplicate subscription IDs (causes conflict)
/// - Must unregister every id before registering any (all at once, then all at
///   once — see [registerSubscriptions])
/// - Re-registers existing subscriptions on *re*connect; the first connect is
///   the orchestrator's (see [onSseConnected])
/// - Heartbeat watchdog written and switched off (#1577): QA Guardian was seen
///   sending a ~20 s `heartbeat` on 2026-10-02, once and for 40 s, which is not
///   yet the hour-long verification the switch waits on
/// - No auth check (temporaryAccessToken cannot refresh)
/// - Uses 'remote-' prefix for subscription IDs to avoid collision with Local
class RemoteSseStrategy implements SseOperationStrategy {
  final UspBridgeClient _bridge;

  /// Prefix for remote subscription IDs to avoid collision with Local mode.
  static const _idPrefix = 'remote-';

  /// Delay between the unregister batch and the register batch, to let
  /// Guardian settle the removals before the same ids are added back.
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

  /// Registers [subscriptions] in two batches: every unregister at once, then
  /// every register at once.
  ///
  /// Batched because Guardian answers each of these in 1–5 s. Measured on QA,
  /// 2026-10-02, with the seven core subscriptions: one after another
  /// (unregister, 100 ms, register, 50 ms) took **32.1 s**; seven unregisters in
  /// parallel 3.1–5.7 s and seven registers in parallel **2.9 s**, every request
  /// 200, no 503, and the parallel-registered subscriptions delivered notifies
  /// at the same rate as the serial ones. The serial walk was the larger half of
  /// the minute an RA agent waited behind the "setting up live updates" dialog.
  ///
  /// The 503 the first-connect ordering guards against belongs to the on-router
  /// bridge's single-threaded backend, which [LocalSseStrategy] still talks to
  /// one request at a time. Guardian is not that backend.
  ///
  /// The unregister batch is still mandatory, and still comes **first and
  /// whole**: Guardian rejects a duplicate id, so no register may go out while
  /// its own id's unregister is still in flight. An unregister that fails is
  /// ignored — the id is usually simply absent — and a register that fails costs
  /// only its own subscription. Records come back in the order asked for, so
  /// the registry reads the same whichever answer arrived first.
  @override
  Future<List<SseSubscriptionRecord>> registerSubscriptions(
    List<SubscriptionDef> subscriptions,
  ) async {
    logger.d('[SSE]: Registering ${subscriptions.length} subscriptions '
        '(${subscriptions.map((s) => s.subscriptionId).join(', ')})');

    await Future.wait([
      for (final sub in subscriptions) _unregisterIgnoringAbsence(sub),
    ]);
    await Future.delayed(_unregisterDelay);

    final registered = await Future.wait([
      for (final sub in subscriptions) _register(sub),
    ]);
    final records = registered.whereType<SseSubscriptionRecord>().toList();

    logger.d(
        '[SSE]: Registered ${records.length}/${subscriptions.length} subscriptions');
    return records;
  }

  /// One unregister, ignoring any failure: the id is usually just absent.
  ///
  /// An `async` body with a `try`, not a `.then(onError:)` on the call, so a
  /// synchronous throw from the bridge is caught too — the batch must not fail
  /// on one id's absence.
  Future<void> _unregisterIgnoringAbsence(SubscriptionDef sub) async {
    try {
      await _bridge.unsubscribe(
          subscriptionId: _toRemoteId(sub.subscriptionId));
    } catch (_) {
      // Ignore — subscription may not exist
    }
  }

  /// One register, or null if Guardian refused it.
  Future<SseSubscriptionRecord?> _register(SubscriptionDef sub) async {
    final remoteId = _toRemoteId(sub.subscriptionId);
    try {
      await _bridge.subscribe(
        subscriptionId: remoteId,
        path: sub.referenceList,
        notifType: _notifTypeToInt(sub.notifType),
      );
      // Record uses original ID (transparent to Registry/Manager)
      return SseSubscriptionRecord(
        subscriptionId: sub.subscriptionId,
        notifType: sub.notifType,
        referenceList: sub.referenceList,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      logger.w('[SSE]: Failed to register ${sub.subscriptionId} '
          '(as $remoteId): $e');
      return null;
    }
  }

  /// `teardown: true`, so a 401 is thrown and swallowed below but never reported.
  /// Logout reaches this through `unregisterAll()` after `session.end()` has spent
  /// the credential, where a reported 401 asks for a logout from inside the
  /// logout — the loop [onSseDisconnected]'s cleanup closed. `disconnect()`
  /// empties the registry first, so today that list is empty; this keeps the loop
  /// closed if the two steps are ever reordered. The other caller, a single
  /// handler's cleanup, ignores the failure as well.
  @override
  Future<void> unregisterSubscriptions(List<String> subscriptionIds) async {
    for (final id in subscriptionIds) {
      final remoteId = _toRemoteId(id);
      try {
        await _bridge.unsubscribe(subscriptionId: remoteId, teardown: true);
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
    // put it. `connected` is inferred from traffic, and when this was written
    // Guardian was measured sending no heartbeats, so a stream with no
    // subscriptions produced no events and the edge never arrived. QA was seen
    // heartbeating on 2026-10-02; stream-open stays the edge anyway, because it
    // is the earlier one and does not depend on a guarantee nobody has made.
    // The contract's doc comment has the full chain.
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
          'records kept, re-registered when the stream reopens');
    }
  }

  void _fireAndForgetCleanup() {
    // Query existing subscriptions and unregister only remote ones (best-effort).
    //
    // `teardown: true` on both: an intentional disconnect is almost always a
    // logout, which has already spent the credential, so a 401 here is the
    // expected answer. Reported as a session loss, it asked for a logout from
    // inside the logout that caused it — a loop, measured on QA Guardian at 770
    // teardowns in four minutes.
    _bridge.listSubscriptions(teardown: true).then((ids) {
      for (final id in ids) {
        if (_isRemoteId(id)) {
          _bridge.unsubscribe(subscriptionId: id, teardown: true).ignore();
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
