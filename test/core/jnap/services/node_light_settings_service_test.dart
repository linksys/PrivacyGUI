import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/nodes/services/node_light_settings_service.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_state.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

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

  group('NodeLightSettingsService - fetchState', () {
    test('returns NodeLightState converted from JNAP response', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createNightModeSettings());

      // Act
      final result = await service.fetchState();

      // Assert
      expect(result.isNightModeEnabled, true);
      expect(result.startHour, 20);
      expect(result.endHour, 8);
      expect(result.status, NodeLightStatus.night);
    });

    test('passes forceRemote=false by default', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createLedOnSettings());

      // Act
      await service.fetchState();

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
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createLedOnSettings());

      // Act
      await service.fetchState(forceRemote: true);

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
        () => service.fetchState(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws UnexpectedError on generic JNAP error', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenThrow(
              NodeLightSettingsTestData.createUnexpectedError('ErrorUnknown'));

      // Act & Assert
      expect(
        () => service.fetchState(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });

  group('NodeLightSettingsService - saveState', () {
    test('converts state to JNAP Map and returns refreshed state', () async {
      // Arrange
      const stateToSave = NodeLightState(
          isNightModeEnabled: true,
          startHour: 20,
          endHour: 8,
          allDayOff: false);

      when(() => mockRepository.send(
                JNAPAction.setLedNightModeSetting,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createSaveSuccess());

      when(() => mockRepository.send(
                JNAPAction.getLedNightModeSetting,
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createNightModeSettings());

      // Act
      final result = await service.saveState(stateToSave);

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

      expect(result.isNightModeEnabled, true);
      expect(result.startHour, 20);
      expect(result.endHour, 8);
    });

    test('sends correct data for All AllDayOff (LED OFF)', () async {
      // Arrange
      // "Off" state means allDayOff=true.
      const stateToSave =
          NodeLightState(isNightModeEnabled: false, allDayOff: true);

      when(() => mockRepository.send(
                JNAPAction.setLedNightModeSetting,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createSaveSuccess());

      when(() => mockRepository.send(
                JNAPAction.getLedNightModeSetting,
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createLedOffSettings());

      // Act
      await service.saveState(stateToSave);

      // Assert
      // Implementation maps allDayOff to Enable=true, Start=0, End=24
      verify(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: {'Enable': true, 'StartingTime': 0, 'EndingTime': 24},
            auth: true,
          )).called(1);
    });

    test('sends Enable=false when turning Night Mode OFF (LED ON)', () async {
      // Arrange
      const stateToSave = NodeLightState(
          isNightModeEnabled: false, allDayOff: false); // Normal/On
      // Defaults: startHour=20, endHour=6

      when(() => mockRepository.send(
                JNAPAction.setLedNightModeSetting,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createSaveSuccess());

      when(() => mockRepository.send(
                JNAPAction.getLedNightModeSetting,
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
              ))
          .thenAnswer(
              (_) async => NodeLightSettingsTestData.createLedOnSettings());

      // Act
      await service.saveState(stateToSave);

      // Assert
      // Implementation sends current hours even if disabled
      verify(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: {'Enable': false, 'StartingTime': 20, 'EndingTime': 6},
            auth: true,
          )).called(1);
    });

    test('throws UnauthorizedError on save auth failure', () async {
      // Arrange
      const stateToSave = NodeLightState(isNightModeEnabled: true);

      when(() => mockRepository.send(
            JNAPAction.setLedNightModeSetting,
            data: any(named: 'data'),
            auth: any(named: 'auth'),
          )).thenThrow(NodeLightSettingsTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.saveState(stateToSave),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws UnexpectedError on save generic error', () async {
      // Arrange
      const stateToSave = NodeLightState(isNightModeEnabled: true);

      when(() => mockRepository.send(
                JNAPAction.setLedNightModeSetting,
                data: any(named: 'data'),
                auth: any(named: 'auth'),
              ))
          .thenThrow(NodeLightSettingsTestData.createUnexpectedError(
              'ErrorSaveFailed'));

      // Act & Assert
      expect(
        () => service.saveState(stateToSave),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
