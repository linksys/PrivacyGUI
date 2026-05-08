import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import 'usp_bridge_client.dart';

export 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

/// Tracks active SSE subscriptions via the bridge API.
///
/// The bridge handles the full OBUSPA `Device.LocalAgent.Subscription.{i}`
/// lifecycle automatically:
/// - **register** → bridge creates OBUSPA subscription + SSE session mapping
/// - **unregister** → bridge deletes OBUSPA subscription + SSE session mapping
/// - **re-register** (same ID) → bridge is idempotent, reuses existing OBUSPA
///
/// On SSE reconnect, [resubscribeAll] re-registers all tracked subscriptions
/// on the bridge. Since bridge is idempotent by subscription_id, this is safe
/// even if the OBUSPA subscriptions persist from the previous session.
class SseSubscriptionRegistry {
  final UspBridgeClient _bridge;

  SseSubscriptionRegistry(this._bridge);

  final Map<String, SseSubscriptionRecord> _subscriptions = {};

  /// All currently registered subscription IDs.
  Set<String> get activeIds => _subscriptions.keys.toSet();

  /// All current subscription records.
  Iterable<SseSubscriptionRecord> get records => _subscriptions.values;

  /// Registers a subscription via the bridge API.
  ///
  /// The bridge creates the OBUSPA subscription and SSE routing in one call.
  /// Throws on failure.
  Future<SseSubscriptionRecord> register({
    required String subscriptionId,
    required String notifType,
    required String referenceList,
  }) async {
    // Check for duplicate
    if (_subscriptions.containsKey(subscriptionId)) {
      logger.d(
          '[USP][SSE][Registry]: Subscription $subscriptionId already exists, '
          'skipping duplicate registration');
      return _subscriptions[subscriptionId]!;
    }

    logger.d('[USP][SSE][Registry]: Registering $subscriptionId '
        '(type=$notifType, ref=$referenceList)');

    await _bridge.subscribe(
      subscriptionId: subscriptionId,
      path: referenceList,
      notifType: _notifTypeToInt(notifType),
    );

    final record = SseSubscriptionRecord(
      subscriptionId: subscriptionId,
      notifType: notifType,
      referenceList: referenceList,
      createdAt: DateTime.now(),
    );
    _subscriptions[subscriptionId] = record;

    logger.d('[USP][SSE][Registry]: Registered $subscriptionId');
    return record;
  }

  /// Unregisters a subscription via the bridge API.
  ///
  /// The bridge deletes the OBUSPA subscription and SSE routing.
  Future<void> unregister(String subscriptionId) async {
    final record = _subscriptions.remove(subscriptionId);
    if (record == null) {
      logger.d(
          '[USP][SSE][Registry]: Unregister $subscriptionId: not found, skipping');
      return;
    }

    logger.d('[USP][SSE][Registry]: Unregistering $subscriptionId');

    try {
      await _bridge.unsubscribe(subscriptionId: subscriptionId);
    } catch (e) {
      logger.w('[USP][SSE][Registry]: Bridge unsubscribe failed for '
          '$subscriptionId: $e');
    }
  }

  /// Re-registers ALL tracked subscriptions on the bridge.
  ///
  /// Called after SSE reconnect. Bridge is idempotent by subscription_id,
  /// so this safely reuses any OBUSPA subscriptions that persist from the
  /// previous session.
  Future<void> resubscribeAll() async {
    if (_subscriptions.isEmpty) {
      logger.d(
          '[USP][SSE][Registry]: resubscribeAll: no subscriptions to re-register');
      return;
    }

    logger.d('[USP][SSE][Registry]: Re-registering ${_subscriptions.length} '
        'subscriptions on bridge');

    for (final record in _subscriptions.values) {
      try {
        await _bridge.subscribe(
          subscriptionId: record.subscriptionId,
          path: record.referenceList,
          notifType: _notifTypeToInt(record.notifType),
        );
        logger
            .d('[USP][SSE][Registry]: Re-registered ${record.subscriptionId}');
      } catch (e) {
        logger.w('[USP][SSE][Registry]: Failed to re-register '
            '${record.subscriptionId}: $e');
      }
    }
  }

  /// Removes all subscriptions (bridge unregister for each).
  /// Used during logout / dispose.
  Future<void> unregisterAll() async {
    final ids = _subscriptions.keys.toList();
    for (final id in ids) {
      await unregister(id);
    }
  }

  /// Converts a notification type string to the bridge API integer.
  static int _notifTypeToInt(String notifType) {
    switch (notifType) {
      case 'ValueChange':
        return 1;
      case 'ObjectCreation':
        return 2;
      case 'ObjectDeletion':
        return 3;
      case 'OperationComplete':
        return 4;
      case 'Event':
        return 5;
      default:
        return 1;
    }
  }
}
