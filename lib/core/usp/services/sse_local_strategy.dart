import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import 'sse_operation_strategy.dart';
import 'usp_bridge_client.dart';

/// Local SSE strategy for usp-bridge (on-router).
///
/// Characteristics:
/// - Bridge is idempotent: re-registering same ID is safe
/// - Direct register without unregister
/// - Auto resubscribe on reconnect
/// - Heartbeat watchdog enabled (45s timeout)
/// - Proactive auth check on heartbeat
class LocalSseStrategy implements SseOperationStrategy {
  final UspBridgeClient _bridge;

  LocalSseStrategy(this._bridge);

  @override
  HeartbeatConfig get heartbeatConfig => HeartbeatConfig.local;

  @override
  Future<List<SseSubscriptionRecord>> registerSubscriptions(
    List<SubscriptionDef> subscriptions,
  ) async {
    final records = <SseSubscriptionRecord>[];

    for (final sub in subscriptions) {
      try {
        logger.d('[SSE][Local]: Registering ${sub.subscriptionId}');

        await _bridge.subscribe(
          subscriptionId: sub.subscriptionId,
          path: sub.referenceList,
          notifType: _notifTypeToInt(sub.notifType),
        );

        records.add(SseSubscriptionRecord(
          subscriptionId: sub.subscriptionId,
          notifType: sub.notifType,
          referenceList: sub.referenceList,
          createdAt: DateTime.now(),
        ));

        // Small breathing room for embedded router between requests
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        logger.w('[SSE][Local]: Failed to register ${sub.subscriptionId}: $e');
      }
    }

    logger.d(
        '[SSE][Local]: Registered ${records.length}/${subscriptions.length} subscriptions');
    return records;
  }

  @override
  Future<void> unregisterSubscriptions(List<String> subscriptionIds) async {
    for (final id in subscriptionIds) {
      try {
        await _bridge.unsubscribe(subscriptionId: id);
        logger.d('[SSE][Local]: Unregistered $id');
      } catch (e) {
        logger.w('[SSE][Local]: Failed to unregister $id: $e');
      }
    }
  }

  @override
  Future<void> onSseConnected(
      List<SseSubscriptionRecord> existingRecords) async {
    if (existingRecords.isEmpty) {
      logger.d(
          '[SSE][Local]: onConnected — no existing subscriptions to resubscribe');
      return;
    }

    logger.d(
        '[SSE][Local]: onConnected — resubscribing ${existingRecords.length} subscriptions');

    // Bridge is idempotent, safe to re-register directly
    for (final record in existingRecords) {
      try {
        await _bridge.subscribe(
          subscriptionId: record.subscriptionId,
          path: record.referenceList,
          notifType: _notifTypeToInt(record.notifType),
        );
      } catch (e) {
        logger.w(
            '[SSE][Local]: Failed to resubscribe ${record.subscriptionId}: $e');
      }
    }
  }

  @override
  Future<void> onSseDisconnected({required bool intentional}) async {
    // Local: Bridge handles cleanup, no action needed
    logger.d('[SSE][Local]: onDisconnected (intentional=$intentional)');
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
