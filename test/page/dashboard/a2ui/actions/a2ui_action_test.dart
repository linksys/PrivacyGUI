import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action.dart';

void main() {
  group('A2UIAction', () {
    group('Constructor and Factory Methods', () {
      test('creates action with required parameters', () {
        final action = A2UIAction(
          action: 'router.restart',
          params: {'timeout': 30},
          sourceWidgetId: 'router_control',
        );

        expect(action.action, equals('router.restart'));
        expect(action.params, equals({'timeout': 30}));
        expect(action.sourceWidgetId, equals('router_control'));
        expect(action.timestamp, isA<DateTime>());
      });

      test('creates action with minimal parameters', () {
        final action = A2UIAction(action: 'device.block');

        expect(action.action, equals('device.block'));
        expect(action.params, isEmpty);
        expect(action.sourceWidgetId, isNull);
        expect(action.timestamp, isA<DateTime>());
      });

      test('fromJson creates action correctly', () {
        final json = {
          r'$action': 'ui.showConfirmation',
          'params': {
            'title': 'Confirmation',
            'message': 'Are you sure?',
          },
        };

        final action = A2UIAction.fromJson(json, sourceWidgetId: 'test_widget');

        expect(action.action, equals('ui.showConfirmation'));
        expect(action.params['title'], equals('Confirmation'));
        expect(action.params['message'], equals('Are you sure?'));
        expect(action.sourceWidgetId, equals('test_widget'));
      });

      test('fromJson handles missing params', () {
        final json = {r'$action': 'router.restart'};
        final action = A2UIAction.fromJson(json);

        expect(action.action, equals('router.restart'));
        expect(action.params, isEmpty);
      });

      test('fromResolvedProperties creates action correctly', () {
        final resolvedProps = {
          r'$action': 'device.setSpeedLimit',
          'params': {
            'deviceId': 'device123',
            'speedLimit': 100,
          },
        };

        final action = A2UIAction.fromResolvedProperties(
          resolvedProps,
          sourceWidgetId: 'device_control',
        );

        expect(action.action, equals('device.setSpeedLimit'));
        expect(action.params['deviceId'], equals('device123'));
        expect(action.params['speedLimit'], equals(100));
        expect(action.sourceWidgetId, equals('device_control'));
      });
    });

    group('Data Conversion', () {
      test('toGenUiData converts correctly', () {
        final action = A2UIAction(
          action: 'router.restart',
          params: {'timeout': 30, 'force': true},
          sourceWidgetId: 'router_widget',
        );

        final genUiData = action.toGenUiData();

        expect(genUiData['action'], equals('router.restart'));
        expect(genUiData['params'], equals({'timeout': 30, 'force': true}));
        expect(genUiData['sourceWidgetId'], equals('router_widget'));
        expect(genUiData['timestamp'], isA<String>());
        // Flattened params
        expect(genUiData['timeout'], equals(30));
        expect(genUiData['force'], equals(true));
      });
    });

    group('Equality and String Representation', () {
      test('actions with same properties are equal', () {
        final timestamp = DateTime.now();
        final action1 = A2UIAction(
          action: 'test.action',
          params: {'key': 'value'},
          sourceWidgetId: 'widget1',
          timestamp: timestamp,
        );
        final action2 = A2UIAction(
          action: 'test.action',
          params: {'key': 'value'},
          sourceWidgetId: 'widget1',
          timestamp: timestamp,
        );

        expect(action1, equals(action2));
        expect(action1.hashCode, equals(action2.hashCode));
      });

      test('actions with different properties are not equal', () {
        final action1 = A2UIAction(action: 'test.action1');
        final action2 = A2UIAction(action: 'test.action2');

        expect(action1, isNot(equals(action2)));
      });

      test('toString provides readable representation', () {
        final action = A2UIAction(
          action: 'router.restart',
          params: {'timeout': 30},
          sourceWidgetId: 'router_control',
        );

        final stringRep = action.toString();
        expect(stringRep, contains('router.restart'));
        expect(stringRep, contains('timeout'));
        expect(stringRep, contains('router_control'));
      });
    });
  });

  group('A2UIActionResult', () {
    late A2UIAction testAction;

    setUp(() {
      testAction = A2UIAction(action: 'test.action');
    });

    group('Success Results', () {
      test('creates successful result', () {
        final result = A2UIActionResult.success(testAction, {'key': 'value'});

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.data, equals({'key': 'value'}));
        expect(result.action, equals(testAction));
      });

      test('creates successful result without data', () {
        final result = A2UIActionResult.success(testAction);

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.data, isEmpty);
        expect(result.action, equals(testAction));
      });
    });

    group('Failure Results', () {
      test('creates failure result', () {
        const errorMessage = 'Action failed';
        final result = A2UIActionResult.failure(testAction, errorMessage);

        expect(result.success, isFalse);
        expect(result.error, equals(errorMessage));
        expect(result.data, isEmpty);
        expect(result.action, equals(testAction));
      });
    });

    group('Equality', () {
      test('results with same properties are equal', () {
        final result1 = A2UIActionResult.success(testAction, {'key': 'value'});
        final result2 = A2UIActionResult.success(testAction, {'key': 'value'});

        expect(result1, equals(result2));
      });

      test('results with different properties are not equal', () {
        final result1 = A2UIActionResult.success(testAction);
        final result2 = A2UIActionResult.failure(testAction, 'Error');

        expect(result1, isNot(equals(result2)));
      });
    });
  });

  group('A2UIActionType', () {
    test('fromAction identifies router actions', () {
      expect(A2UIActionType.fromAction('router.restart'), equals(A2UIActionType.router));
      expect(A2UIActionType.fromAction('router.factoryReset'), equals(A2UIActionType.router));
    });

    test('fromAction identifies device actions', () {
      expect(A2UIActionType.fromAction('device.block'), equals(A2UIActionType.device));
      expect(A2UIActionType.fromAction('device.unblock'), equals(A2UIActionType.device));
    });

    test('fromAction identifies navigation actions', () {
      expect(A2UIActionType.fromAction('navigation.push'), equals(A2UIActionType.navigation));
    });

    test('fromAction identifies ui actions', () {
      expect(A2UIActionType.fromAction('ui.showConfirmation'), equals(A2UIActionType.ui));
    });

    test('fromAction returns null for unknown actions', () {
      expect(A2UIActionType.fromAction('unknown.action'), isNull);
      expect(A2UIActionType.fromAction('invalid'), isNull);
    });

    test('enum has correct prefix values', () {
      expect(A2UIActionType.router.prefix, equals('router'));
      expect(A2UIActionType.device.prefix, equals('device'));
      expect(A2UIActionType.wifi.prefix, equals('wifi'));
      expect(A2UIActionType.navigation.prefix, equals('navigation'));
      expect(A2UIActionType.ui.prefix, equals('ui'));
      expect(A2UIActionType.custom.prefix, equals('custom'));
    });
  });
}