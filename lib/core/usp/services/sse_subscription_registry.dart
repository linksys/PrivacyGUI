import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import 'sse_operation_strategy.dart';

export 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

/// Tracks active SSE subscriptions in memory and delegates
/// registration to [SseOperationStrategy].
///
/// This class is responsible for:
/// - In-memory tracking of active subscriptions
/// - Delegating actual register/unregister to the strategy
/// - Preventing duplicate registration (in-memory check)
class SseSubscriptionRegistry {
  final SseOperationStrategy _strategy;

  SseSubscriptionRegistry(this._strategy);

  final Map<String, SseSubscriptionRecord> _subscriptions = {};

  /// All currently registered subscription IDs.
  Set<String> get activeIds => _subscriptions.keys.toSet();

  /// All current subscription records.
  List<SseSubscriptionRecord> get records => _subscriptions.values.toList();

  /// Registers subscriptions via the strategy.
  ///
  /// Filters out already-registered subscriptions (in-memory check)
  /// and delegates actual registration to the strategy.
  Future<void> registerAll(List<SubscriptionDef> subscriptions) async {
    // Filter out already registered (in-memory)
    final toRegister = subscriptions
        .where((s) => !_subscriptions.containsKey(s.subscriptionId))
        .toList();

    if (toRegister.isEmpty) {
      logger.d('[SSE][Registry]: All ${subscriptions.length} subscriptions '
          'already registered, skipping');
      return;
    }

    if (toRegister.length < subscriptions.length) {
      logger.d(
          '[SSE][Registry]: Skipping ${subscriptions.length - toRegister.length} '
          'already registered subscriptions');
    }

    final records = await _strategy.registerSubscriptions(toRegister);

    for (final record in records) {
      _subscriptions[record.subscriptionId] = record;
    }

    logger.d('[SSE][Registry]: Registered ${records.length} subscriptions, '
        'total active: ${_subscriptions.length}');
  }

  /// Unregisters a subscription.
  Future<void> unregister(String subscriptionId) async {
    final record = _subscriptions.remove(subscriptionId);
    if (record == null) {
      logger.d(
          '[SSE][Registry]: Unregister $subscriptionId: not found, skipping');
      return;
    }

    await _strategy.unregisterSubscriptions([subscriptionId]);
  }

  /// Unregisters all subscriptions.
  Future<void> unregisterAll() async {
    if (_subscriptions.isEmpty) return;

    final ids = _subscriptions.keys.toList();
    _subscriptions.clear();

    await _strategy.unregisterSubscriptions(ids);
    logger.d('[SSE][Registry]: Unregistered all ${ids.length} subscriptions');
  }

  /// Called when SSE connects. Delegates to strategy for reconnect handling.
  Future<void> onSseConnected() async {
    await _strategy.onSseConnected(records);
  }

  /// Called when SSE disconnects.
  Future<void> onSseDisconnected({required bool intentional}) async {
    await _strategy.onSseDisconnected(intentional: intentional);
    if (intentional) {
      _subscriptions.clear();
    }
  }

  /// Clears in-memory state without unregistering on backend.
  void clearLocal() {
    _subscriptions.clear();
  }
}
