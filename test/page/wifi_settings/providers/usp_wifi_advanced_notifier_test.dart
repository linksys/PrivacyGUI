import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
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
        wifiDataProvider.overrideWith(() => _StubWifiDataNotifier()),
      ],
    );
    container.listen(uspWifiAdvancedProvider, (_, __) {});
    return container;
  }

  group('UspWifiAdvancedNotifier - performFetch', () {
    test('fetches IEEE80211h state and sets settings', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.status.isLoading, isFalse);
      expect(state.status.errorMessage, isNull);
      expect(state.settings.current.ieee80211hByRadio, {
        'Device.WiFi.Radio.1.': true,
        'Device.WiFi.Radio.2.': false,
      });
      verify(() => mockService.fetchIeee80211h()).called(1);
      container.dispose();
    });

    test('sets error status when service throws ServiceError', () async {
      when(() => mockService.fetchIeee80211h())
          .thenThrow(const NetworkError(message: 'timeout'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.status.errorMessage, isNotNull);
      expect(state.settings.current.ieee80211hByRadio, isEmpty);
      container.dispose();
    });
  });

  group('UspWifiAdvancedNotifier - setDfsEnabled', () {
    test('updates current settings and marks dirty', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
            'Device.WiFi.Radio.2.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(true);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.current.isDfsEnabled, isTrue);
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    test('setDfsEnabled false updates all radios to false', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': true,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(false);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.current.isDfsEnabled, isFalse);
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    test('toggle on then off clears dirty (uniform original)', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
            'Device.WiFi.Radio.2.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      // Toggle ON → dirty
      notifier.setDfsEnabled(true);
      expect(container.read(uspWifiAdvancedProvider).isDirty, isTrue);

      // Toggle OFF → back to original → clean
      notifier.setDfsEnabled(false);
      expect(container.read(uspWifiAdvancedProvider).isDirty, isFalse);
      container.dispose();
    });

    test('toggle on then off clears dirty (mixed original)', () async {
      // Server returns mixed per-radio values (e.g. 2.4GHz=false, 5GHz=true)
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      // isDfsEnabled starts as false (not all true)

      // Toggle ON → dirty
      notifier.setDfsEnabled(true);
      expect(container.read(uspWifiAdvancedProvider).isDirty, isTrue);

      // Toggle OFF → restores original mixed map → clean
      notifier.setDfsEnabled(false);
      expect(container.read(uspWifiAdvancedProvider).isDirty, isFalse);
      container.dispose();
    });

    test('toggle off then on clears dirty (all-true original)', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': true,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      // Toggle OFF → dirty
      notifier.setDfsEnabled(false);
      expect(container.read(uspWifiAdvancedProvider).isDirty, isTrue);

      // Toggle ON → back to original → clean
      notifier.setDfsEnabled(true);
      expect(container.read(uspWifiAdvancedProvider).isDirty, isFalse);
      container.dispose();
    });

    test('setDfsEnabled does not call service', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(true);

      // Only fetchIeee80211h should have been called (from build), not set
      verifyNever(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
          ));
      container.dispose();
    });
  });

  group('UspWifiAdvancedNotifier - revert', () {
    test('reverts current to original and clears dirty', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
            'Device.WiFi.Radio.2.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(true);
      expect(container.read(uspWifiAdvancedProvider).isDirty, isTrue);

      notifier.revert();
      final state = container.read(uspWifiAdvancedProvider);
      expect(state.isDirty, isFalse);
      expect(state.settings.current.isDfsEnabled, isFalse);
      container.dispose();
    });
  });

  group('UspWifiAdvancedNotifier - performSave', () {
    test('calls service with correct params on save', () async {
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
      notifier.setDfsEnabled(true);
      await notifier.save();

      verify(() => mockService.setIeee80211hEnabled(
            radioPaths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
            enabled: true,
          )).called(1);
      container.dispose();
    });

    test('save rethrows ServiceError', () async {
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
      notifier.setDfsEnabled(true);

      expect(() => notifier.save(), throwsA(isA<InvalidInputError>()));
      container.dispose();
    });

    test('isSaving flag toggles during save', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
          )).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(true);

      // After save completes, isSaving should be false
      await notifier.save();
      final state = container.read(uspWifiAdvancedProvider);
      expect(state.status.isSaving, isFalse);
      container.dispose();
    });
  });

  group('UspWifiAdvancedNotifier - isDfsEnabled', () {
    test('true when all radios enabled', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': true,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.current.isDfsEnabled, isTrue);
      container.dispose();
    });

    test('false when any radio disabled', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': false,
          });

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.current.isDfsEnabled, isFalse);
      container.dispose();
    });

    test('false when no radios report', () async {
      when(() => mockService.fetchIeee80211h())
          .thenAnswer((_) async => <String, bool>{});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.current.isDfsEnabled, isFalse);
      container.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Stub for wifiDataProvider to prevent real fetches in tests.
// ---------------------------------------------------------------------------

class _StubWifiDataNotifier extends WifiDataNotifier {
  @override
  Future<WifiData> build() async => throw UnimplementedError();
}
