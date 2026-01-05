import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/services/router_password_service.dart';

import '../../../mocks/test_data/router_password_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late RouterPasswordService service;
  late MockRouterRepository mockRepository;
  late MockFlutterSecureStorage mockStorage;

  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(JNAPAction.isAdminPasswordDefault);
    registerFallbackValue(CommandType.local);
    registerFallbackValue(
        JNAPTransactionBuilder(commands: const [], auth: false));
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    mockStorage = MockFlutterSecureStorage();
    service = RouterPasswordService(mockRepository, mockStorage);
  });

  group('RouterPasswordService - fetchPasswordConfiguration', () {
    test('returns correct data when password is default', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer(
              (_) async => RouterPasswordTestData.createFetchConfiguredSuccess(
                    isAdminPasswordDefault: true,
                    isAdminPasswordSetByUser: false,
                  ));
      when(() => mockStorage.read(key: pLocalPassword))
          .thenAnswer((_) async => 'stored_password');

      // Act
      final result = await service.fetchPasswordConfiguration();

      // Assert
      expect(result['isDefault'], true);
      expect(result['isSetByUser'], false);
      expect(result['hint'], ''); // No hint when not set by user
      expect(result['storedPassword'], 'stored_password');
      verify(() => mockRepository.transaction(any(),
          fetchRemote: any(named: 'fetchRemote'))).called(1);
      verify(() => mockStorage.read(key: pLocalPassword)).called(1);
      verifyNever(() => mockRepository.send(any()));
    });

    test('returns correct data when password is set by user', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer(
              (_) async => RouterPasswordTestData.createFetchConfiguredSuccess(
                    isAdminPasswordDefault: false,
                    isAdminPasswordSetByUser: true,
                  ));
      when(() => mockRepository.send(any())).thenAnswer((_) async =>
          RouterPasswordTestData.createPasswordHintSuccess(hint: 'Test hint'));
      when(() => mockStorage.read(key: pLocalPassword))
          .thenAnswer((_) async => 'user_password');

      // Act
      final result = await service.fetchPasswordConfiguration();

      // Assert
      expect(result['isDefault'], false);
      expect(result['isSetByUser'], true);
      expect(result['hint'], 'Test hint');
      expect(result['storedPassword'], 'user_password');
    });

    test('includes hint when password is not default', () async {
      // Arrange
      when(() => mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer(
              (_) async => RouterPasswordTestData.createFetchConfiguredSuccess(
                    isAdminPasswordDefault: false,
                    isAdminPasswordSetByUser: true,
                  ));
      when(() => mockRepository.send(any())).thenAnswer((_) async =>
          RouterPasswordTestData.createPasswordHintSuccess(hint: 'My hint'));
      when(() => mockStorage.read(key: pLocalPassword))
          .thenAnswer((_) async => null);

      // Act
      final result = await service.fetchPasswordConfiguration();

      // Assert
      expect(result['hint'], 'My hint');
      verify(() => mockRepository.send(any())).called(1);
    });

    test('reads stored password from FlutterSecureStorage', () async {
      // Arrange
      when(() =>
          mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote'))).thenAnswer(
          (_) async => RouterPasswordTestData.createFetchConfiguredSuccess());
      when(() => mockRepository.send(any())).thenAnswer(
          (_) async => RouterPasswordTestData.createPasswordHintSuccess());
      when(() => mockStorage.read(key: pLocalPassword))
          .thenAnswer((_) async => 'secure_password_123');

      // Act
      final result = await service.fetchPasswordConfiguration();

      // Assert
      expect(result['storedPassword'], 'secure_password_123');
      verify(() => mockStorage.read(key: pLocalPassword)).called(1);
    });

    test('throws ServiceError when JNAP call fails', () async {
      // Arrange
      final jnapError = RouterPasswordTestData.createGenericError(
        errorCode: 'ErrorNetworkTimeout',
      );
      when(() => mockRepository.transaction(any(),
          fetchRemote: any(named: 'fetchRemote'))).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.fetchPasswordConfiguration(),
        throwsA(isA<ServiceError>()),
      );
    });

    test('throws StorageError when FlutterSecureStorage read fails', () async {
      // Arrange
      when(() =>
          mockRepository.transaction(any(),
              fetchRemote: any(named: 'fetchRemote'))).thenAnswer(
          (_) async => RouterPasswordTestData.createFetchConfiguredSuccess());
      when(() => mockRepository.send(any())).thenAnswer(
          (_) async => RouterPasswordTestData.createPasswordHintSuccess());
      when(() => mockStorage.read(key: pLocalPassword))
          .thenThrow(Exception('Storage read error'));

      // Act & Assert
      expect(
        () => service.fetchPasswordConfiguration(),
        throwsA(isA<StorageError>()),
      );
    });
  });

  group('RouterPasswordService - setPasswordWithResetCode', () {
    test('succeeds with valid code', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                type: any(named: 'type'),
              ))
          .thenAnswer(
              (_) async => RouterPasswordTestData.createSetPasswordSuccess());

      // Act
      await service.setPasswordWithResetCode(
        'newPassword123',
        'My hint',
        'ABCD-1234',
      );

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setupSetAdminPassword,
            data: {
              'adminPassword': 'newPassword123',
              'passwordHint': 'My hint',
              'resetCode': 'ABCD-1234',
            },
            type: CommandType.local,
          )).called(1);
    });

    test('throws ServiceError with invalid code', () async {
      // Arrange
      final jnapError = RouterPasswordTestData.createGenericError(
        errorCode: 'ErrorInvalidResetCode',
      );
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
            type: any(named: 'type'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.setPasswordWithResetCode(
          'password',
          'hint',
          'INVALID',
        ),
        throwsA(isA<ServiceError>()),
      );
    });

    test('throws ServiceError when JNAP call fails', () async {
      // Arrange
      final jnapError = RouterPasswordTestData.createGenericError();
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
            type: any(named: 'type'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.setPasswordWithResetCode(
          'password',
          'hint',
          'code',
        ),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('RouterPasswordService - setPasswordWithCredentials', () {
    test('succeeds with valid credentials', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                type: any(named: 'type'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => RouterPasswordTestData.createSetPasswordSuccess());

      // Act
      await service.setPasswordWithCredentials('newPassword456', 'New hint');

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.coreSetAdminPassword,
            data: {
              'adminPassword': 'newPassword456',
              'passwordHint': 'New hint',
            },
            type: CommandType.local,
            auth: true,
          )).called(1);
    });

    test('includes hint in JNAP payload when provided', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
                type: any(named: 'type'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => RouterPasswordTestData.createSetPasswordSuccess());

      // Act
      await service.setPasswordWithCredentials('password', 'Custom hint');

      // Assert
      final captured = verify(() => mockRepository.send(
            JNAPAction.coreSetAdminPassword,
            data: captureAny(named: 'data'),
            type: any(named: 'type'),
            auth: any(named: 'auth'),
          )).captured;
      expect(captured.first['passwordHint'], 'Custom hint');
    });

    test('throws ServiceError on authentication failure', () async {
      // Arrange
      final jnapError = RouterPasswordTestData.createGenericError(
        errorCode: 'ErrorAuthenticationFailed',
      );
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
            type: any(named: 'type'),
            auth: any(named: 'auth'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.setPasswordWithCredentials('password'),
        throwsA(isA<ServiceError>()),
      );
    });

    test('throws ServiceError when JNAP call fails', () async {
      // Arrange
      final jnapError = RouterPasswordTestData.createGenericError();
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
            type: any(named: 'type'),
            auth: any(named: 'auth'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.setPasswordWithCredentials('password'),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('RouterPasswordService - verifyRecoveryCode', () {
    test('returns isValid=true for valid code', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                data: any(named: 'data'),
              ))
          .thenAnswer(
              (_) async => RouterPasswordTestData.createVerifyCodeSuccess());

      // Act
      final result = await service.verifyRecoveryCode('VALID-CODE');

      // Assert
      expect(result['isValid'], true);
      expect(result['attemptsRemaining'], null);
    });

    test('returns isValid=false with attemptsRemaining for invalid code',
        () async {
      // Arrange
      final jnapError = RouterPasswordTestData.createVerifyCodeError(
        attemptsRemaining: 2,
      );
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
          )).thenThrow(jnapError);

      // Act
      final result = await service.verifyRecoveryCode('INVALID-CODE');

      // Assert
      expect(result['isValid'], false);
      expect(result['attemptsRemaining'], 2);
    });

    test('returns isValid=false and attemptsRemaining=0 for exhausted attempts',
        () async {
      // Arrange
      final jnapError = RouterPasswordTestData.createVerifyCodeExhaustedError();
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
          )).thenThrow(jnapError);

      // Act
      final result = await service.verifyRecoveryCode('CODE');

      // Assert
      expect(result['isValid'], false);
      expect(result['attemptsRemaining'], 0);
    });

    test('throws ServiceError when JNAP call fails with unknown error',
        () async {
      // Arrange
      final jnapError = RouterPasswordTestData.createGenericError(
        errorCode: 'ErrorNetworkFailure',
      );
      when(() => mockRepository.send(
            any(),
            data: any(named: 'data'),
          )).thenThrow(jnapError);

      // Act & Assert
      expect(
        () => service.verifyRecoveryCode('CODE'),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  group('RouterPasswordService - persistPassword', () {
    test('successfully writes to FlutterSecureStorage', () async {
      // Arrange
      when(() => mockStorage.write(
            key: pLocalPassword,
            value: any(named: 'value'),
          )).thenAnswer((_) async => {});

      // Act
      await service.persistPassword('mySecurePassword');

      // Assert
      verify(() => mockStorage.write(
            key: pLocalPassword,
            value: 'mySecurePassword',
          )).called(1);
    });

    test('throws StorageError when FlutterSecureStorage write fails', () async {
      // Arrange
      when(() => mockStorage.write(
            key: pLocalPassword,
            value: any(named: 'value'),
          )).thenThrow(Exception('Storage write error'));

      // Act & Assert
      expect(
        () => service.persistPassword('password'),
        throwsA(isA<StorageError>()),
      );
    });
  });
}
