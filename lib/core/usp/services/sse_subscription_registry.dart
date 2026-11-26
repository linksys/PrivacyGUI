import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import 'sse_operation_strategy.dart';

export 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

/// The SSE subscriptions of this session and who holds each one; the router
/// side is delegated to [SseOperationStrategy].
///
/// One subscription id can have several holders: two package widget live
/// notifiers keyed by two templates of one widget hold `pkg-<widgetId>-
/// valuechange` at once (#1887). So the router sees an id registered once
/// while at least one holder has it, and unregistered once, after the last
/// holder has let go:
/// - a [hold] of an id whose registration is in flight waits for it instead
///   of registering the id again;
/// - a [hold] of an id whose unregister is in flight waits for that first, so
///   the new registration is not undone by the old unregister;
/// - a holder is an identity, not a count, so a second [release] by one holder
///   changes nothing, and a release from before the session ended cannot
///   remove a holder of the next session.
class SseSubscriptionRegistry {
  final SseOperationStrategy _strategy;

  SseSubscriptionRegistry(this._strategy);

  final Map<String, _Entry> _entries = {};

  /// Unregisters in flight, by id: what a [hold] of that id waits for.
  final Map<String, Future<void>> _unregistering = {};

  /// All currently registered subscription IDs.
  Set<String> get activeIds => {
        for (final MapEntry(:key, :value) in _entries.entries)
          if (value.record != null) key,
      };

  /// All current subscription records.
  List<SseSubscriptionRecord> get records => [
        for (final entry in _entries.values)
          if (entry.record case final record?) record,
      ];

  /// Adds [holder] to each of [subscriptions], registering on the router the
  /// ids nobody held yet, all in one strategy call. Completes once each id is
  /// registered or refused, its own registration or the one it joined.
  ///
  /// [holder] is compared by identity. Holding an id twice with one holder is
  /// holding it once: the core set does that every time it is registered
  /// again.
  ///
  /// The strategy reports a refused id by leaving out its record, and so does
  /// this: a refused id has no holders afterwards, and the next [hold] of it
  /// tries again.
  Future<void> hold(
    List<SubscriptionDef> subscriptions, {
    required Object holder,
  }) async {
    final unregistering = [
      for (final s in subscriptions)
        if (_unregistering[s.subscriptionId] case final pending?) pending,
    ];
    if (unregistering.isNotEmpty) await Future.wait(unregistering);

    final toRegister = <_Entry>[];
    final inFlight = <Future<void>>{};
    for (final s in subscriptions) {
      final entry = _entries[s.subscriptionId];
      if (entry != null) {
        entry.holders.add(holder);
        if (entry.registering case final registering?) {
          inFlight.add(registering);
        }
        continue;
      }
      final created = _Entry(s)..holders.add(holder);
      _entries[s.subscriptionId] = created;
      toRegister.add(created);
    }

    if (toRegister.isEmpty && inFlight.isEmpty) {
      logger.d('[SSE]: All ${subscriptions.length} subscriptions '
          'already registered, skipping');
      return;
    }
    if (toRegister.isNotEmpty) {
      final registering = _register(toRegister);
      for (final entry in toRegister) {
        entry.registering = registering;
      }
      inFlight.add(registering);
    }
    await Future.wait(inFlight);
  }

  Future<void> _register(List<_Entry> entries) async {
    final List<SseSubscriptionRecord> records;
    try {
      records = await _strategy
          .registerSubscriptions([for (final e in entries) e.subscription]);
    } catch (_) {
      _forget(entries);
      rethrow;
    }
    final byId = {for (final r in records) r.subscriptionId: r};
    for (final entry in entries) {
      entry.registering = null;
      final id = entry.subscription.subscriptionId;
      // Gone: the session ended while this was in flight. Not unregistered here:
      // an intentional disconnect leaves the router side to the strategy.
      if (!identical(_entries[id], entry)) continue;
      final record = byId[id];
      if (record == null) {
        _entries.remove(id);
      } else {
        entry.record = record;
      }
    }
    logger.d('[SSE]: Registered ${records.length} subscriptions, '
        'total active: ${activeIds.length}');
  }

  void _forget(List<_Entry> entries) {
    for (final entry in entries) {
      final id = entry.subscription.subscriptionId;
      if (identical(_entries[id], entry)) _entries.remove(id);
    }
  }

  /// Removes [holder] from [subscriptionId], and unregisters the id on the
  /// router if that was its last holder.
  ///
  /// Does nothing for a holder the id does not have: one that released it
  /// already, or one from before the session ended.
  Future<void> release(String subscriptionId, {required Object holder}) async {
    final entry = _entries[subscriptionId];
    if (entry == null || !entry.holders.remove(holder)) {
      logger.d('[SSE]: Release $subscriptionId: not held by this holder, '
          'skipping');
      return;
    }
    if (entry.holders.isNotEmpty) {
      logger.d('[SSE]: Release $subscriptionId: '
          '${entry.holders.length} holder(s) left');
      return;
    }
    _entries.remove(subscriptionId);
    if (entry.record == null) return;

    final unregistering = _strategy.unregisterSubscriptions([subscriptionId]);
    _unregistering[subscriptionId] = unregistering;
    try {
      await unregistering;
    } finally {
      if (identical(_unregistering[subscriptionId], unregistering)) {
        _unregistering.remove(subscriptionId);
      }
    }
  }

  /// Unregisters every registered subscription and forgets every holder.
  Future<void> unregisterAll() async {
    final ids = activeIds.toList();
    _entries.clear();
    if (ids.isEmpty) return;

    await _strategy.unregisterSubscriptions(ids);
    logger.d('[SSE]: Unregistered all ${ids.length} subscriptions');
  }

  /// Called when the SSE stream opens, before any event has arrived. Delegates to
  /// strategy — the remote arm re-registers here because it cannot rely on
  /// [onSseConnected] being reached at all.
  Future<void> onSseStreamOpened() async {
    await _strategy.onSseStreamOpened(records);
  }

  /// Called when SSE connects. Delegates to strategy for reconnect handling.
  Future<void> onSseConnected() async {
    await _strategy.onSseConnected(records);
  }

  /// Called when SSE disconnects. An intentional disconnect ends the session's
  /// subscriptions: every holder is forgotten, so a release that arrives later
  /// does nothing.
  Future<void> onSseDisconnected({required bool intentional}) async {
    await _strategy.onSseDisconnected(intentional: intentional);
    if (intentional) {
      _entries.clear();
    }
  }
}

/// One subscription id: who holds it, and whether the router has it yet.
class _Entry {
  _Entry(this.subscription);

  final SubscriptionDef subscription;

  /// Compared by identity; see [SseSubscriptionRegistry.hold].
  final Set<Object> holders = Set.identity();

  /// Set once the router accepted the registration.
  SseSubscriptionRecord? record;

  /// The registration in flight, which a second [SseSubscriptionRegistry.hold]
  /// joins.
  Future<void>? registering;
}
