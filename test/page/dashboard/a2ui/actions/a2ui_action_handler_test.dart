import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action_handler.dart';
import 'package:privacy_gui/route/router_provider.dart';

// Mock WidgetRef for testing
class MockWidgetRef extends Mock implements WidgetRef {
  final Map<ProviderListenable, Object> overrides = {};

  @override
  T read<T>(ProviderListenable<T> provider) {
    debugPrint('🧐 MockWidgetRef: Reading provider $provider');
    if (overrides.containsKey(provider)) {
      return overrides[provider] as T;
    }

    // Check by runtime type/string representation for providers to avoid identity issues in mocks
    for (final entry in overrides.entries) {
      if (entry.key.toString() == provider.toString()) {
        return entry.value as T;
      }
    }

    throw UnsupportedError(
        'MockWidgetRef: Provider $provider not overridden. Available: ${overrides.keys}');
  }
}

// Mock GoRouter for testing
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  // Register fallback values for mocktail if needed
  setUpAll(() {
    registerFallbackValue(A2UIAction(action: 'unknown'));
  });

  group('RouterActionHandler', () {
    late RouterActionHandler handler;
    late MockWidgetRef mockRef;

    setUp(() {
      handler = RouterActionHandler();
      mockRef = MockWidgetRef();
    });

    group('Action Type and Validation', () {
      test('has correct action type', () {
        expect(handler.actionType, equals('router'));
      });

      test('canHandle identifies router actions correctly', () {
        expect(handler.canHandle(A2UIAction(action: 'router.restart')), isTrue);
        expect(handler.canHandle(A2UIAction(action: 'router.factoryReset')),
            isTrue);
        expect(handler.canHandle(A2UIAction(action: 'device.block')), isFalse);
        expect(handler.canHandle(A2UIAction(action: 'ui.showDialog')), isFalse);
      });

      test('validates supported actions', () {
        expect(handler.validateAction(A2UIAction(action: 'router.restart')),
            isTrue);
        expect(
            handler.validateAction(A2UIAction(action: 'router.factoryReset')),
            isTrue);
        expect(handler.validateAction(A2UIAction(action: 'router.connect')),
            isTrue);
        expect(handler.validateAction(A2UIAction(action: 'router.disconnect')),
            isTrue);
        expect(handler.validateAction(A2UIAction(action: 'router.unsupported')),
            isFalse);
      });
    });

    group('Action Execution', () {
      test('handles restart action successfully', () async {
        final action = A2UIAction(action: 'router.restart');
        final result = await handler.handle(action, mockRef);

        expect(result.success, isTrue);
        expect(result.error, isNull);
        expect(result.data['message'], contains('Router restart initiated'));
        expect(result.data['estimatedTime'], equals(120));
        expect(result.action, equals(action));
      });

      test('handles factory reset action successfully', () async {
        final action = A2UIAction(action: 'router.factoryReset');
        final result = await handler.handle(action, mockRef);

        expect(result.success, isTrue);
        expect(result.data['message'], contains('Factory reset initiated'));
        expect(result.data['estimatedTime'], equals(300));
      });
    });
  });

  group('DeviceActionHandler', () {
    late DeviceActionHandler handler;
    late MockWidgetRef mockRef;

    setUp(() {
      handler = DeviceActionHandler();
      mockRef = MockWidgetRef();
    });

    group('Action Type and Validation', () {
      test('has correct action type', () {
        expect(handler.actionType, equals('device'));
      });

      test('canHandle identifies device actions correctly', () {
        expect(handler.canHandle(A2UIAction(action: 'device.block')), isTrue);
        expect(
            handler.canHandle(A2UIAction(action: 'router.restart')), isFalse);
      });
    });

    group('Action Execution', () {
      test('handles block action with device ID', () async {
        final action =
            A2UIAction(action: 'device.block', params: {'deviceId': 'dev123'});
        final result = await handler.handle(action, mockRef);

        expect(result.success, isTrue);
        expect(result.data['deviceId'], equals('dev123'));
        expect(result.data['message'], contains('Device blocked'));
      });

      test('fails block action without device ID', () async {
        final action = A2UIAction(action: 'device.block');
        final result = await handler.handle(action, mockRef);

        expect(result.success, isFalse);
        expect(result.error, contains('Device ID is required'));
      });

      test('handles unblock action successfully', () async {
        final action = A2UIAction(
            action: 'device.unblock', params: {'deviceId': 'dev456'});
        final result = await handler.handle(action, mockRef);

        expect(result.success, isTrue);
        expect(result.data['deviceId'], equals('dev456'));
      });

      test('handles set speed limit successfully', () async {
        final action = A2UIAction(action: 'device.setSpeedLimit', params: {
          'deviceId': 'dev789',
          'speedLimit': 50,
        });
        final result = await handler.handle(action, mockRef);

        expect(result.success, isTrue);
        expect(result.data['speedLimit'], equals(50));
      });

      test('handles show details (UI action)', () async {
        final action = A2UIAction(
            action: 'device.showDetails', params: {'deviceId': 'device123'});
        final result = await handler.handle(action, mockRef);

        expect(result.success, isTrue);
        expect(result.data['navigateTo'], equals('/device-details/device123'));
        expect(result.data['deviceId'], equals('device123'));
      });

      test('fails show details without device ID', () async {
        final action = A2UIAction(action: 'device.showDetails');
        final result = await handler.handle(action, mockRef);

        expect(result.success, isFalse);
        expect(result.error, contains('Device ID is required'));
      });
    });

    test('fails for unsupported device actions', () async {
      final action = A2UIAction(action: 'device.unsupported');
      final result = await handler.handle(action, mockRef);

      expect(result.success, isFalse);
      expect(result.error, contains('Unsupported device action'));
    });
  });

  group('NavigationActionHandler', () {
    late NavigationActionHandler handler;
    late MockWidgetRef mockRef;
    late MockGoRouter mockRouter;

    setUp(() {
      handler = NavigationActionHandler();
      mockRef = MockWidgetRef();
      mockRouter = MockGoRouter();

      // Setup default mock behavior for router provider
      mockRef.overrides[routerProvider] = mockRouter;

      // Stub router methods
      when(() => mockRouter.pushNamed(any())).thenAnswer((_) async => null);
      when(() => mockRouter.pushReplacementNamed(any()))
          .thenAnswer((_) async => null);
      when(() => mockRouter.pop()).thenReturn(null);
    });

    test('has correct action type', () {
      expect(handler.actionType, equals('navigation'));
    });

    test('handles push action with route', () async {
      final action = A2UIAction(
        action: 'navigation.push',
        params: {'route': '/settings'},
      );
      final result = await handler.handle(action, mockRef);
      expect(result.success, isTrue);
      verify(() => mockRouter.pushNamed('/settings')).called(1);
    });

    test('fails push action without route', () async {
      final action = A2UIAction(action: 'navigation.push');
      final result = await handler.handle(action, mockRef);

      expect(result.success, isFalse);
      expect(result.error, contains('Route is required'));
    });

    test('handles pop action', () async {
      final action = A2UIAction(action: 'navigation.pop');
      final result = await handler.handle(action, mockRef);
      expect(result.success, isTrue);
      verify(() => mockRouter.pop()).called(1);
    });

    test('handles replace action with route', () async {
      final action = A2UIAction(
        action: 'navigation.replace',
        params: {'route': '/dashboard'},
      );
      final result = await handler.handle(action, mockRef);
      expect(result.success, isTrue);
      verify(() => mockRouter.pushReplacementNamed('/dashboard')).called(1);
    });
  });

  group('UIActionHandler', () {
    late UIActionHandler handler;
    late MockWidgetRef mockRef;

    setUp(() {
      handler = UIActionHandler();
      mockRef = MockWidgetRef();
    });

    test('has correct action type', () {
      expect(handler.actionType, equals('ui'));
    });

    test('handles show confirmation with custom parameters', () async {
      final action = A2UIAction(
        action: 'ui.showConfirmation',
        params: {
          'title': 'Custom Title',
          'message': 'Custom message',
        },
      );
      final result = await handler.handle(action, mockRef);

      expect(result.success, isTrue);
      expect(result.data['dialogType'], equals('confirmation'));
      expect(result.data['title'], equals('Custom Title'));
      expect(result.data['message'], equals('Custom message'));
    });

    test('handles show confirmation with default parameters', () async {
      final action = A2UIAction(action: 'ui.showConfirmation');
      final result = await handler.handle(action, mockRef);

      expect(result.success, isTrue);
      expect(result.data['title'], equals('Confirmation'));
      expect(result.data['message'], equals('Are you sure?'));
    });

    test('handles show snackbar with custom message', () async {
      final action = A2UIAction(
        action: 'ui.showSnackbar',
        params: {'message': 'Custom snackbar'},
      );
      final result = await handler.handle(action, mockRef);

      expect(result.success, isTrue);
      expect(result.data['snackbarMessage'], equals('Custom snackbar'));
    });

    test('handles show snackbar with default message', () async {
      final action = A2UIAction(action: 'ui.showSnackbar');
      final result = await handler.handle(action, mockRef);

      expect(result.success, isTrue);
      expect(result.data['snackbarMessage'], equals('Action completed'));
    });

    test('handles refresh action', () async {
      final action = A2UIAction(action: 'ui.refresh');
      final result = await handler.handle(action, mockRef);

      expect(result.success, isTrue);
      expect(result.data['message'], contains('Data refresh initiated'));
    });

    test('fails for unsupported UI actions', () async {
      final action = A2UIAction(action: 'ui.unsupported');
      final result = await handler.handle(action, mockRef);

      expect(result.success, isFalse);
      expect(result.error, contains('Unsupported UI action'));
    });
  });
}
