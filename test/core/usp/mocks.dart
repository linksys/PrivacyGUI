import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';

class MockUspBridgeClient extends Mock implements UspBridgeClient {}

class MockUspClient extends Mock implements UspClient {}

class MockSseManager extends Mock implements SseManager {}

class MockSseOperationStrategy extends Mock implements SseOperationStrategy {}

/// Fake strategy for testing that behaves like LocalSseStrategy.
class FakeSseOperationStrategy implements SseOperationStrategy {
  final UspBridgeClient bridge;

  FakeSseOperationStrategy(this.bridge);

  @override
  HeartbeatConfig get heartbeatConfig => HeartbeatConfig.local;

  @override
  Future<List<SseSubscriptionRecord>> registerSubscriptions(
    List<SubscriptionDef> subscriptions,
  ) async {
    final records = <SseSubscriptionRecord>[];
    for (final sub in subscriptions) {
      try {
        await bridge.subscribe(
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
      } catch (_) {
        // Log and continue (matches real strategy behavior)
      }
    }
    return records;
  }

  @override
  Future<void> unregisterSubscriptions(List<String> subscriptionIds) async {
    for (final id in subscriptionIds) {
      await bridge.unsubscribe(subscriptionId: id);
    }
  }

  @override
  Future<void> onSseConnected(
      List<SseSubscriptionRecord> existingRecords) async {
    for (final record in existingRecords) {
      await bridge.subscribe(
        subscriptionId: record.subscriptionId,
        path: record.referenceList,
        notifType: _notifTypeToInt(record.notifType),
      );
    }
  }

  @override
  Future<void> onSseDisconnected({required bool intentional}) async {}

  @override
  void dispose() {}

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
