import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks/test_data/connectivity_test_data.dart';

/// Mock for RouterRepository
class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ConnectivityService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    // Register fallback values for Mocktail
    registerFallbackValue(JNAPAction.getDeviceInfo);
    registerFallbackValue(CommandType.local);
    registerFallbackValue(CacheLevel.noCache);
    registerFallbackValue(
        JNAPTransactionBuilder(commands: const [], auth: false));
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = ConnectivityService(mockRepository);
  });

  // ============================================================================
  // Phase 3 (US1): testRouterType Tests
  // ============================================================================

  group('ConnectivityService - testRouterType', () {
    // T008: testRouterType returns RouterType.behindManaged when serial numbers match
    test('T008: returns RouterType.behindManaged when serial numbers match',
        () async {
      // Arrange
      const testSerialNumber = 'ABC123456789';
      SharedPreferences.setMockInitialValues({pCurrentSN: testSerialNumber});

      when(() => mockRepository.send(
                any(),
                type: any(named: 'type'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer(
              (_) async => ConnectivityTestData.createGetDeviceInfoSuccess(
                    serialNumber: testSerialNumber,
                  ));

      // Act
      final result = await service.testRouterType('192.168.1.1');

      // Assert
      expect(result, RouterType.behindManaged);
      verify(() => mockRepository.send(
            JNAPAction.getDeviceInfo,
            type: CommandType.local,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    // T009: testRouterType returns RouterType.behind when serial numbers differ
    test('T009: returns RouterType.behind when serial numbers differ',
        () async {
      // Arrange
      const storedSerialNumber = 'ABC123456789';
      const differentSerialNumber = 'XYZ987654321';
      SharedPreferences.setMockInitialValues({pCurrentSN: storedSerialNumber});

      when(() => mockRepository.send(
                any(),
                type: any(named: 'type'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer(
              (_) async => ConnectivityTestData.createGetDeviceInfoSuccess(
                    serialNumber: differentSerialNumber,
                  ));

      // Act
      final result = await service.testRouterType('192.168.1.1');

      // Assert
      expect(result, RouterType.behind);
    });

    // T010: testRouterType returns RouterType.others when JNAP call fails
    test('T010: returns RouterType.others when JNAP call fails', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({pCurrentSN: 'ABC123456789'});

      when(() => mockRepository.send(
                any(),
                type: any(named: 'type'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async =>
              throw ConnectivityTestData.createGetDeviceInfoError());

      // Act
      final result = await service.testRouterType('192.168.1.1');

      // Assert
      expect(result, RouterType.others);
    });

    // T011: testRouterType returns RouterType.others when serial number is empty
    test('T011: returns RouterType.others when serial number is empty',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({pCurrentSN: 'ABC123456789'});

      when(() => mockRepository.send(
                any(),
                type: any(named: 'type'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async =>
              ConnectivityTestData.createGetDeviceInfoEmptySerial());

      // Act
      final result = await service.testRouterType('192.168.1.1');

      // Assert
      expect(result, RouterType.others);
    });

    // Additional edge case: testRouterType handles null gateway IP gracefully
    test('returns RouterType.others when gateway IP is null and JNAP fails',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});

      when(() => mockRepository.send(
                any(),
                type: any(named: 'type'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async =>
              throw ConnectivityTestData.createGetDeviceInfoError());

      // Act
      final result = await service.testRouterType(null);

      // Assert
      expect(result, RouterType.others);
    });

    // Additional edge case: testRouterType handles missing stored serial number
    test('returns RouterType.behind when stored serial number is missing',
        () async {
      // Arrange
      SharedPreferences.setMockInitialValues({}); // No stored serial number

      when(() => mockRepository.send(
                any(),
                type: any(named: 'type'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer(
              (_) async => ConnectivityTestData.createGetDeviceInfoSuccess(
                    serialNumber: 'ABC123456789',
                  ));

      // Act
      final result = await service.testRouterType('192.168.1.1');

      // Assert
      // Serial numbers don't match (null != 'ABC123456789'), so should return behind
      expect(result, RouterType.behind);
    });
  });

  // ============================================================================
  // Phase 4 (US2): fetchRouterConfiguredData Tests
  // ============================================================================

  group('ConnectivityService - fetchRouterConfiguredData', () {
    /// Helper to create JNAPTransactionSuccessWrap from test data
    JNAPTransactionSuccessWrap createTransactionSuccessWrap(
        List<MapEntry<JNAPAction, JNAPResult>> data) {
      return JNAPTransactionSuccessWrap(
        result: 'OK',
        data: data,
      );
    }

    // T014: fetchRouterConfiguredData returns correct data on success
    test('T014: returns correct RouterConfiguredData on success', () async {
      // Arrange
      when(() => mockRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            timeoutMs: any(named: 'timeoutMs'),
            retries: any(named: 'retries'),
            pollConfig: any(named: 'pollConfig'),
          )).thenAnswer((_) async => createTransactionSuccessWrap(
            ConnectivityTestData.createFetchConfiguredSuccess(
              isAdminPasswordDefault: false,
              isAdminPasswordSetByUser: true,
            ),
          ));

      // Act
      final result = await service.fetchRouterConfiguredData();

      // Assert
      expect(result.isDefaultPassword, false);
      expect(result.isSetByUser, true);
      verify(() => mockRepository.transaction(
            any(),
            fetchRemote: true,
            cacheLevel: any(named: 'cacheLevel'),
            timeoutMs: any(named: 'timeoutMs'),
            retries: any(named: 'retries'),
            pollConfig: any(named: 'pollConfig'),
          )).called(1);
    });

    // T015: fetchRouterConfiguredData throws ServiceError on JNAP failure
    test('T015: throws ServiceError on JNAP failure', () async {
      // Arrange
      when(() => mockRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            timeoutMs: any(named: 'timeoutMs'),
            retries: any(named: 'retries'),
            pollConfig: any(named: 'pollConfig'),
          )).thenThrow(ConnectivityTestData.createFetchConfiguredError());

      // Act & Assert
      expect(
        () => service.fetchRouterConfiguredData(),
        throwsA(isA<ServiceError>()),
      );
    });

    // T016: fetchRouterConfiguredData handles default password state
    test('T016: handles default password state correctly', () async {
      // Arrange
      when(() => mockRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            timeoutMs: any(named: 'timeoutMs'),
            retries: any(named: 'retries'),
            pollConfig: any(named: 'pollConfig'),
          )).thenAnswer((_) async => createTransactionSuccessWrap(
            ConnectivityTestData.createFetchConfiguredDefaultPassword(),
          ));

      // Act
      final result = await service.fetchRouterConfiguredData();

      // Assert
      expect(result.isDefaultPassword, true);
      expect(result.isSetByUser, false);
    });

    // T017: fetchRouterConfiguredData handles user-set password state
    test('T017: handles user-set password state correctly', () async {
      // Arrange
      when(() => mockRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            timeoutMs: any(named: 'timeoutMs'),
            retries: any(named: 'retries'),
            pollConfig: any(named: 'pollConfig'),
          )).thenAnswer((_) async => createTransactionSuccessWrap(
            ConnectivityTestData.createFetchConfiguredUserSetPassword(),
          ));

      // Act
      final result = await service.fetchRouterConfiguredData();

      // Assert
      expect(result.isDefaultPassword, false);
      expect(result.isSetByUser, true);
    });

    // Additional edge case: handles both flags being true
    test('handles both isDefaultPassword and isSetByUser being true', () async {
      // Arrange - unusual but possible state
      when(() => mockRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            timeoutMs: any(named: 'timeoutMs'),
            retries: any(named: 'retries'),
            pollConfig: any(named: 'pollConfig'),
          )).thenAnswer((_) async => createTransactionSuccessWrap(
            ConnectivityTestData.createFetchConfiguredSuccess(
              isAdminPasswordDefault: true,
              isAdminPasswordSetByUser: true,
            ),
          ));

      // Act
      final result = await service.fetchRouterConfiguredData();

      // Assert
      expect(result.isDefaultPassword, true);
      expect(result.isSetByUser, true);
    });

    // Additional edge case: handles both flags being false
    test('handles both isDefaultPassword and isSetByUser being false',
        () async {
      // Arrange - unusual but possible state
      when(() => mockRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
            timeoutMs: any(named: 'timeoutMs'),
            retries: any(named: 'retries'),
            pollConfig: any(named: 'pollConfig'),
          )).thenAnswer((_) async => createTransactionSuccessWrap(
            ConnectivityTestData.createFetchConfiguredSuccess(
              isAdminPasswordDefault: false,
              isAdminPasswordSetByUser: false,
            ),
          ));

      // Act
      final result = await service.fetchRouterConfiguredData();

      // Assert
      expect(result.isDefaultPassword, false);
      expect(result.isSetByUser, false);
    });
  });
}
