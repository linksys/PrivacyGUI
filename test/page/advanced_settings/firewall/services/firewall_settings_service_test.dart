import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/firewall_settings_service.dart';

import '../../../../common/unit_test_helper.dart';
import 'firewall_settings_service_test_data.dart';

// Mock class for RouterRepository
class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late MockRouterRepository mockRepository;
  late FirewallSettingsService service;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getFirewallSettings);
    registerFallbackValue(JNAPAction.setFirewallSettings);
    registerFallbackValue(CacheLevel.noCache);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = FirewallSettingsService();
    UnitTestHelper.setupMocktailFallbacks();
  });

  group('FirewallSettingsService', () {
    group('fetchFirewallSettings', () {
      test('fetches and transforms default firewall settings successfully',
          () async {
        // Arrange
        final mockResponse =
            FirewallSettingsTestData.createSuccessfulResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchFirewallSettings(
          mockRef,
        );

        // Assert
        expect(uiSettings, isNotNull);
        expect(uiSettings?.blockAnonymousRequests, false);
        expect(uiSettings?.blockIDENT, false);
        expect(uiSettings?.blockIPSec, false);
        expect(uiSettings?.blockL2TP, false);
        expect(uiSettings?.blockMulticast, false);
        expect(uiSettings?.blockNATRedirection, false);
        expect(uiSettings?.blockPPTP, false);
        expect(uiSettings?.isIPv4FirewallEnabled, false);
        expect(uiSettings?.isIPv6FirewallEnabled, false);
        expect(status, isNotNull);
      });

      test('transforms all 9 boolean fields correctly', () async {
        // Arrange
        final mockResponse =
            FirewallSettingsTestData.createFullyEnabledResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchFirewallSettings(
          mockRef,
        );

        // Assert - verify all fields are correctly mapped
        expect(uiSettings?.blockAnonymousRequests, true);
        expect(uiSettings?.blockIDENT, true);
        expect(uiSettings?.blockIPSec, true);
        expect(uiSettings?.blockL2TP, true);
        expect(uiSettings?.blockMulticast, true);
        expect(uiSettings?.blockNATRedirection, true);
        expect(uiSettings?.blockPPTP, true);
        expect(uiSettings?.isIPv4FirewallEnabled, true);
        expect(uiSettings?.isIPv6FirewallEnabled, true);
      });

      test('fetches with custom IPv4 firewall enabled', () async {
        // Arrange
        final mockResponse =
            FirewallSettingsTestData.createIPv4EnabledResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, _) = await service.fetchFirewallSettings(mockRef);

        // Assert
        expect(uiSettings?.isIPv4FirewallEnabled, true);
        expect(uiSettings?.blockAnonymousRequests, true);
        expect(uiSettings?.isIPv6FirewallEnabled, false);
      });

      test('fetches with custom IPv6 firewall enabled', () async {
        // Arrange
        final mockResponse =
            FirewallSettingsTestData.createIPv6EnabledResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, _) = await service.fetchFirewallSettings(mockRef);

        // Assert
        expect(uiSettings?.isIPv6FirewallEnabled, true);
        expect(uiSettings?.blockMulticast, true);
        expect(uiSettings?.isIPv4FirewallEnabled, false);
      });

      test('fetches with protocol blocking enabled', () async {
        // Arrange
        final mockResponse =
            FirewallSettingsTestData.createProtocolBlockingResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, _) = await service.fetchFirewallSettings(mockRef);

        // Assert
        expect(uiSettings?.blockIPSec, true);
        expect(uiSettings?.blockL2TP, true);
        expect(uiSettings?.blockPPTP, true);
      });

      test('respects forceRemote parameter', () async {
        // Arrange
        final mockResponse =
            FirewallSettingsTestData.createSuccessfulResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.fetchFirewallSettings(mockRef, forceRemote: true);

        // Assert
        verify(() => mockRepository.send(
              JNAPAction.getFirewallSettings,
              auth: true,
              fetchRemote: true,
            )).called(1);
      });

      test('uses local fetch by default (forceRemote: false)', () async {
        // Arrange
        final mockResponse =
            FirewallSettingsTestData.createSuccessfulResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.fetchFirewallSettings(mockRef);

        // Assert
        verify(() => mockRepository.send(
              JNAPAction.getFirewallSettings,
              auth: true,
              fetchRemote: false,
            )).called(1);
      });

      test('returns (null, null) on network error', () async {
        // Arrange
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenThrow(Exception('Network error'));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchFirewallSettings(mockRef);

        // Assert
        expect(uiSettings, isNull);
        expect(status, isNull);
      });

      test('returns (null, null) on JNAP error response', () async {
        // Arrange
        final mockErrorResponse = FirewallSettingsTestData.createErrorResponse(
          errorMessage: 'Device unreachable',
        );
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenThrow(mockErrorResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchFirewallSettings(mockRef);

        // Assert
        expect(uiSettings, isNull);
        expect(status, isNull);
      });

      test('returns (null, null) on incomplete JNAP response data', () async {
        // Arrange - create response with incomplete output
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenThrow(TypeError());

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchFirewallSettings(mockRef);

        // Assert
        expect(uiSettings, isNull);
        expect(status, isNull);
      });

      test('returns (null, null) when response throws on parsing', () async {
        // Arrange - simulate a parsing failure
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenThrow(FormatException('Invalid JSON'));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchFirewallSettings(mockRef);

        // Assert
        expect(uiSettings, isNull);
        expect(status, isNull);
      });
    });

    group('saveFirewallSettings', () {
      test('saves firewall settings with valid input', () async {
        // Arrange
        final mockResponse =
            FirewallSettingsTestData.createSuccessfulResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        final uiSettings =
            FirewallSettingsTestData.createSuccessfulResponse().output;
        final firewallUISettings =
            service.fetchFirewallSettings(mockRef).then((value) => value.$1!);

        // Act
        await service.saveFirewallSettings(
          mockRef,
          await firewallUISettings,
        );

        // Assert
        verify(() => mockRepository.send(
              JNAPAction.setFirewallSettings,
              auth: true,
              fetchRemote: true,
              cacheLevel: CacheLevel.noCache,
              data: any(named: 'data'),
            )).called(1);
      });

      test('transforms FirewallUISettings to FirewallSettings correctly',
          () async {
        // Arrange
        Map<String, dynamic>? capturedData;
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: captureAny(named: 'data'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')]
              as Map<String, dynamic>;
          return FirewallSettingsTestData.createSuccessfulResponse();
        });

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Create initial fetch to get UI settings
        final fetchResponse =
            FirewallSettingsTestData.createFullyEnabledResponse();
        when(() => mockRepository.send(
              JNAPAction.getFirewallSettings,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => fetchResponse);

        final (uiSettings, _) = await service.fetchFirewallSettings(mockRef);

        // Act
        await service.saveFirewallSettings(mockRef, uiSettings!);

        // Assert - verify all fields are transformed correctly
        expect(capturedData, isNotNull);
        expect(capturedData!['blockAnonymousRequests'], true);
        expect(capturedData!['blockIDENT'], true);
        expect(capturedData!['blockIPSec'], true);
        expect(capturedData!['blockL2TP'], true);
        expect(capturedData!['blockMulticast'], true);
        expect(capturedData!['blockNATRedirection'], true);
        expect(capturedData!['blockPPTP'], true);
        expect(capturedData!['isIPv4FirewallEnabled'], true);
        expect(capturedData!['isIPv6FirewallEnabled'], true);
      });

      test('saves with IPv4 firewall enabled only', () async {
        // Arrange
        Map<String, dynamic>? capturedData;
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: captureAny(named: 'data'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[const Symbol('data')]
              as Map<String, dynamic>;
          return FirewallSettingsTestData.createSuccessfulResponse();
        });

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        final fetchResponse =
            FirewallSettingsTestData.createIPv4EnabledResponse();
        when(() => mockRepository.send(
              JNAPAction.getFirewallSettings,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => fetchResponse);

        final (uiSettings, _) = await service.fetchFirewallSettings(mockRef);

        // Act
        await service.saveFirewallSettings(mockRef, uiSettings!);

        // Assert
        expect(capturedData!['isIPv4FirewallEnabled'], true);
        expect(capturedData!['isIPv6FirewallEnabled'], false);
      });

      test('handles save error gracefully', () async {
        // Arrange
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: any(named: 'data'),
            )).thenThrow(Exception('Network error'));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        final fetchResponse =
            FirewallSettingsTestData.createSuccessfulResponse();
        when(() => mockRepository.send(
              JNAPAction.getFirewallSettings,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => fetchResponse);

        final (uiSettings, _) = await service.fetchFirewallSettings(mockRef);

        // Act & Assert
        expect(
          () => service.saveFirewallSettings(mockRef, uiSettings!),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to save firewall settings'),
          )),
        );
      });

      test('ensures fetchRemote is true for save operation', () async {
        // Arrange
        when(() => mockRepository.send(
                  any(),
                  auth: any(named: 'auth'),
                  fetchRemote: any(named: 'fetchRemote'),
                  cacheLevel: any(named: 'cacheLevel'),
                  data: any(named: 'data'),
                ))
            .thenAnswer((_) async =>
                FirewallSettingsTestData.createSuccessfulResponse());

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        final fetchResponse =
            FirewallSettingsTestData.createSuccessfulResponse();
        when(() => mockRepository.send(
              JNAPAction.getFirewallSettings,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => fetchResponse);

        final (uiSettings, _) = await service.fetchFirewallSettings(mockRef);

        // Act
        await service.saveFirewallSettings(mockRef, uiSettings!);

        // Assert
        verify(() => mockRepository.send(
              JNAPAction.setFirewallSettings,
              auth: true,
              fetchRemote: true,
              cacheLevel: CacheLevel.noCache,
              data: any(named: 'data'),
            )).called(1);
      });

      test('ensures noCache for save operation', () async {
        // Arrange
        when(() => mockRepository.send(
                  any(),
                  auth: any(named: 'auth'),
                  fetchRemote: any(named: 'fetchRemote'),
                  cacheLevel: any(named: 'cacheLevel'),
                  data: any(named: 'data'),
                ))
            .thenAnswer((_) async =>
                FirewallSettingsTestData.createSuccessfulResponse());

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        final fetchResponse =
            FirewallSettingsTestData.createSuccessfulResponse();
        when(() => mockRepository.send(
              JNAPAction.getFirewallSettings,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => fetchResponse);

        final (uiSettings, _) = await service.fetchFirewallSettings(mockRef);

        // Act
        await service.saveFirewallSettings(mockRef, uiSettings!);

        // Assert
        verify(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: CacheLevel.noCache,
              data: any(named: 'data'),
            )).called(1);
      });
    });
  });
}
