import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';

class MockUspWifiAdvancedService extends Mock
    implements UspWifiAdvancedService {}

void main() {
  late MockUspWifiAdvancedService mockService;

  setUp(() {
    mockService = MockUspWifiAdvancedService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspWifiAdvancedServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(uspWifiAdvancedProvider, (_, __) {});
    return container;
  }

  group('UspWifiAdvancedNotifier', () {
    // -----------------------------------------------------------------------
    // build
    // -----------------------------------------------------------------------

    test('build fetches IEEE80211h state via service', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.hasValue, isTrue);
      expect(state.requireValue.ieee80211hByRadio, {
        'Device.WiFi.Radio.1.': true,
        'Device.WiFi.Radio.2.': false,
      });
      verify(() => mockService.fetchIeee80211h()).called(1);
      container.dispose();
    });

    test('build sets error state when service throws', () async {
      when(() => mockService.fetchIeee80211h())
          .thenThrow(Exception('network error'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.hasError, isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // isDfsEnabled (computed getter on state)
    // -----------------------------------------------------------------------

    test('isDfsEnabled true when all radios have 80211h enabled', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': true,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      expect(container.read(uspWifiAdvancedProvider).requireValue.isDfsEnabled,
          isTrue);
      container.dispose();
    });

    test('isDfsEnabled false when any radio has 80211h disabled', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      expect(container.read(uspWifiAdvancedProvider).requireValue.isDfsEnabled,
          isFalse);
      container.dispose();
    });

    test('isDfsEnabled false when no radios report', () async {
      when(() => mockService.fetchIeee80211h())
          .thenAnswer((_) async => <String, bool>{});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      expect(container.read(uspWifiAdvancedProvider).requireValue.isDfsEnabled,
          isFalse);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // setIeee80211hEnabled
    // -----------------------------------------------------------------------

    test('setIeee80211hEnabled calls service and updates state', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
            'Device.WiFi.Radio.2.': false,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
          )).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      await notifier.setIeee80211hEnabled(true);

      verify(() => mockService.setIeee80211hEnabled(
            radioPaths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
            enabled: true,
          )).called(1);

      final state = container.read(uspWifiAdvancedProvider).requireValue;
      expect(state.ieee80211hByRadio['Device.WiFi.Radio.1.'], isTrue);
      expect(state.ieee80211hByRadio['Device.WiFi.Radio.2.'], isTrue);
      expect(state.isDfsEnabled, isTrue);
      container.dispose();
    });

    test('setIeee80211hEnabled does nothing when no radios known', () async {
      when(() => mockService.fetchIeee80211h())
          .thenAnswer((_) async => <String, bool>{});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      await notifier.setIeee80211hEnabled(true);

      verifyNever(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
          ));
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Error handling
    // -----------------------------------------------------------------------

    test('build sets AsyncError when service throws ServiceError', () async {
      when(() => mockService.fetchIeee80211h())
          .thenThrow(const NetworkError(message: 'timeout'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkError>());
      container.dispose();
    });

    test('setIeee80211hEnabled rethrows ServiceError from service', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
          )).thenThrow(const InvalidInputError(message: 'read-only'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      expect(
        () => notifier.setIeee80211hEnabled(true),
        throwsA(isA<InvalidInputError>()),
      );
      container.dispose();
    });

    test('setIeee80211hEnabled does not update state when service throws',
        () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
          )).thenThrow(const NetworkError(message: 'connection refused'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      try {
        await notifier.setIeee80211hEnabled(true);
      } on ServiceError catch (_) {
        // expected
      }

      // State should remain unchanged (still false)
      final state = container.read(uspWifiAdvancedProvider).requireValue;
      expect(state.ieee80211hByRadio['Device.WiFi.Radio.1.'], isFalse);
      container.dispose();
    });
  });
}
