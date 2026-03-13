import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/usp/models/sse_subscription_record.dart';

import 'usp_bridge_client.dart';
import 'usp_service.dart';

export 'package:privacy_gui/usp/models/sse_subscription_record.dart';

/// Tracks active SSE subscriptions and manages two-layer creation:
///
/// 1. **OBUSPA Layer**: Creates `Device.LocalAgent.Subscription.{i}` via
///    [UspService.createNotifySubscription] (5-step workaround).
/// 2. **Bridge Layer**: Registers with bridge via
///    [UspBridgeClient.subscribe] for SSE session routing.
///
/// On SSE reconnect, only the bridge layer needs re-registration (OBUSPA
/// subscriptions persist on the router independently of SSE connections).
class SseSubscriptionRegistry {
  final UspService _usp;
  final UspBridgeClient _bridge;

  SseSubscriptionRegistry(this._usp, this._bridge);

  final Map<String, SseSubscriptionRecord> _subscriptions = {};

  /// All currently registered subscription IDs.
  Set<String> get activeIds => _subscriptions.keys.toSet();

  /// All current subscription records.
  Iterable<SseSubscriptionRecord> get records => _subscriptions.values;

  /// Creates a subscription at both OBUSPA and bridge layers.
  ///
  /// Steps:
  /// 1. Create OBUSPA subscription (5-step workaround via UspService)
  /// 2. Register with bridge for SSE routing
  /// 3. Store record for tracking
  ///
  /// Throws if either step fails. On bridge registration failure, the OBUSPA
  /// subscription is cleaned up.
  Future<SseSubscriptionRecord> register({
    required String subscriptionId,
    required String notifType,
    required String referenceList,
  }) async {
    // Check for duplicate
    if (_subscriptions.containsKey(subscriptionId)) {
      logger.d('[SSE Registry] Subscription $subscriptionId already exists, '
          'skipping duplicate registration');
      return _subscriptions[subscriptionId]!;
    }

    logger.d('[SSE Registry] Registering $subscriptionId '
        '(type=$notifType, ref=$referenceList)');

    // Step 1: Create OBUSPA subscription
    final obuspaResult = await _usp.createNotifySubscription(
      notifType: notifType,
      referenceList: referenceList,
    );
    final instancePath = obuspaResult['instancePath'] ?? '';

    if (instancePath.isEmpty) {
      throw StateError(
          'OBUSPA subscription creation returned empty instancePath '
          'for $subscriptionId');
    }

    // Step 2: Register with bridge for SSE routing
    try {
      await _bridge.subscribe(
        subscriptionId: subscriptionId,
        path: referenceList,
        notifType: _notifTypeToInt(notifType),
      );
    } catch (e) {
      // Cleanup OBUSPA subscription on bridge failure
      logger.w('[SSE Registry] Bridge registration failed for '
          '$subscriptionId, cleaning up OBUSPA subscription: $e');
      try {
        await _usp.deleteNotifySubscription(instancePath);
      } catch (cleanupError) {
        logger.w('[SSE Registry] OBUSPA cleanup also failed: $cleanupError');
      }
      rethrow;
    }

    // Step 3: Store record
    final record = SseSubscriptionRecord(
      subscriptionId: subscriptionId,
      obuspaInstancePath: instancePath,
      notifType: notifType,
      referenceList: referenceList,
      createdAt: DateTime.now(),
    );
    _subscriptions[subscriptionId] = record;

    logger.d('[SSE Registry] Registered $subscriptionId → $instancePath');
    return record;
  }

  /// Removes a subscription from both OBUSPA and bridge layers.
  Future<void> unregister(String subscriptionId) async {
    final record = _subscriptions.remove(subscriptionId);
    if (record == null) {
      logger.d('[SSE Registry] Unregister $subscriptionId: not found, skipping');
      return;
    }

    logger.d('[SSE Registry] Unregistering $subscriptionId');

    // Unregister from bridge (non-fatal if fails)
    try {
      await _bridge.unsubscribe(subscriptionId: subscriptionId);
    } catch (e) {
      logger.w('[SSE Registry] Bridge unsubscribe failed for '
          '$subscriptionId: $e');
    }

    // Delete OBUSPA subscription (non-fatal if fails)
    try {
      await _usp.deleteNotifySubscription(record.obuspaInstancePath);
    } catch (e) {
      logger.w('[SSE Registry] OBUSPA delete failed for '
          '$subscriptionId (${record.obuspaInstancePath}): $e');
    }
  }

  /// Re-registers ALL tracked subscriptions on the bridge layer only.
  ///
  /// Called after SSE reconnect. OBUSPA subscriptions persist on the router
  /// across SSE disconnects, so only the bridge session mapping needs
  /// re-registration — this avoids the expensive 5-step OBUSPA workaround.
  Future<void> resubscribeAll() async {
    if (_subscriptions.isEmpty) {
      logger.d('[SSE Registry] resubscribeAll: no subscriptions to re-register');
      return;
    }

    logger.d('[SSE Registry] Re-registering ${_subscriptions.length} '
        'subscriptions on bridge');

    for (final record in _subscriptions.values) {
      try {
        await _bridge.subscribe(
          subscriptionId: record.subscriptionId,
          path: record.referenceList,
          notifType: _notifTypeToInt(record.notifType),
        );
        logger.d('[SSE Registry] Re-registered ${record.subscriptionId}');
      } catch (e) {
        logger.w('[SSE Registry] Failed to re-register '
            '${record.subscriptionId}: $e');
        // Non-fatal: continue with remaining subscriptions
      }
    }
  }

  /// Removes all subscriptions (both OBUSPA and bridge).
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
