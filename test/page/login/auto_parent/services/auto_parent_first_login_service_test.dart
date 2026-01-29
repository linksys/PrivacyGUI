import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/login/auto_parent/services/auto_parent_first_login_service.dart';

import 'package:privacy_gui/core/retry_strategy/retry.dart'; // import RetryStrategy

import '../../../../mocks/test_data/auto_parent_first_login_test_data.dart';

// Mocks
class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late AutoParentFirstLoginService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(JNAPAction.setUserAcknowledgedAutoConfiguration);
    registerFallbackValue(CacheLevel.noCache);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    // Use LinearBackoffRetryStrategy with 0 delay for testing to speed up tests
    final testRetryStrategy = LinearBackoffRetryStrategy(
      maxRetries: 5,
      initialDelay: Duration.zero,
      increment: Duration.zero,
    );
    service = AutoParentFirstLoginService(
      mockRepository,
      retryStrategy: testRetryStrategy,
    );
  });

  // ===========================================================================
  // User Story 1 - setUserAcknowledgedAutoConfiguration Tests (T005)
  // ===========================================================================

  group('AutoParentFirstLoginService - setUserAcknowledgedAutoConfiguration',
      () {
    test('sends JNAP action and awaits response', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.setUserAcknowledgedAutoConfiguration,
                fetchRemote: true,
                cacheLevel: CacheLevel.noCache,
                data: {},
                auth: true,
              ))
          .thenAnswer(
              (_) async => AutoParentFirstLoginTestData.createSetSuccess());

      // Act
      await service.setUserAcknowledgedAutoConfiguration();

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setUserAcknowledgedAutoConfiguration,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            data: {},
            auth: true,
          )).called(1);
    });

    test('throws ServiceError on JNAPError', () async {
      // Arrange
      when(() => mockRepository.send(
            JNAPAction.setUserAcknowledgedAutoConfiguration,
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenThrow(const JNAPError(result: '_ErrorUnauthorized'));

      // Act & Assert
      expect(
        () => service.setUserAcknowledgedAutoConfiguration(),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  // ===========================================================================
  // User Story 1 - setFirmwareUpdatePolicy Tests (T006, T007)
  // ===========================================================================

  group('AutoParentFirstLoginService - setFirmwareUpdatePolicy', () {
    test('fetches settings and sets auto-update policy', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getFirmwareUpdateSettings,
                fetchRemote: true,
                auth: true,
              ))
          .thenAnswer((_) async =>
              AutoParentFirstLoginTestData.createFirmwareUpdateSettingsSuccess(
                updatePolicy: 'Manual',
                startMinute: 60,
                durationMinutes: 180,
              ));

      when(() => mockRepository.send(
                JNAPAction.setFirmwareUpdateSettings,
                fetchRemote: true,
                cacheLevel: CacheLevel.noCache,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => AutoParentFirstLoginTestData.createSetSuccess());

      // Act
      await service.setFirmwareUpdatePolicy();

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.getFirmwareUpdateSettings,
            fetchRemote: true,
            auth: true,
          )).called(1);

      verify(() => mockRepository.send(
            JNAPAction.setFirmwareUpdateSettings,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            data: {
              'updatePolicy': 'AutomaticallyCheckAndInstall',
              'autoUpdateWindow': {
                'startMinute': 60,
                'durationMinutes': 180,
              },
            },
            auth: true,
          )).called(1);
    });

    test('uses default settings on fetch failure', () async {
      // Arrange - use thenAnswer with Future.error for proper async error handling
      when(() => mockRepository.send(
                JNAPAction.getFirmwareUpdateSettings,
                fetchRemote: true,
                auth: true,
              ))
          .thenAnswer(
              (_) => Future.error(const JNAPError(result: 'ErrorUnknown')));

      when(() => mockRepository.send(
                JNAPAction.setFirmwareUpdateSettings,
                fetchRemote: true,
                cacheLevel: CacheLevel.noCache,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => AutoParentFirstLoginTestData.createSetSuccess());

      // Act
      await service.setFirmwareUpdatePolicy();

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setFirmwareUpdateSettings,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
            data: {
              'updatePolicy': 'AutomaticallyCheckAndInstall',
              'autoUpdateWindow': {
                'startMinute': 0,
                'durationMinutes': 240,
              },
            },
            auth: true,
          )).called(1);
    });

    test('throws ServiceError on save failure', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getFirmwareUpdateSettings,
                fetchRemote: true,
                auth: true,
              ))
          .thenAnswer((_) async => AutoParentFirstLoginTestData
              .createFirmwareUpdateSettingsSuccess());

      when(() => mockRepository.send(
            JNAPAction.setFirmwareUpdateSettings,
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenThrow(const JNAPError(result: 'ErrorUnknown'));

      // Act & Assert
      expect(
        () => service.setFirmwareUpdatePolicy(),
        throwsA(isA<ServiceError>()),
      );
    });
  });

  // ===========================================================================
  // User Story 1 - checkInternetConnection Tests (T008, T009, T010)
  // ===========================================================================

  group('AutoParentFirstLoginService - checkInternetConnection', () {
    test('returns true when connected', () async {
      // Arrange
      when(() => mockRepository.send(
            JNAPAction.getInternetConnectionStatus,
            fetchRemote: true,
            auth: true,
          )).thenAnswer((_) async => AutoParentFirstLoginTestData
              .createInternetConnectionStatusSuccess(
            connectionStatus: 'InternetConnected',
          ));

      // Act
      final result = await service.checkInternetConnection();

      // Assert
      expect(result, isTrue);
    });

    test('returns false after retries exhausted', () async {
      // Arrange - always return disconnected
      when(() => mockRepository.send(
            JNAPAction.getInternetConnectionStatus,
            fetchRemote: true,
            auth: true,
          )).thenAnswer((_) async => AutoParentFirstLoginTestData
              .createInternetConnectionStatusSuccess(
            connectionStatus: 'InternetDisconnected',
          ));

      // Act
      final result = await service.checkInternetConnection();

      // Assert
      expect(result, isFalse);
    });

    test('returns false on error', () async {
      // Arrange
      when(() => mockRepository.send(
            JNAPAction.getInternetConnectionStatus,
            fetchRemote: true,
            auth: true,
          )).thenThrow(const JNAPError(result: 'ErrorUnknown'));

      // Act
      final result = await service.checkInternetConnection();

      // Assert
      expect(result, isFalse);
    });

    test('does not throw on JNAPError', () async {
      // Arrange
      when(() => mockRepository.send(
            JNAPAction.getInternetConnectionStatus,
            fetchRemote: true,
            auth: true,
          )).thenThrow(const JNAPError(result: '_ErrorUnauthorized'));

      // Act & Assert - should not throw
      final result = await service.checkInternetConnection();
      expect(result, isFalse);
    });
  });
}
