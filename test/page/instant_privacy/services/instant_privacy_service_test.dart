import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';

import '../../../common/di.dart';
import '../../../mocks/test_data/instant_privacy_test_data.dart';

// Mocks
class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late InstantPrivacyService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    // Register mock dependencies including ServiceHelper
    mockDependencyRegister();

    // Register fallback values for Mocktail
    registerFallbackValue(JNAPAction.getMACFilterSettings);
    registerFallbackValue(CacheLevel.noCache);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = InstantPrivacyService(mockRepository);
  });

  // ===========================================================================
  // User Story 2 - fetchMacFilterSettings Tests (T008-T010)
  // ===========================================================================

  group('InstantPrivacyService - fetchMacFilterSettings', () {
    test('returns settings and status on success', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getMACFilterSettings,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              InstantPrivacyTestData.createMacFilterSettingsSuccess(
                macFilterMode: 'Allow',
                maxMacAddresses: 32,
                macAddresses: ['AA:BB:CC:DD:EE:FF'],
              ));

      // Note: BSSIDs are not fetched because MockServiceHelper.isSupportGetSTABSSID()
      // returns false by default (see test/mocks/jnap_service_supported_mocks.dart)

      // Act
      final (settings, status) = await service.fetchMacFilterSettings();

      // Assert
      expect(settings, isNotNull);
      expect(status, isNotNull);
      expect(settings!.mode, MacFilterMode.allow);
      expect(settings.macAddresses, ['AA:BB:CC:DD:EE:FF']);
      expect(settings.maxMacAddresses, 32);
      // BSSIDs are empty because isSupportGetSTABSSID() returns false
      expect(settings.bssids, isEmpty);
      expect(status!.mode, MacFilterMode.allow);
    });

    test('returns only status when updateStatusOnly=true', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getMACFilterSettings,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              InstantPrivacyTestData.createMacFilterSettingsSuccess(
                macFilterMode: 'Deny',
              ));

      // Act
      final (settings, status) =
          await service.fetchMacFilterSettings(updateStatusOnly: true);

      // Assert
      expect(settings, isNull);
      expect(status, isNotNull);
      expect(status!.mode, MacFilterMode.deny);

      // Verify STA BSSIDs was NOT called
      verifyNever(() => mockRepository.send(
            JNAPAction.getSTABSSIDs,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          ));
    });

    test('correctly splits macAddresses for allow mode', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getMACFilterSettings,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              InstantPrivacyTestData.createMacFilterSettingsSuccess(
                macFilterMode: 'Allow',
                macAddresses: ['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'],
              ));

      when(() => mockRepository.send(
                JNAPAction.getSTABSSIDs,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => InstantPrivacyTestData.createStaBssidsSuccess());

      // Act
      final (settings, _) = await service.fetchMacFilterSettings();

      // Assert
      expect(settings!.mode, MacFilterMode.allow);
      expect(settings.macAddresses, ['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66']);
      expect(settings.denyMacAddresses, isEmpty);
    });

    test('correctly splits macAddresses for deny mode', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getMACFilterSettings,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              InstantPrivacyTestData.createMacFilterSettingsSuccess(
                macFilterMode: 'Deny',
                macAddresses: ['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'],
              ));

      when(() => mockRepository.send(
                JNAPAction.getSTABSSIDs,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => InstantPrivacyTestData.createStaBssidsSuccess());

      // Act
      final (settings, _) = await service.fetchMacFilterSettings();

      // Assert
      expect(settings!.mode, MacFilterMode.deny);
      expect(settings.macAddresses, isEmpty);
      expect(settings.denyMacAddresses,
          ['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66']);
    });

    test('converts macAddresses to uppercase', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getMACFilterSettings,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer((_) async =>
              InstantPrivacyTestData.createMacFilterSettingsSuccess(
                macFilterMode: 'Allow',
                macAddresses: ['aa:bb:cc:dd:ee:ff'],
              ));

      when(() => mockRepository.send(
                JNAPAction.getSTABSSIDs,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => InstantPrivacyTestData.createStaBssidsSuccess());

      // Act
      final (settings, _) = await service.fetchMacFilterSettings();

      // Assert
      expect(settings!.macAddresses, ['AA:BB:CC:DD:EE:FF']);
    });

    test('passes forceRemote to repository', () async {
      // Arrange
      when(() => mockRepository.send(
                JNAPAction.getMACFilterSettings,
                fetchRemote: true,
                auth: true,
              ))
          .thenAnswer((_) async =>
              InstantPrivacyTestData.createMacFilterSettingsSuccess());

      when(() => mockRepository.send(
                JNAPAction.getSTABSSIDs,
                fetchRemote: any(named: 'fetchRemote'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => InstantPrivacyTestData.createStaBssidsSuccess());

      // Act
      await service.fetchMacFilterSettings(forceRemote: true);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.getMACFilterSettings,
            fetchRemote: true,
            auth: true,
          )).called(1);
    });
  });

  // ===========================================================================
  // User Story 2 - saveMacFilterSettings Tests (T011-T012)
  // ===========================================================================

  group('InstantPrivacyService - saveMacFilterSettings', () {
    test('transforms settings to JNAP format for allow mode', () async {
      // Arrange
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.allow,
        macAddresses: ['AA:BB:CC:DD:EE:FF'],
        denyMacAddresses: [],
        maxMacAddresses: 32,
        bssids: ['11:22:33:44:55:66'],
      );

      when(() => mockRepository.send(
                JNAPAction.setMACFilterSettings,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));

      // Act
      await service.saveMacFilterSettings(settings, []);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setMACFilterSettings,
            data: {
              'macFilterMode': 'Allow',
              'macAddresses': ['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'],
            },
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    test('merges nodesMacAddresses for allow mode', () async {
      // Arrange
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.allow,
        macAddresses: ['AA:BB:CC:DD:EE:FF'],
        denyMacAddresses: [],
        maxMacAddresses: 32,
        bssids: [],
      );
      final nodesMacAddresses = [
        'NODE:MAC:00:00:00:01',
        'NODE:MAC:00:00:00:02'
      ];

      when(() => mockRepository.send(
                JNAPAction.setMACFilterSettings,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));

      // Act
      await service.saveMacFilterSettings(settings, nodesMacAddresses);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setMACFilterSettings,
            data: {
              'macFilterMode': 'Allow',
              'macAddresses': [
                'AA:BB:CC:DD:EE:FF',
                'NODE:MAC:00:00:00:01',
                'NODE:MAC:00:00:00:02'
              ],
            },
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    test('uses denyMacAddresses for deny mode', () async {
      // Arrange
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.deny,
        macAddresses: [],
        denyMacAddresses: ['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'],
        maxMacAddresses: 32,
        bssids: [],
      );

      when(() => mockRepository.send(
                JNAPAction.setMACFilterSettings,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));

      // Act
      await service.saveMacFilterSettings(settings, []);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setMACFilterSettings,
            data: {
              'macFilterMode': 'Deny',
              'macAddresses': ['AA:BB:CC:DD:EE:FF', '11:22:33:44:55:66'],
            },
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    test('does not include nodesMacAddresses for deny mode', () async {
      // Arrange
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.deny,
        macAddresses: [],
        denyMacAddresses: ['AA:BB:CC:DD:EE:FF'],
        maxMacAddresses: 32,
        bssids: [],
      );
      final nodesMacAddresses = ['NODE:MAC:00:00:00:01'];

      when(() => mockRepository.send(
                JNAPAction.setMACFilterSettings,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));

      // Act
      await service.saveMacFilterSettings(settings, nodesMacAddresses);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setMACFilterSettings,
            data: {
              'macFilterMode': 'Deny',
              'macAddresses': ['AA:BB:CC:DD:EE:FF'],
            },
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    test('removes duplicate macAddresses', () async {
      // Arrange
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.allow,
        macAddresses: ['AA:BB:CC:DD:EE:FF', 'AA:BB:CC:DD:EE:FF'],
        denyMacAddresses: [],
        maxMacAddresses: 32,
        bssids: ['AA:BB:CC:DD:EE:FF'],
      );

      when(() => mockRepository.send(
                JNAPAction.setMACFilterSettings,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));

      // Act
      await service.saveMacFilterSettings(settings, []);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setMACFilterSettings,
            data: {
              'macFilterMode': 'Allow',
              'macAddresses': ['AA:BB:CC:DD:EE:FF'],
            },
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    test('sends empty macAddresses for disabled mode', () async {
      // Arrange
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.disabled,
        macAddresses: ['AA:BB:CC:DD:EE:FF'],
        denyMacAddresses: [],
        maxMacAddresses: 32,
        bssids: [],
      );

      when(() => mockRepository.send(
                JNAPAction.setMACFilterSettings,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));

      // Act
      await service.saveMacFilterSettings(settings, []);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setMACFilterSettings,
            data: {
              'macFilterMode': 'Disabled',
              'macAddresses': <String>[],
            },
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });
  });

  // ===========================================================================
  // User Story 2 - fetchStaBssids Tests (T013)
  // ===========================================================================

  group('InstantPrivacyService - fetchStaBssids', () {
    // NOTE: The serviceHelper is a top-level final initialized at import time.
    // MockServiceHelper.isSupportGetSTABSSID() returns false by default,
    // so we can only test the "not supported" path.
    // Testing the "supported" path requires integration tests or architectural changes.

    test('returns empty list when not supported (default mock behavior)',
        () async {
      // Arrange - MockServiceHelper.isSupportGetSTABSSID() returns false by default

      // Act
      final result = await service.fetchStaBssids();

      // Assert
      expect(result, isEmpty);

      // Verify repository was NOT called
      verifyNever(() => mockRepository.send(
            JNAPAction.getSTABSSIDs,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          ));
    });

    // NOTE: Tests for 'returns BSSIDs when supported', 'converts BSSIDs to uppercase',
    // and 'returns empty list on error' are skipped because they require
    // isSupportGetSTABSSID() to return true, which cannot be controlled
    // with the current Mockito-based mock setup.
    // These behaviors are covered by integration tests.
  });

  // ===========================================================================
  // User Story 2 - fetchMyMacAddress Tests (T014-T015)
  // ===========================================================================

  group('InstantPrivacyService - fetchMyMacAddress', () {
    test('returns MAC from device list when found', () async {
      // Arrange
      final deviceList = [
        InstantPrivacyTestData.createLinksysDevice(
          deviceId: 'test-device-id',
          macAddress: 'AA:BB:CC:DD:EE:FF',
        ),
        InstantPrivacyTestData.createLinksysDevice(
          deviceId: 'other-device',
          macAddress: '11:22:33:44:55:66',
        ),
      ];

      when(() => mockRepository.send(
                JNAPAction.getLocalDevice,
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => InstantPrivacyTestData.createLocalDeviceSuccess(
                    deviceId: 'test-device-id',
                  ));

      // Act
      final result = await service.fetchMyMacAddress(deviceList);

      // Assert
      expect(result, 'AA:BB:CC:DD:EE:FF');
    });

    test('returns null when device not found in list', () async {
      // Arrange
      final deviceList = [
        InstantPrivacyTestData.createLinksysDevice(
          deviceId: 'other-device',
          macAddress: '11:22:33:44:55:66',
        ),
      ];

      when(() => mockRepository.send(
                JNAPAction.getLocalDevice,
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => InstantPrivacyTestData.createLocalDeviceSuccess(
                    deviceId: 'test-device-id',
                  ));

      // Act
      final result = await service.fetchMyMacAddress(deviceList);

      // Assert
      expect(result, isNull);
    });

    test('returns null when getLocalDevice fails', () async {
      // Arrange
      final deviceList = <dynamic>[];

      // Use thenAnswer with Future.error for async error handling
      when(() => mockRepository.send(
            JNAPAction.getLocalDevice,
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) => Future.error(Exception('Network error')));

      // Act
      final result = await service.fetchMyMacAddress(deviceList.cast());

      // Assert
      expect(result, isNull);
    });

    test('returns null when device list is empty', () async {
      // Arrange
      final deviceList = <dynamic>[];

      when(() => mockRepository.send(
                JNAPAction.getLocalDevice,
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => InstantPrivacyTestData.createLocalDeviceSuccess(
                    deviceId: 'test-device-id',
                  ));

      // Act
      final result = await service.fetchMyMacAddress(deviceList.cast());

      // Assert
      expect(result, isNull);
    });
  });

  // ===========================================================================
  // User Story 3 - Error Handling Tests (T022-T023)
  // ===========================================================================

  group('InstantPrivacyService - error handling', () {
    test('fetchMacFilterSettings throws ServiceError on JNAP failure',
        () async {
      // Arrange - Mock JNAP error response
      when(() => mockRepository.send(
            JNAPAction.getMACFilterSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenThrow(const JNAPError(result: 'ErrorUnknown'));

      // Act & Assert - Should throw ServiceError, not JNAPError
      await expectLater(
        () => service.fetchMacFilterSettings(),
        throwsA(allOf(
          isA<ServiceError>(),
          isNot(isA<JNAPError>()),
        )),
      );
    });

    test(
        'fetchMacFilterSettings maps known JNAP errors to specific ServiceError',
        () async {
      // Arrange - Mock unauthorized error
      when(() => mockRepository.send(
            JNAPAction.getMACFilterSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenThrow(const JNAPError(result: '_ErrorUnauthorized'));

      // Act & Assert - Should throw UnauthorizedError
      expect(
        () => service.fetchMacFilterSettings(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('fetchMacFilterSettings maps unknown JNAP errors to UnexpectedError',
        () async {
      // Arrange - Mock unknown error
      when(() => mockRepository.send(
            JNAPAction.getMACFilterSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenThrow(const JNAPError(result: 'ErrorSomethingWeird'));

      // Act & Assert - Should throw UnexpectedError
      expect(
        () => service.fetchMacFilterSettings(),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('saveMacFilterSettings throws ServiceError on JNAP failure', () async {
      // Arrange
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.allow,
        macAddresses: ['AA:BB:CC:DD:EE:FF'],
        denyMacAddresses: [],
        maxMacAddresses: 32,
        bssids: [],
      );

      when(() => mockRepository.send(
            JNAPAction.setMACFilterSettings,
            data: any(named: 'data'),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(const JNAPError(result: 'ErrorUnknown'));

      // Act & Assert - Should throw ServiceError, not JNAPError
      expect(
        () => service.saveMacFilterSettings(settings, []),
        throwsA(isA<ServiceError>()),
      );
    });

    test('saveMacFilterSettings maps InvalidMACAddress error correctly',
        () async {
      // Arrange
      const settings = InstantPrivacySettings(
        mode: MacFilterMode.allow,
        macAddresses: ['INVALID-MAC'],
        denyMacAddresses: [],
        maxMacAddresses: 32,
        bssids: [],
      );

      when(() => mockRepository.send(
            JNAPAction.setMACFilterSettings,
            data: any(named: 'data'),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(const JNAPError(result: 'ErrorInvalidMACAddress'));

      // Act & Assert - Should throw InvalidMACAddressError
      expect(
        () => service.saveMacFilterSettings(settings, []),
        throwsA(isA<InvalidMACAddressError>()),
      );
    });
  });
}
