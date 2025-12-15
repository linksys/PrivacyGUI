import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/instant_admin/providers/router_password_provider.dart';
import 'package:privacy_gui/page/instant_admin/services/router_password_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MockRouterPasswordService extends Mock implements RouterPasswordService {}

void main() {
  late MockRouterPasswordService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockRouterPasswordService();
  });

  tearDown(() {
    container.dispose();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        routerPasswordServiceProvider.overrideWithValue(mockService),
        // Note: authProvider is not mocked - tests always pass explicit password
      ],
    );
  }

  group('RouterPasswordNotifier - fetch()', () {
    test('updates state on successful service call', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.fetchPasswordConfiguration()).thenAnswer(
        (_) async => {
          'isDefault': false,
          'isSetByUser': true,
          'hint': 'Test hint',
          'storedPassword': 'test123',
        },
      );

      // Act
      await container.read(routerPasswordProvider.notifier).fetch();

      // Assert
      final state = container.read(routerPasswordProvider);
      expect(state.isDefault, false);
      expect(state.isSetByUser, true);
      expect(state.hint, 'Test hint');
      expect(state.adminPassword, 'test123');
      verify(() => mockService.fetchPasswordConfiguration()).called(1);
    });

    test('updates state.isDefault correctly from service response', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.fetchPasswordConfiguration()).thenAnswer(
        (_) async => {
          'isDefault': true,
          'isSetByUser': false,
          'hint': '',
          'storedPassword': '',
        },
      );

      // Act
      await container.read(routerPasswordProvider.notifier).fetch();

      // Assert
      expect(container.read(routerPasswordProvider).isDefault, true);
    });

    test('updates state.isSetByUser correctly from service response', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.fetchPasswordConfiguration()).thenAnswer(
        (_) async => {
          'isDefault': false,
          'isSetByUser': true,
          'hint': 'hint',
          'storedPassword': 'pwd',
        },
      );

      // Act
      await container.read(routerPasswordProvider.notifier).fetch();

      // Assert
      expect(container.read(routerPasswordProvider).isSetByUser, true);
    });

    test('updates state.hint correctly from service response', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.fetchPasswordConfiguration()).thenAnswer(
        (_) async => {
          'isDefault': false,
          'isSetByUser': true,
          'hint': 'My password hint',
          'storedPassword': 'pwd',
        },
      );

      // Act
      await container.read(routerPasswordProvider.notifier).fetch();

      // Assert
      expect(container.read(routerPasswordProvider).hint, 'My password hint');
    });

    test('updates state.adminPassword from service response', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.fetchPasswordConfiguration()).thenAnswer(
        (_) async => {
          'isDefault': false,
          'isSetByUser': true,
          'hint': 'hint',
          'storedPassword': 'securePassword123',
        },
      );

      // Act
      await container.read(routerPasswordProvider.notifier).fetch();

      // Assert
      expect(container.read(routerPasswordProvider).adminPassword,
          'securePassword123');
    });

    test('rethrows JNAPError from service', () async {
      // Arrange
      container = createContainer();
      final jnapError = JNAPError(result: 'ErrorNetworkTimeout', error: null);
      when(() => mockService.fetchPasswordConfiguration()).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => container.read(routerPasswordProvider.notifier).fetch(),
        throwsA(isA<JNAPError>()),
      );
    });

    test('rethrows Exception from service', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.fetchPasswordConfiguration())
          .thenThrow(Exception('Storage error'));

      // Act & Assert
      expect(
        () => container.read(routerPasswordProvider.notifier).fetch(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('RouterPasswordNotifier - setAdminPasswordWithResetCode()', () {
    test('calls service with correct parameters', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.setPasswordWithResetCode(
            any(),
            any(),
            any(),
          )).thenAnswer((_) async => {});

      // Act
      await container
          .read(routerPasswordProvider.notifier)
          .setAdminPasswordWithResetCode('newPwd', 'hint', 'CODE-123');

      // Assert
      verify(() => mockService.setPasswordWithResetCode(
            'newPwd',
            'hint',
            'CODE-123',
          )).called(1);
      expect(container.read(routerPasswordProvider).error, null);
    });

    test('rethrows JNAPError from service', () async {
      // Arrange
      container = createContainer();
      final jnapError = JNAPError(result: 'ErrorInvalidResetCode', error: null);
      when(() => mockService.setPasswordWithResetCode(
            any(),
            any(),
            any(),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => container
            .read(routerPasswordProvider.notifier)
            .setAdminPasswordWithResetCode('pwd', 'hint', 'CODE'),
        throwsA(isA<JNAPError>()),
      );
    });
  });

  group('RouterPasswordNotifier - setAdminPasswordWithCredentials()', () {
    test('rethrows JNAPError from service', () async {
      // Arrange
      container = createContainer();
      final jnapError =
          JNAPError(result: 'ErrorAuthenticationFailed', error: null);
      when(() => mockService.setPasswordWithCredentials(any(), any()))
          .thenThrow(jnapError);

      // Act & Assert
      expect(
        () => container
            .read(routerPasswordProvider.notifier)
            .setAdminPasswordWithCredentials('pwd', 'hint'),
        throwsA(isA<JNAPError>()),
      );
    });

    // Note: Tests for successful scenarios require mocking AuthProvider.localLogin
    // which is complex due to its AsyncNotifier nature. The service delegation
    // is already tested above, and integration tests will cover the full flow.
  });

  group('RouterPasswordNotifier - checkRecoveryCode()', () {
    test('returns true for valid code', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.verifyRecoveryCode(any())).thenAnswer(
        (_) async => {
          'isValid': true,
          'attemptsRemaining': null,
        },
      );

      // Act
      final result = await container
          .read(routerPasswordProvider.notifier)
          .checkRecoveryCode('VALID-CODE');

      // Assert
      expect(result, true);
      expect(
          container.read(routerPasswordProvider).remainingErrorAttempts, null);
      expect(container.read(routerPasswordProvider).error, null);
    });

    test('returns false for invalid code', () async {
      // Arrange
      container = createContainer();
      when(() => mockService.verifyRecoveryCode(any())).thenAnswer(
        (_) async => {
          'isValid': false,
          'attemptsRemaining': 2,
        },
      );

      // Act
      final result = await container
          .read(routerPasswordProvider.notifier)
          .checkRecoveryCode('INVALID-CODE');

      // Assert
      expect(result, false);
    });

    test('updates state.remainingErrorAttempts from service response',
        () async {
      // Arrange
      container = createContainer();
      when(() => mockService.verifyRecoveryCode(any())).thenAnswer(
        (_) async => {
          'isValid': false,
          'attemptsRemaining': 1,
        },
      );

      // Act
      await container
          .read(routerPasswordProvider.notifier)
          .checkRecoveryCode('CODE');

      // Assert
      expect(container.read(routerPasswordProvider).remainingErrorAttempts, 1);
    });

    test('rethrows JNAPError from service', () async {
      // Arrange
      container = createContainer();
      final jnapError = JNAPError(result: 'ErrorNetworkFailure', error: null);
      when(() => mockService.verifyRecoveryCode(any())).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => container
            .read(routerPasswordProvider.notifier)
            .checkRecoveryCode('CODE'),
        throwsA(isA<JNAPError>()),
      );
    });
  });

  group('RouterPasswordNotifier - State Flags', () {
    test('setEdited() updates state.hasEdited correctly', () {
      // Arrange
      container = createContainer();

      // Act
      container.read(routerPasswordProvider.notifier).setEdited(true);

      // Assert
      expect(container.read(routerPasswordProvider).hasEdited, true);
    });

    test('setValidate() updates state.isValid correctly', () {
      // Arrange
      container = createContainer();

      // Act
      container.read(routerPasswordProvider.notifier).setValidate(true);

      // Assert
      expect(container.read(routerPasswordProvider).isValid, true);
    });
  });
}
