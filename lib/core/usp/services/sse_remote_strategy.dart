import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import 'sse_operation_strategy.dart';
import 'usp_bridge_client.dart';

/// Remote SSE strategy for Guardian proxy.
///
/// Characteristics:
/// - Guardian does NOT allow duplicate subscription IDs (causes conflict)
/// - Must unregister → delay → register
/// - No auto resubscribe on reconnect (orchestrator controls)
/// - Heartbeat watchdog disabled (Guardian doesn't send heartbeats)
/// - No auth check (temporaryAccessToken cannot refresh)
class RemoteSseStrategy implements SseOperationStrategy {
  final UspBridgeClient _bridge;

  /// Delay between unregister and register to allow Guardian to process.
  static const _unregisterDelay = Duration(milliseconds: 100);

  RemoteSseStrategy(this._bridge);

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
      try {
        logger.d('[SSE][Remote]: Registering ${sub.subscriptionId}');

        // Unregister first to avoid ID conflict
        try {
          await _bridge.unsubscribe(subscriptionId: sub.subscriptionId);
          await Future.delayed(_unregisterDelay);
        } catch (_) {
          // Ignore — subscription may not exist
        }

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

        // Breathing room for Guardian between requests
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        logger.w('[SSE][Remote]: Failed to register ${sub.subscriptionId}: $e');
      }
    }

    logger.d(
        '[SSE][Remote]: Registered ${records.length}/${subscriptions.length} subscriptions');
    return records;
  }

  @override
  Future<void> unregisterSubscriptions(List<String> subscriptionIds) async {
    for (final id in subscriptionIds) {
      try {
        await _bridge.unsubscribe(subscriptionId: id);
        logger.d('[SSE][Remote]: Unregistered $id');
      } catch (e) {
        logger.w('[SSE][Remote]: Failed to unregister $id: $e');
      }
    }
  }

  @override
  Future<void> onSseConnected(
      List<SseSubscriptionRecord> existingRecords) async {
    // Remote: Do NOT auto resubscribe — orchestrator controls registration
    // This avoids duplicate registration when orchestrator has already registered
    logger.d('[SSE][Remote]: onConnected — skipping auto resubscribe '
        '(orchestrator controls registration)');
  }

  @override
  Future<void> onSseDisconnected({required bool intentional}) async {
    if (intentional) {
      // Fire-and-forget cleanup: unregister all subscriptions on Guardian
      // Don't await — let it complete in background
      logger.d('[SSE][Remote]: onDisconnected (intentional) — '
          'fire-and-forget cleanup');
      _fireAndForgetCleanup();
    } else {
      logger.d('[SSE][Remote]: onDisconnected (unintentional) — '
          'will resubscribe on reconnect via orchestrator');
    }
  }

  void _fireAndForgetCleanup() {
    // Query existing subscriptions and unregister all (best-effort)
    _bridge.listSubscriptions().then((ids) {
      for (final id in ids) {
        _bridge.unsubscribe(subscriptionId: id).ignore();
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
