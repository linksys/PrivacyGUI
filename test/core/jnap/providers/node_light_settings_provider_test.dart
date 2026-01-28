import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/page/nodes/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/page/nodes/services/node_light_settings_service.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_state.dart';

class MockNodeLightSettingsService extends Mock
    implements NodeLightSettingsService {}

void main() {
  late MockNodeLightSettingsService mockService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(NodeLightSettings.on());
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
    test('fetch() calls service.fetchSettings() and updates state', () async {
      // Arrange
      final expectedSettings = NodeLightSettings.night();
      when(() =>
              mockService.fetchSettings(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => expectedSettings);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      final result = await notifier.fetch();

      // Assert
      verify(() => mockService.fetchSettings(forceRemote: false)).called(1);
      expect(result, expectedSettings);
      expect(container.read(nodeLightSettingsProvider), expectedSettings);
    });

    test('fetch(true) passes forceRemote=true to service', () async {
      // Arrange
      final expectedSettings = NodeLightSettings.night();
      when(() =>
              mockService.fetchSettings(forceRemote: any(named: 'forceRemote')))
          .thenAnswer((_) async => expectedSettings);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      await notifier.fetch(true);

      // Assert
      verify(() => mockService.fetchSettings(forceRemote: true)).called(1);
    });

    test('save() calls service.saveSettings(state) and updates state',
        () async {
      // Arrange
      final settingsToSave = NodeLightSettings.night();
      final savedSettings = NodeLightSettings.night();

      when(() => mockService.saveSettings(any()))
          .thenAnswer((_) async => savedSettings);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settingsToSave);
      final result = await notifier.save();

      // Assert
      verify(() => mockService.saveSettings(settingsToSave)).called(1);
      expect(result, savedSettings);
      expect(container.read(nodeLightSettingsProvider), savedSettings);
    });

    test('setSettings() updates state directly without service call', () {
      // Arrange
      final newSettings = NodeLightSettings.off();

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(newSettings);

      // Assert - just verify state was updated directly
      expect(container.read(nodeLightSettingsProvider), newSettings);
    });
  });

  group('NodeLightSettingsNotifier - currentStatus getter', () {
    test('returns NodeLightStatus.on when isNightModeEnable=false', () {
      // Arrange
      final settings = NodeLightSettings.on();

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settings);
      final status = notifier.currentStatus;

      // Assert
      expect(status, NodeLightStatus.on);
    });

    test('returns NodeLightStatus.off when allDayOff=true', () {
      // Arrange
      const settings = NodeLightSettings(
        isNightModeEnable: true,
        allDayOff: true,
      );

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settings);
      final status = notifier.currentStatus;

      // Assert
      expect(status, NodeLightStatus.off);
    });

    test('returns NodeLightStatus.off when startHour=0 and endHour=24', () {
      // Arrange
      final settings = NodeLightSettings.off();

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settings);
      final status = notifier.currentStatus;

      // Assert
      expect(status, NodeLightStatus.off);
    });

    test(
        'returns NodeLightStatus.night when isNightModeEnable=true with partial schedule',
        () {
      // Arrange
      final settings = NodeLightSettings.night();

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settings);
      final status = notifier.currentStatus;

      // Assert
      expect(status, NodeLightStatus.night);
    });
  });

  group('NodeLightSettingsNotifier - save flow', () {
    test('setSettings() followed by save() persists correct values', () async {
      // Arrange
      final settingsToSet = NodeLightSettings.off();
      final savedSettings = NodeLightSettings.off();

      when(() => mockService.saveSettings(any()))
          .thenAnswer((_) async => savedSettings);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settingsToSet);
      await notifier.save();

      // Assert
      verify(() => mockService.saveSettings(settingsToSet)).called(1);
    });

    test('state updates after successful save', () async {
      // Arrange
      final settingsToSet = NodeLightSettings.night();
      const returnedSettings = NodeLightSettings(
        isNightModeEnable: true,
        startHour: 20,
        endHour: 8,
        allDayOff: false, // Server might add this field
      );

      when(() => mockService.saveSettings(any()))
          .thenAnswer((_) async => returnedSettings);

      // Act
      final notifier = container.read(nodeLightSettingsProvider.notifier);
      notifier.setSettings(settingsToSet);
      await notifier.save();

      // Assert
      expect(container.read(nodeLightSettingsProvider), returnedSettings);
    });
  });
}
