import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';

class MockUspInstantPrivacyService extends Mock
    implements UspInstantPrivacyService {}

void main() {
  late MockUspInstantPrivacyService mockService;

  const device1 = InstantPrivacyDeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:01', displayName: 'Laptop');
  const device2 = InstantPrivacyDeviceUIModel(
      mac: 'AA:BB:CC:DD:EE:02', displayName: 'Phone');

  final disabledResult = InstantPrivacyFetchResult(
    isEnabled: false,
    connectedDevices: [device1, device2],
    allowedDevices: [],
    macFilterContext: MacFilterContext.empty,
  );

  final enabledResult = InstantPrivacyFetchResult(
    isEnabled: true,
    connectedDevices: [device1, device2],
    allowedDevices: [device1],
    macFilterContext: MacFilterContext.empty,
  );

  setUpAll(() {
    registerFallbackValue(MacFilterContext.empty);
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockService = MockUspInstantPrivacyService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspInstantPrivacyServiceProvider.overrideWithValue(mockService),
      ],
    );
    return container;
  }

  group('UspInstantPrivacyNotifier', () {
    test('build fetches all data and populates state', () async {
      when(() => mockService.fetchAll())
          .thenAnswer((_) async => disabledResult);
      final container = createContainer();

      final state = await container.read(uspInstantPrivacyProvider.future);
      expect(state.isEnabled, isFalse);
      expect(state.connectedDevices, hasLength(2));
      expect(state.allowedDevices, isEmpty);
      container.dispose();
    });

    test('build error sets AsyncError', () async {
      when(() => mockService.fetchAll())
          .thenThrow(const NetworkError(message: 'fetch failed'));
      final container = createContainer();

      try {
        await container.read(uspInstantPrivacyProvider.future);
      } catch (_) {}

      expect(container.read(uspInstantPrivacyProvider).hasError, isTrue);
      container.dispose();
    });

    test('enable calls service.enable with connected device MACs', () async {
      when(() => mockService.fetchAll())
          .thenAnswer((_) async => disabledResult);
      when(() => mockService.enable(any(), any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(uspInstantPrivacyProvider.future);

      // After enable, the notifier calls invalidateSelf which triggers re-fetch.
      // Set up the re-fetch to return enabled.
      when(() => mockService.fetchAll()).thenAnswer((_) async => enabledResult);

      await container.read(uspInstantPrivacyProvider.notifier).enable();

      verify(() => mockService.enable(
            ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02'],
            any(),
          )).called(1);
      container.dispose();
    });

    test('enable skips if already enabled', () async {
      when(() => mockService.fetchAll()).thenAnswer((_) async => enabledResult);
      final container = createContainer();
      await container.read(uspInstantPrivacyProvider.future);

      await container.read(uspInstantPrivacyProvider.notifier).enable();

      verifyNever(() => mockService.enable(any(), any()));
      container.dispose();
    });

    test('disable calls service.disable', () async {
      when(() => mockService.fetchAll()).thenAnswer((_) async => enabledResult);
      when(() => mockService.disable(any())).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(uspInstantPrivacyProvider.future);

      when(() => mockService.fetchAll())
          .thenAnswer((_) async => disabledResult);

      await container.read(uspInstantPrivacyProvider.notifier).disable();

      verify(() => mockService.disable(any())).called(1);
      container.dispose();
    });

    test('disable skips if already disabled', () async {
      when(() => mockService.fetchAll())
          .thenAnswer((_) async => disabledResult);
      final container = createContainer();
      await container.read(uspInstantPrivacyProvider.future);

      await container.read(uspInstantPrivacyProvider.notifier).disable();

      verifyNever(() => mockService.disable(any()));
      container.dispose();
    });

    test('enable error restores isToggleLocked to false', () async {
      when(() => mockService.fetchAll())
          .thenAnswer((_) async => disabledResult);
      when(() => mockService.enable(any(), any()))
          .thenThrow(const NetworkError(message: 'enable failed'));

      final container = createContainer();
      await container.read(uspInstantPrivacyProvider.future);

      expect(
        () => container.read(uspInstantPrivacyProvider.notifier).enable(),
        throwsA(isA<ServiceError>()),
      );
      await Future.delayed(Duration.zero);

      final state = container.read(uspInstantPrivacyProvider).valueOrNull;
      expect(state?.isToggleLocked, isFalse);
      container.dispose();
    });

    test('addMac calls service.addMac when enabled', () async {
      when(() => mockService.fetchAll()).thenAnswer((_) async => enabledResult);
      when(() => mockService.addMac(any(), any()))
          .thenAnswer((_) async => true);

      final container = createContainer();
      await container.read(uspInstantPrivacyProvider.future);

      when(() => mockService.fetchAll()).thenAnswer((_) async => enabledResult);

      await container
          .read(uspInstantPrivacyProvider.notifier)
          .addMac('FF:EE:DD:CC:BB:AA');

      verify(() => mockService.addMac('FF:EE:DD:CC:BB:AA', any())).called(1);
      container.dispose();
    });

    test('addMac skips if not enabled', () async {
      when(() => mockService.fetchAll())
          .thenAnswer((_) async => disabledResult);
      final container = createContainer();
      await container.read(uspInstantPrivacyProvider.future);

      await container
          .read(uspInstantPrivacyProvider.notifier)
          .addMac('FF:EE:DD:CC:BB:AA');

      verifyNever(() => mockService.addMac(any(), any()));
      container.dispose();
    });

    test('addMac restores isToggleLocked on already-present MAC', () async {
      when(() => mockService.fetchAll()).thenAnswer((_) async => enabledResult);
      when(() => mockService.addMac(any(), any()))
          .thenAnswer((_) async => false);

      final container = createContainer();
      await container.read(uspInstantPrivacyProvider.future);

      await container
          .read(uspInstantPrivacyProvider.notifier)
          .addMac('AA:BB:CC:DD:EE:01');

      final state = container.read(uspInstantPrivacyProvider).valueOrNull;
      expect(state?.isToggleLocked, isFalse);
      container.dispose();
    });
  });
}
