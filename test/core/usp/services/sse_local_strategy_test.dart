import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/sse_local_strategy.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';

import '../mocks.dart';

void main() {
  late MockUspBridgeClient mockBridge;
  late LocalSseStrategy strategy;

  setUp(() {
    mockBridge = MockUspBridgeClient();
    strategy = LocalSseStrategy(mockBridge);

    when(() => mockBridge.subscribe(
          subscriptionId: any(named: 'subscriptionId'),
          path: any(named: 'path'),
          notifType: any(named: 'notifType'),
        )).thenAnswer((_) async => {});
    when(() => mockBridge.unsubscribe(
          subscriptionId: any(named: 'subscriptionId'),
        )).thenAnswer((_) async => {});
  });

  group('heartbeatConfig', () {
    test('returns local config with enabled=true', () {
      expect(strategy.heartbeatConfig.enabled, isTrue);
      expect(strategy.heartbeatConfig.authCheckEnabled, isTrue);
      expect(strategy.heartbeatConfig.timeout, const Duration(seconds: 45));
    });
  });

  group('registerSubscriptions', () {
    test('calls bridge.subscribe for each subscription', () async {
      await strategy.registerSubscriptions([
        SubscriptionDef(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.',
        ),
        SubscriptionDef(
          subscriptionId: 'sub-2',
          notifType: 'ObjectCreation',
          referenceList: 'Device.Hosts.',
        ),
      ]);

      verify(() => mockBridge.subscribe(
            subscriptionId: 'sub-1',
            path: 'Device.WiFi.',
            notifType: 1,
          )).called(1);
      verify(() => mockBridge.subscribe(
            subscriptionId: 'sub-2',
            path: 'Device.Hosts.',
            notifType: 2,
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
      expect(records.first.notifType, 'ValueChange');
    });

    test('continues on failure and excludes failed from results', () async {
      when(() => mockBridge.subscribe(
            subscriptionId: 'fail-sub',
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          )).thenThrow(Exception('bridge error'));

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

    test('converts notifType correctly', () async {
      await strategy.registerSubscriptions([
        SubscriptionDef(
            subscriptionId: 'vc',
            notifType: 'ValueChange',
            referenceList: 'D.'),
        SubscriptionDef(
            subscriptionId: 'oc',
            notifType: 'ObjectCreation',
            referenceList: 'D.'),
        SubscriptionDef(
            subscriptionId: 'od',
            notifType: 'ObjectDeletion',
            referenceList: 'D.'),
        SubscriptionDef(
            subscriptionId: 'op',
            notifType: 'OperationComplete',
            referenceList: 'D.'),
        SubscriptionDef(
            subscriptionId: 'ev', notifType: 'Event', referenceList: 'D.'),
      ]);

      verify(() => mockBridge.subscribe(
          subscriptionId: 'vc', path: any(named: 'path'), notifType: 1));
      verify(() => mockBridge.subscribe(
          subscriptionId: 'oc', path: any(named: 'path'), notifType: 2));
      verify(() => mockBridge.subscribe(
          subscriptionId: 'od', path: any(named: 'path'), notifType: 3));
      verify(() => mockBridge.subscribe(
          subscriptionId: 'op', path: any(named: 'path'), notifType: 4));
      verify(() => mockBridge.subscribe(
          subscriptionId: 'ev', path: any(named: 'path'), notifType: 5));
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

      verify(() => mockBridge.unsubscribe(subscriptionId: 'fail')).called(1);
      verify(() => mockBridge.unsubscribe(subscriptionId: 'ok')).called(1);
    });
  });

  group('onSseConnected', () {
    test('resubscribes all existing records', () async {
      final records = [
        SseSubscriptionRecord(
          subscriptionId: 'sub-1',
          notifType: 'ValueChange',
          referenceList: 'Device.WiFi.',
          createdAt: DateTime.now(),
        ),
        SseSubscriptionRecord(
          subscriptionId: 'sub-2',
          notifType: 'ObjectCreation',
          referenceList: 'Device.Hosts.',
          createdAt: DateTime.now(),
        ),
      ];

      await strategy.onSseConnected(records);

      verify(() => mockBridge.subscribe(
            subscriptionId: 'sub-1',
            path: 'Device.WiFi.',
            notifType: 1,
          )).called(1);
      verify(() => mockBridge.subscribe(
            subscriptionId: 'sub-2',
            path: 'Device.Hosts.',
            notifType: 2,
          )).called(1);
    });

    test('does nothing with empty records', () async {
      await strategy.onSseConnected([]);

      verifyNever(() => mockBridge.subscribe(
            subscriptionId: any(named: 'subscriptionId'),
            path: any(named: 'path'),
            notifType: any(named: 'notifType'),
          ));
    });
  });

  group('onSseDisconnected', () {
    test('does nothing (bridge handles cleanup)', () async {
      await strategy.onSseDisconnected(intentional: true);
      await strategy.onSseDisconnected(intentional: false);

      verifyNever(() => mockBridge.unsubscribe(
            subscriptionId: any(named: 'subscriptionId'),
          ));
    });
  });
}
