import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart' as jnap_models;
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/services/dmz_settings_service.dart';

import '../../../../common/unit_test_helper.dart';
import 'dmz_settings_service_test_data.dart';

// Mock class for RouterRepository
class MockRouterRepository extends Mock implements RouterRepository {}

// Fake for JNAPTransactionBuilder
class FakeJNAPTransactionBuilder extends Fake implements JNAPTransactionBuilder {}

void main() {
  late MockRouterRepository mockRepository;
  late DMZSettingsService service;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getDMZSettings);
    registerFallbackValue(JNAPAction.getLANSettings);
    registerFallbackValue(JNAPAction.setDMZSettings);
    registerFallbackValue(FakeJNAPTransactionBuilder());
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = DMZSettingsService();
    UnitTestHelper.setupMocktailFallbacks();
  });

  group('DMZSettingsService', () {
    group('fetchDmzSettings', () {
      test('parses DMZ settings and LAN settings successfully', () async {
        // Arrange
        final mockResponse = DMZSettingsTestData.createSuccessfulTransaction(
          isDMZEnabled: false,
        );
        when(() => mockRepository.transaction(any(), fetchRemote: any()))
            .thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchDmzSettings(mockRef);

        // Assert
        expect(uiSettings, isNotNull);
        expect(uiSettings?.isDMZEnabled, false);
        expect(uiSettings?.sourceType, DMZSourceType.auto);
        expect(uiSettings?.destinationType, DMZDestinationType.ip);
        expect(status, isNotNull);
        expect(status?.ipAddress, '192.168.1.0');
      });

      test('parses DMZ enabled with IP destination', () async {
        // Arrange
        final mockResponse = DMZSettingsTestData.createEnabledDMZWithIP(
            destinationIP: '192.168.1.100');
        when(() => mockRepository.transaction(any(), fetchRemote: any()))
            .thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchDmzSettings(mockRef);

        // Assert
        expect(uiSettings?.isDMZEnabled, true);
        expect(uiSettings?.destinationIPAddress, '192.168.1.100');
        expect(uiSettings?.destinationType, DMZDestinationType.ip);
      });

      test('parses DMZ enabled with MAC destination', () async {
        // Arrange
        final mockResponse = DMZSettingsTestData.createEnabledDMZWithMAC(
            destinationMac: '00:11:22:33:44:55');
        when(() => mockRepository.transaction(any(), fetchRemote: any()))
            .thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchDmzSettings(mockRef);

        // Assert
        expect(uiSettings?.isDMZEnabled, true);
        expect(uiSettings?.destinationMACAddress, '00:11:22:33:44:55');
        expect(uiSettings?.destinationType, DMZDestinationType.mac);
      });

      test('parses DMZ with source IP range restriction', () async {
        // Arrange
        final mockResponse = DMZSettingsTestData.createDMZWithSourceRestriction(
          firstIPAddress: '192.168.1.50',
          lastIPAddress: '192.168.1.99',
          destinationIP: '192.168.1.100',
        );
        when(() => mockRepository.transaction(any(), fetchRemote: any()))
            .thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchDmzSettings(mockRef);

        // Assert
        expect(uiSettings?.isDMZEnabled, true);
        expect(uiSettings?.sourceType, DMZSourceType.range);
        expect(uiSettings?.sourceRestriction?.firstIPAddress, '192.168.1.50');
        expect(uiSettings?.sourceRestriction?.lastIPAddress, '192.168.1.99');
      });

      test('handles getDMZSettings error gracefully', () async {
        // Arrange
        final mockResponse = DMZSettingsTestData.createPartialErrorTransaction(
          errorAction: JNAPAction.getDMZSettings,
        );
        when(() => mockRepository.transaction(any(), fetchRemote: any()))
            .thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act & Assert
        expect(
          () => service.fetchDmzSettings(mockRef),
          throwsA(isA<Exception>()),
        );
      });

      test('returns null settings if getDMZSettings missing', () async {
        // Arrange: Build a response with only getLANSettings (no DMZ)
        final mockResponse = JNAPTransactionSuccessWrap(
          result: 'ok',
          data: [
            MapEntry(
              JNAPAction.getLANSettings,
              DMZSettingsTestData.createLANSettingsSuccess(),
            ),
          ],
        );
        when(() => mockRepository.transaction(any(), fetchRemote: any()))
            .thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (uiSettings, status) = await service.fetchDmzSettings(mockRef);

        // Assert
        expect(uiSettings, isNull);
        expect(status, isNotNull);
      });

      test('respects forceRemote parameter', () async {
        // Arrange
        final mockResponse = DMZSettingsTestData.createSuccessfulTransaction();
        when(() => mockRepository.transaction(any(), fetchRemote: any()))
            .thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.fetchDmzSettings(mockRef, forceRemote: true);

        // Assert
        verify(
          () => mockRepository.transaction(any(), fetchRemote: true),
        ).called(1);
      });
    });

    group('saveDmzSettings', () {
      test('sends setDMZSettings action', () async {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '192.168.1.100',
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        when(() => mockRepository.send(
              any(),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              auth: any(named: 'auth'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => JNAPSuccess(result: 'ok', output: {}));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.saveDmzSettings(mockRef, settings);

        // Assert
        verify(
          () => mockRepository.send(
            JNAPAction.setDMZSettings,
            fetchRemote: true,
            cacheLevel: any(named: 'cacheLevel'),
            auth: true,
            data: any(named: 'data'),
          ),
        ).called(1);
      });

      test('handles save error gracefully', () async {
        // Arrange
        const settings = DMZUISettings(
          isDMZEnabled: false,
          sourceType: DMZSourceType.auto,
          destinationType: DMZDestinationType.ip,
        );

        when(() => mockRepository.send(
              any(),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              auth: any(named: 'auth'),
              data: any(named: 'data'),
            )).thenThrow(Exception('Network error'));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act & Assert
        expect(
          () => service.saveDmzSettings(mockRef, settings),
          throwsA(isA<Exception>()),
        );
      });

      test('saves DMZ with source restriction', () async {
        // Arrange
        final settings = DMZUISettings(
          isDMZEnabled: true,
          destinationIPAddress: '192.168.1.100',
          sourceRestriction: const DMZSourceRestrictionUI(
            firstIPAddress: '192.168.1.50',
            lastIPAddress: '192.168.1.99',
          ),
          sourceType: DMZSourceType.range,
          destinationType: DMZDestinationType.ip,
        );

        when(() => mockRepository.send(
              any(),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              auth: any(named: 'auth'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => JNAPSuccess(result: 'ok', output: {}));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.saveDmzSettings(mockRef, settings);

        // Assert
        verify(
          () => mockRepository.send(
            JNAPAction.setDMZSettings,
            fetchRemote: true,
            cacheLevel: any(named: 'cacheLevel'),
            auth: true,
            data: any(named: 'data'),
          ),
        ).called(1);
      });
    });
  });
}
