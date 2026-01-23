import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action_handler.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action_manager.dart';

// Mock classes for testing
class MockWidgetRef extends Mock implements WidgetRef {}

class TestActionHandler extends A2UIActionHandler {
  @override
  String get actionType => 'test';

  final bool _shouldSucceed;
  final bool _shouldValidate;
  final String? _customError;

  TestActionHandler({
    bool shouldSucceed = true,
    bool shouldValidate = true,
    String? customError,
  }) : _shouldSucceed = shouldSucceed,
       _shouldValidate = shouldValidate,
       _customError = customError;

  @override
  Future<A2UIActionResult> handle(A2UIAction action, WidgetRef ref) async {
    await Future.delayed(const Duration(milliseconds: 10)); // Simulate async work

    if (_customError != null) {
      throw Exception(_customError);
    }

    if (_shouldSucceed) {
      return A2UIActionResult.success(action, {'testResult': 'success'});
    } else {
      return A2UIActionResult.failure(action, 'Test failure');
    }
  }

  @override
  bool validateAction(A2UIAction action) => _shouldValidate;
}

void main() {
  group('A2UIActionManager', () {
    late A2UIActionManager manager;
    late MockWidgetRef mockRef;

    setUp(() {
      manager = A2UIActionManager();
      mockRef = MockWidgetRef();
    });

    tearDown(() {
      manager.dispose();
    });

    group('Handler Registration', () {
      test('registers default handlers on initialization', () {
        final actionTypes = manager.registeredActionTypes;

        expect(actionTypes, contains('router'));
        expect(actionTypes, contains('device'));
        expect(actionTypes, contains('navigation'));
        expect(actionTypes, contains('ui'));
      });

      test('registers custom handler', () {
        final testHandler = TestActionHandler();
        manager.registerHandler(testHandler);

        expect(manager.registeredActionTypes, contains('test'));
        expect(manager.isActionTypeSupported('test'), isTrue);
      });

      test('replaces existing handler for same action type', () {
        final handler1 = TestActionHandler();
        final handler2 = TestActionHandler(shouldSucceed: false);

        manager.registerHandler(handler1);
        manager.registerHandler(handler2);

        // Should only have one 'test' handler (the second one)
        expect(manager.registeredActionTypes.where((type) => type == 'test').length, equals(1));
      });
    });

    group('Action Execution', () {
      test('executes action successfully with registered handler', () async {
        final testHandler = TestActionHandler();
        manager.registerHandler(testHandler);

        final action = A2UIAction(action: 'test.sample');
        final result = await manager.executeAction(action, mockRef);

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.data['testResult'], equals('success'));
        expect(result.action, equals(action));
      });

      test('fails when no handler found for action', () async {
        final action = A2UIAction(action: 'unknown.action');
        final result = await manager.executeAction(action, mockRef);

        expect(result.success, isFalse);
        expect(result.error, contains('No handler found for action type'));
      });

      test('fails when action validation fails', () async {
        final testHandler = TestActionHandler(shouldValidate: false);
        manager.registerHandler(testHandler);

        final action = A2UIAction(action: 'test.invalid');
        final result = await manager.executeAction(action, mockRef);

        expect(result.success, isFalse);
        expect(result.error, contains('Action validation failed'));
      });

      test('handles handler execution failure', () async {
        final testHandler = TestActionHandler(shouldSucceed: false);
        manager.registerHandler(testHandler);

        final action = A2UIAction(action: 'test.fail');
        final result = await manager.executeAction(action, mockRef);

        expect(result.success, isFalse);
        expect(result.error, contains('Test failure'));
      });

      test('handles handler exception', () async {
        final testHandler = TestActionHandler(customError: 'Handler crashed');
        manager.registerHandler(testHandler);

        final action = A2UIAction(action: 'test.crash');
        final result = await manager.executeAction(action, mockRef);

        expect(result.success, isFalse);
        expect(result.error, contains('Execution error'));
        expect(result.error, contains('Handler crashed'));
      });
    });

    group('Action Results Stream', () {
      test('broadcasts action results to stream', () async {
        final testHandler = TestActionHandler();
        manager.registerHandler(testHandler);

        final results = <A2UIActionResult>[];
        final subscription = manager.results.listen(results.add);

        final action = A2UIAction(action: 'test.stream');
        await manager.executeAction(action, mockRef);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(results, hasLength(1));
        expect(results.first.success, isTrue);
        expect(results.first.action, equals(action));

        await subscription.cancel();
      });

      test('streams multiple action results', () async {
        final testHandler = TestActionHandler();
        manager.registerHandler(testHandler);

        final results = <A2UIActionResult>[];
        final subscription = manager.results.listen(results.add);

        final action1 = A2UIAction(action: 'test.first');
        final action2 = A2UIAction(action: 'test.second');

        await Future.wait([
          manager.executeAction(action1, mockRef),
          manager.executeAction(action2, mockRef),
        ]);

        await Future.delayed(const Duration(milliseconds: 50));

        expect(results, hasLength(2));

        await subscription.cancel();
      });
    });

    group('Action Callback Creation', () {
      test('creates action callback that executes actions', () async {
        final testHandler = TestActionHandler();
        manager.registerHandler(testHandler);

        final callback = manager.createActionCallback(mockRef, widgetId: 'test_widget');

        final callbackData = {
          'action': 'test.callback',
          'param1': 'value1',
          'param2': 42,
        };

        final results = <A2UIActionResult>[];
        final subscription = manager.results.listen(results.add);

        // Execute callback
        callback(callbackData);

        // Wait for async execution
        await Future.delayed(const Duration(milliseconds: 50));

        expect(results, hasLength(1));
        expect(results.first.success, isTrue);
        expect(results.first.action.action, equals('test.callback'));
        expect(results.first.action.params['param1'], equals('value1'));
        expect(results.first.action.params['param2'], equals(42));
        expect(results.first.action.sourceWidgetId, equals('test_widget'));

        await subscription.cancel();
      });

      test('handles callback without action parameter', () {
        final callback = manager.createActionCallback(mockRef);

        // Should not throw when called with invalid data
        expect(() => callback({'invalid': 'data'}), returnsNormally);
      });

      test('handles callback execution errors gracefully', () {
        final callback = manager.createActionCallback(mockRef);

        // Should not throw when called with null action
        expect(() => callback({'action': null}), returnsNormally);
      });
    });

    group('Default Handlers Integration', () {
      test('router handler is accessible', () {
        expect(manager.isActionTypeSupported('router'), isTrue);
      });

      test('device handler is accessible', () {
        expect(manager.isActionTypeSupported('device'), isTrue);
      });

      test('navigation handler is accessible', () {
        expect(manager.isActionTypeSupported('navigation'), isTrue);
      });

      test('ui handler is accessible', () {
        expect(manager.isActionTypeSupported('ui'), isTrue);
      });

      test('executes router restart action through default handler', () async {
        final action = A2UIAction(action: 'router.restart');
        final result = await manager.executeAction(action, mockRef);

        expect(result.success, isTrue);
        expect(result.data['message'], contains('Router restart initiated'));
      });
    });
  });

  group('A2UISecurityContext', () {
    group('Action Permission Checking', () {
      test('development context allows all actions', () {
        const context = A2UISecurityContext.development;

        expect(context.canExecuteAction('router.restart'), isTrue);
        expect(context.canExecuteAction('device.block'), isTrue);
        expect(context.canExecuteAction('custom.action'), isTrue);
        expect(context.canExecuteAction('malicious.action'), isTrue);
      });

      test('production context restricts actions', () {
        const context = A2UISecurityContext.production;

        // Allowed actions
        expect(context.canExecuteAction('router.restart'), isTrue);
        expect(context.canExecuteAction('router.connect'), isTrue);
        expect(context.canExecuteAction('device.block'), isTrue);
        expect(context.canExecuteAction('navigation.push'), isTrue);
        expect(context.canExecuteAction('ui.showConfirmation'), isTrue);

        // Disallowed actions
        expect(context.canExecuteAction('router.factoryReset'), isFalse);
        expect(context.canExecuteAction('malicious.action'), isFalse);
        expect(context.canExecuteAction('custom.unknown'), isFalse);
      });

      test('wildcard patterns work correctly', () {
        const context = A2UISecurityContext(
          allowedActions: {'test.*', 'specific.action'},
        );

        expect(context.canExecuteAction('test.action1'), isTrue);
        expect(context.canExecuteAction('test.action2'), isTrue);
        expect(context.canExecuteAction('specific.action'), isTrue);
        expect(context.canExecuteAction('other.action'), isFalse);
      });
    });

    group('Data Path Permission Checking', () {
      test('development context allows all data paths', () {
        const context = A2UISecurityContext.development;

        expect(context.canAccessDataPath('router.status'), isTrue);
        expect(context.canAccessDataPath('device.list'), isTrue);
        expect(context.canAccessDataPath('sensitive.data'), isTrue);
      });

      test('production context restricts data paths', () {
        const context = A2UISecurityContext.production;

        // Allowed paths
        expect(context.canAccessDataPath('router.status'), isTrue);
        expect(context.canAccessDataPath('wifi.networks'), isTrue);
        expect(context.canAccessDataPath('device.count'), isTrue);

        // Disallowed paths
        expect(context.canAccessDataPath('admin.credentials'), isFalse);
        expect(context.canAccessDataPath('system.config'), isFalse);
      });

      test('wildcard patterns work for data paths', () {
        const context = A2UISecurityContext(
          allowedDataPaths: {'public.*', 'user.profile'},
        );

        expect(context.canAccessDataPath('public.info'), isTrue);
        expect(context.canAccessDataPath('public.status'), isTrue);
        expect(context.canAccessDataPath('user.profile'), isTrue);
        expect(context.canAccessDataPath('private.data'), isFalse);
      });
    });

    group('Custom Security Contexts', () {
      test('empty restrictions allow everything', () {
        const context = A2UISecurityContext();

        expect(context.canExecuteAction('any.action'), isTrue);
        expect(context.canAccessDataPath('any.path'), isTrue);
      });

      test('specific restrictions work correctly', () {
        const context = A2UISecurityContext(
          allowedActions: {'safe.action'},
          allowedDataPaths: {'safe.data'},
        );

        expect(context.canExecuteAction('safe.action'), isTrue);
        expect(context.canExecuteAction('unsafe.action'), isFalse);
        expect(context.canAccessDataPath('safe.data'), isTrue);
        expect(context.canAccessDataPath('unsafe.data'), isFalse);
      });
    });
  });
}