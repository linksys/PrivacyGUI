import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_state.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/page/nodes/services/node_light_settings_service.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

class MockNodeLightSettingsService extends Mock
    implements NodeLightSettingsService {}

void main() {
  late MockNodeLightSettingsService mockService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(NodeLightState.initial());
  });

  setUp(() {
    mockService = MockNodeLightSettingsService();
    container = ProviderContainer(
      overrides: [
        nodeLightSettingsServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('NodeLightSettingsNotifier - delegation', () {
    test('fetch() calls service.fetchState() and updates state', () async {
      // Arrange
      const expectedState = NodeLightState(
          isNightModeEnabled: true,
          startHour: 20,
          endHour: 8,
          allDayOff: false);
      when(() => mockService.fetchState(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => expectedState);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      final result = await notifier.fetch();

      // Assert
      verify(() => mockService.fetchState(forceRemote: false)).called(1);
      expect(result, expectedState);
      expect(container.read(nodeLightSettingsProvider), expectedState);
    });

    test('fetch(true) passes forceRemote=true to service', () async {
      // Arrange
      const expectedState = NodeLightState(
          isNightModeEnabled: true,
          startHour: 20,
          endHour: 8,
          allDayOff: false);
      when(() => mockService.fetchState(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => expectedState);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      await notifier.fetch(forceRemote: true);

      // Assert
      verify(() => mockService.fetchState(forceRemote: true)).called(1);
    });

    test('save() calls service.saveState(state) and updates state', () async {
      // Arrange
      const stateToSave = NodeLightState(
          isNightModeEnabled: true,
          startHour: 20,
          endHour: 8,
          allDayOff: false);
      const savedState = NodeLightState(
          isNightModeEnabled: true,
          startHour: 20,
          endHour: 8,
          allDayOff: false);

      when(() => mockService.saveState(any()))
          .thenAnswer((_) async => savedState);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(stateToSave);
      final result = await notifier.save();

      // Assert
      verify(() => mockService.saveState(stateToSave)).called(1);
      expect(result, savedState);
      expect(container.read(nodeLightSettingsProvider), savedState);
    });

    test('setSettings() updates state directly without service call', () {
      // Arrange
      const newState = NodeLightState(
          isNightModeEnabled: false, startHour: 0, endHour: 0, allDayOff: true);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(newState);

      // Assert - just verify state was updated directly
      expect(container.read(nodeLightSettingsProvider), newState);
    });
  });

  group('NodeLightSettingsNotifier - currentStatus getter', () {
    test('returns NodeLightStatus.on when isNightModeEnabled=false', () {
      // Arrange
      const state = NodeLightState(isNightModeEnabled: false, allDayOff: false);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(state);
      final status = notifier.currentStatus;

      // Assert
      expect(status, NodeLightStatus.on);
    });

    test('returns NodeLightStatus.off when allDayOff=true', () {
      // Arrange
      const state = NodeLightState(
        isNightModeEnabled: true,
        allDayOff: true,
      );

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(state);
      final status = notifier.currentStatus;

      // Assert
      expect(status, NodeLightStatus.off);
    });

    test(
        'returns NodeLightStatus.off when startHour=0 and endHour=24 and enabled=true? (No, depends on implementation)',
        () {
      // NOTE: Original test checked "returns NodeLightStatus.off when startHour=0 and endHour=24" using NodeLightSettings.off().
      // In Refactor, logic is mostly boolean flags.
      // NodeLightState.off() factory logic was: isNightModeEnable=false, allDayOff=true.
      // Let's test the `NodeLightStatus.off` condition which is `allDayOff` in my implementation (or !night && allDayOff).

      // Arrange
      // Let's create a state that would be logically OFF.
      const state = NodeLightState(isNightModeEnabled: false, allDayOff: true);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(state);
      final status = notifier.currentStatus;

      // Assert
      expect(status, NodeLightStatus.off);
    });

    test('returns NodeLightStatus.night when isNightModeEnabled=true', () {
      // Arrange
      const state = NodeLightState(isNightModeEnabled: true, allDayOff: false);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(state);
      final status = notifier.currentStatus;

      // Assert
      expect(status, NodeLightStatus.night);
    });
  });

  group('NodeLightSettingsNotifier - save flow', () {
    test('setSettings() followed by save() persists correct values', () async {
      // Arrange
      const settingsToSet =
          NodeLightState(isNightModeEnabled: false, allDayOff: true);
      const savedSettings =
          NodeLightState(isNightModeEnabled: false, allDayOff: true);

      when(() => mockService.saveState(any()))
          .thenAnswer((_) async => savedSettings);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settingsToSet);
      await notifier.save();

      // Assert
      verify(() => mockService.saveState(settingsToSet)).called(1);
    });

    test('state updates after successful save', () async {
      // Arrange
      const settingsToSet =
          NodeLightState(isNightModeEnabled: true, allDayOff: false);
      const returnedState = NodeLightState(
        isNightModeEnabled: true,
        startHour: 20,
        endHour: 8,
        allDayOff: false,
      );

      when(() => mockService.saveState(any()))
          .thenAnswer((_) async => returnedState);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settingsToSet);
      await notifier.save();

      // Assert
      expect(container.read(nodeLightSettingsProvider), returnedState);
    });
  });
}
