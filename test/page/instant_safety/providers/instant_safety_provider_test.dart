import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';

class MockInstantSafetyService extends Mock implements InstantSafetyService {}

void main() {
  late MockInstantSafetyService mockService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(InstantSafetyType.off);
  });

  setUp(() {
    mockService = MockInstantSafetyService();
  });

  tearDown(() {
    container.dispose();
  });

  /// Creates a container with default service mock.
  /// The default mock returns off type with hasFortinet false.
  ProviderContainer createContainer({
    InstantSafetyType defaultType = InstantSafetyType.off,
    bool hasFortinet = false,
  }) {
    // Setup default mock for fetch (called during build)
    when(() => mockService.fetchSettings(
          deviceInfo: any(named: 'deviceInfo'),
          forceRemote: any(named: 'forceRemote'),
        )).thenAnswer((_) async => InstantSafetyFetchResult(
          safeBrowsingType: defaultType,
          hasFortinet: hasFortinet,
        ));

    return ProviderContainer(
      overrides: [
        instantSafetyServiceProvider.overrideWithValue(mockService),
      ],
    );
  }

  group('InstantSafetyNotifier - build()', () {
    test('returns initial state', () {
      // Arrange
      container = createContainer();

      // Act
      final state = container.read(instantSafetyProvider);

      // Assert
      expect(state.settings.current.safeBrowsingType, InstantSafetyType.off);
      expect(state.status.hasFortinet, false);
    });
  });

  group('InstantSafetyNotifier - performFetch()', () {
    test('calls service.fetchSettings and returns settings and status',
        () async {
      // Arrange
      container = createContainer(
        defaultType: InstantSafetyType.fortinet,
        hasFortinet: true,
      );

      // Act
      final notifier = container.read(instantSafetyProvider.notifier);
      final result = await notifier.performFetch();

      // Assert
      expect(result.$1?.safeBrowsingType, InstantSafetyType.fortinet);
      expect(result.$2?.hasFortinet, true);
    });

    test('calls service.fetchSettings with forceRemote true when specified',
        () async {
      // Arrange
      container = createContainer();

      // Act - read notifier (will trigger build which calls fetch with forceRemote: true)
      final notifier = container.read(instantSafetyProvider.notifier);

      // Clear previous calls from build
      clearInteractions(mockService);

      await notifier.performFetch(forceRemote: true);

      // Assert - verify the explicit performFetch call with forceRemote: true
      verify(() => mockService.fetchSettings(
            deviceInfo: any(named: 'deviceInfo'),
            forceRemote: true,
          )).called(1);
    });
  });

  group('InstantSafetyNotifier - performSave()', () {
    test('calls service.saveSettings with current safeBrowsingType', () async {
      // Arrange
      container = createContainer(
        defaultType: InstantSafetyType.fortinet,
        hasFortinet: true,
      );
      when(() => mockService.saveSettings(any())).thenAnswer((_) async {});

      final notifier = container.read(instantSafetyProvider.notifier);

      // First fetch to populate state
      await notifier.fetch();

      // Act
      await notifier.performSave();

      // Assert
      verify(() => mockService.saveSettings(InstantSafetyType.fortinet))
          .called(1);
    });

    test('calls service.saveSettings with updated safeBrowsingType', () async {
      // Arrange
      container = createContainer(
        defaultType: InstantSafetyType.off,
        hasFortinet: true,
      );
      when(() => mockService.saveSettings(any())).thenAnswer((_) async {});

      final notifier = container.read(instantSafetyProvider.notifier);
      await notifier.fetch();

      // Change the selection
      notifier.setSafeBrowsingProvider(InstantSafetyType.openDNS);

      // Act
      await notifier.performSave();

      // Assert
      verify(() => mockService.saveSettings(InstantSafetyType.openDNS))
          .called(1);
    });
  });

  group('InstantSafetyNotifier - setSafeBrowsingEnabled()', () {
    test('sets fortinet when enabled and hasFortinet is true', () async {
      // Arrange
      container = createContainer(
        defaultType: InstantSafetyType.off,
        hasFortinet: true,
      );

      final notifier = container.read(instantSafetyProvider.notifier);
      await notifier.fetch();

      // Act
      notifier.setSafeBrowsingEnabled(true);

      // Assert
      final state = container.read(instantSafetyProvider);
      expect(
          state.settings.current.safeBrowsingType, InstantSafetyType.fortinet);
    });

    test('sets openDNS when enabled and hasFortinet is false', () async {
      // Arrange
      container = createContainer(
        defaultType: InstantSafetyType.off,
        hasFortinet: false,
      );

      final notifier = container.read(instantSafetyProvider.notifier);
      await notifier.fetch();

      // Act
      notifier.setSafeBrowsingEnabled(true);

      // Assert
      final state = container.read(instantSafetyProvider);
      expect(
          state.settings.current.safeBrowsingType, InstantSafetyType.openDNS);
    });

    test('sets off when disabled', () async {
      // Arrange
      container = createContainer(
        defaultType: InstantSafetyType.fortinet,
        hasFortinet: true,
      );

      final notifier = container.read(instantSafetyProvider.notifier);
      await notifier.fetch();

      // Act
      notifier.setSafeBrowsingEnabled(false);

      // Assert
      final state = container.read(instantSafetyProvider);
      expect(state.settings.current.safeBrowsingType, InstantSafetyType.off);
    });
  });

  group('InstantSafetyNotifier - setSafeBrowsingProvider()', () {
    test('updates state with specified provider', () async {
      // Arrange
      container = createContainer(
        defaultType: InstantSafetyType.off,
        hasFortinet: true,
      );

      final notifier = container.read(instantSafetyProvider.notifier);
      await notifier.fetch();

      // Act
      notifier.setSafeBrowsingProvider(InstantSafetyType.openDNS);

      // Assert
      final state = container.read(instantSafetyProvider);
      expect(
          state.settings.current.safeBrowsingType, InstantSafetyType.openDNS);
    });

    test('can toggle between providers', () async {
      // Arrange
      container = createContainer(
        defaultType: InstantSafetyType.off,
        hasFortinet: true,
      );

      final notifier = container.read(instantSafetyProvider.notifier);
      await notifier.fetch();

      // Act & Assert
      notifier.setSafeBrowsingProvider(InstantSafetyType.fortinet);
      expect(
        container.read(instantSafetyProvider).settings.current.safeBrowsingType,
        InstantSafetyType.fortinet,
      );

      notifier.setSafeBrowsingProvider(InstantSafetyType.openDNS);
      expect(
        container.read(instantSafetyProvider).settings.current.safeBrowsingType,
        InstantSafetyType.openDNS,
      );

      notifier.setSafeBrowsingProvider(InstantSafetyType.off);
      expect(
        container.read(instantSafetyProvider).settings.current.safeBrowsingType,
        InstantSafetyType.off,
      );
    });
  });
}
