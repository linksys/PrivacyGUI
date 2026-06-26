import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_remote_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import '../mocks.dart';

void main() {
  late MockUspBridgeClient mockBridge;
  late RemoteSseStrategy strategy;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    strategy = RemoteSseStrategy(mockBridge);

    when(() => mockBridge.subscribe(
          subscriptionId: any(named: 'subscriptionId'),
          path: any(named: 'path'),
          notifType: any(named: 'notifType'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.unsubscribe(
          subscriptionId: any(named: 'subscriptionId'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.listSubscriptions())
        .thenAnswer((_) async => <String>[]);
  });

  group('heartbeatConfig', () {
    test('returns remote config with enabled=false', () {
      expect(strategy.heartbeatConfig.enabled, isFalse);
      expect(strategy.heartbeatConfig.authCheckEnabled, isFalse);
    });
  });

  group('authBehavior', () {
    test('returns remote config with shouldRetryOnFailure=false', () {
      expect(strategy.authBehavior.shouldRetryOnFailure, isFalse);
    });
  });

  group('registerSubscriptions', () {
    test('calls unsubscribe before subscribe for each subscription', () async {
      await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.',
        ),
      ]);

      verifyInOrder([
        () => mockBridge.unsubscribe(subscriptionId: 'sub-1'),
        () => mockBridge.subscribe(
              subscriptionId: 'sub-1',
              path: 'Device.WiFi.',
              notifType: 1,
            ),
      ]);
    });

    test('ignores unsubscribe error and continues to subscribe', () async {
      when(() => mockBridge.unsubscribe(
              subscriptionId: any(named: 'subscriptionId')))
          .thenThrow(Exception('not found'));

      final records = await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.',
        ),
      ]);

      expect(records.length, 1);
      verify(() => mockBridge.subscribe(
            subscriptionId: 'sub-1',
            path: 'Device.WiFi.',
            notifType: 1,
          )).called(1);
    });

    test('returns records for successful registrations', () async {
      final records = await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.Test.',
        ),
      ]);

      expect(records.length, 1);
      expect(records.first.subscriptionId, 'sub-1');
    });

    test('continues on subscribe failure', () async {
      when(() => mockBridge.subscribe(
            subscriptionId: 'fail-sub',
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenThrow(Exception('guardian error'));

      final records = await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'fail-sub',
          notifType: 'ValueChange',
          referenceList: 'Device.Fail.',
        ),
        SubscriptionDef(
          subscriptionId: 'ok-sub',
          notifType: 'ValueChange',
          referenceList: 'Device.OK.',
        ),
      ]);

      expect(records.length, 1);
      expect(records.first.subscriptionId, 'ok-sub');
    });
  });

  group('unregisterSubscriptions', () {
    test('calls bridge.unsubscribe for each id', () async {
      await strategy.unregisterSubscriptions(['sub-1', 'sub-2']);

      verify(() => mockBridge.unsubscribe(subscriptionId: 'sub-1')).called(1);
      verify(() => mockBridge.unsubscribe(subscriptionId: 'sub-2')).called(1);
    });

    test('continues on failure', () async {
      when(() => mockBridge.unsubscribe(subscriptionId: 'fail'))
          .thenThrow(Exception('error'));

      await strategy.unregisterSubscriptions(['fail', 'ok']);

      verify(() => mockBridge.unsubscribe(subscriptionId: 'ok')).called(1);
    });
  });

  group('onSseConnected', () {
    test('does NOT auto resubscribe (orchestrator controls)', () async {
      final records = [
        SseSubscriptionRecord(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.',
          createdAt: DateTime.now(),
        ),
      ];

      await strategy.onSseConnected(records);

      // Remote strategy does NOT auto resubscribe on connect
      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));
    });
  });

  group('onSseDisconnected', () {
    test('intentional disconnect triggers fire-and-forget cleanup', () async {
      when(() => mockBridge.listSubscriptions())
          .thenAnswer((_) async => ['sub-1', 'sub-2']);

      await strategy.onSseDisconnected(intentional: true);

      // Fire-and-forget, so we just verify it was called
      // The actual cleanup happens asynchronously
      await Future.delayed(const Duration(milliseconds: 50));
      verify(() => mockBridge.listSubscriptions()).called(1);
    });

    test('unintentional disconnect does not trigger cleanup', () async {
      await strategy.onSseDisconnected(intentional: false);

      verifyNever(() => mockBridge.listSubscriptions());
    });
  });
}
