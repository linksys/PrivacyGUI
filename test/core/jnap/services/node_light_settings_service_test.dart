import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/services/node_light_settings_service.dart';

import '../../../mocks/test_data/node_light_settings_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late NodeLightSettingsService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getLedNightModeSetting);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = NodeLightSettingsService(mockRepository);
  });

  group('NodeLightSettingsService - fetchSettings', () {
    test('returns NodeLightSettings from JNAP response', () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer(
          (_) async => NodeLightSettingsTestData.createNightModeSettings());

      // Act
      final result = await service.fetchSettings();

      // Assert
      expect(result.isNightModeEnable, true);
      expect(result.startHour, 20);
      expect(result.endHour, 8);
    });

    test('passes forceRemote=false by default', () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer(
          (_) async => NodeLightSettingsTestData.createLedOnSettings());

      // Act
      await service.fetchSettings();

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.getLedNightModeSetting,
            auth: true,
            fetchRemote: false,
          )).called(1);
    });

    test('passes forceRemote=true when specified', () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer(
          (_) async => NodeLightSettingsTestData.createLedOnSettings());

      // Act
      await service.fetchSettings(forceRemote: true);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.getLedNightModeSetting,
            auth: true,
            fetchRemote: true,
          )).called(1);
    });

    test('throws UnauthorizedError on auth failure', () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenThrow(NodeLightSettingsTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws UnexpectedError on generic JNAP error', () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenThrow(
          NodeLightSettingsTestData.createUnexpectedError('ErrorUnknown'));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });

  group('NodeLightSettingsService - saveSettings', () {
    test('sends correct data to JNAP and returns refreshed settings', () async {
      // Arrange
      final settingsToSave = NodeLightSettings.night();

      when(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenAnswer(
          (_) async => NodeLightSettingsTestData.createSaveSuccess());

      when(() => mockRepository.send(
            JNAPAction.getLedNightModeSetting,
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer(
          (_) async => NodeLightSettingsTestData.createNightModeSettings());

      // Act
      final result = await service.saveSettings(settingsToSave);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: {
              'Enable': true,
              'StartingTime': 20,
              'EndingTime': 8,
            },
            auth: true,
          )).called(1);

      // Verify it re-fetches after save
      verify(() => mockRepository.send(
            JNAPAction.getLedNightModeSetting,
            auth: true,
            fetchRemote: true,
          )).called(1);

      expect(result.isNightModeEnable, true);
    });

    test('excludes null fields from request', () async {
      // Arrange
      final settingsToSave = NodeLightSettings.on(); // Has null startHour/endHour

      when(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenAnswer(
          (_) async => NodeLightSettingsTestData.createSaveSuccess());

      when(() => mockRepository.send(
            JNAPAction.getLedNightModeSetting,
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer(
          (_) async => NodeLightSettingsTestData.createLedOnSettings());

      // Act
      await service.saveSettings(settingsToSave);

      // Assert - only Enable should be sent, no StartingTime or EndingTime
      verify(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: {'Enable': false},
            auth: true,
          )).called(1);
    });

    test('throws UnauthorizedError on save auth failure', () async {
      // Arrange
      final settingsToSave = NodeLightSettings.night();

      when(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenThrow(NodeLightSettingsTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.saveSettings(settingsToSave),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws UnexpectedError on save generic error', () async {
      // Arrange
      final settingsToSave = NodeLightSettings.night();

      when(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenThrow(
          NodeLightSettingsTestData.createUnexpectedError('ErrorSaveFailed'));

      // Act & Assert
      expect(
        () => service.saveSettings(settingsToSave),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
