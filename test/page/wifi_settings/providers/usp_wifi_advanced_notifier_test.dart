import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';

class MockUspWifiAdvancedService extends Mock
    implements UspWifiAdvancedService {}

WifiRadioUIModel _radioModel({
  required String instancePath,
  required String band,
  required int channel,
  required bool autoChannelEnable,
}) =>
    WifiRadioUIModel(
      instancePath: instancePath,
      band: band,
      enable: true,
      transmitPower: 100,
      maxBitRate: 2402,
      channel: channel,
      autoChannelEnable: autoChannelEnable,
      channelBandwidth: '80MHz',
      supportedStandards: 'a,n,ac,ax',
    );

void main() {
  late MockUspWifiAdvancedService mockService;

  setUp(() {
    mockService = MockUspWifiAdvancedService();
  });

  ProviderContainer createContainer({
    List<WifiRadioUIModel> radios = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        uspWifiAdvancedServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        wifiDataProvider.overrideWith(() => _StubWifiDataNotifier(radios)),
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
      expect(state.status.error, isNull);
      expect(state.settings.current.ieee80211hByRadio, {
        'Device.WiFi.Radio.1.': true,
        'Device.WiFi.Radio.2.': false,
      });
      // Called at least once from build(); may be called again if SSE listener
      // triggers due to wifiDataProvider stub emitting a value.
      verify(() => mockService.fetchIeee80211h())
          .called(greaterThanOrEqualTo(1));
      container.dispose();
    });

    test('sets error status when service throws ServiceError', () async {
      when(() => mockService.fetchIeee80211h())
          .thenThrow(const NetworkError(detail: 'timeout'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.status.error, isA<NetworkError>());
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
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
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
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(true);
      await notifier.save();

      verify(() => mockService.setIeee80211hEnabled(
            radioPaths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
            enabled: true,
            forceAutoChannelPaths: const [],
          )).called(1);
      container.dispose();
    });

    test(
        'disabling DFS forces AutoChannelEnable on radios parked on a DFS '
        'channel', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
            'Device.WiFi.Radio.2.': true,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});

      final container = createContainer(radios: [
        // 2.4 GHz on ch 6 — never DFS, must not be forced.
        _radioModel(
          instancePath: 'Device.WiFi.Radio.1.',
          band: '2.4GHz',
          channel: 6,
          autoChannelEnable: false,
        ),
        // 5 GHz manually parked on DFS ch 100 — must be forced to auto.
        _radioModel(
          instancePath: 'Device.WiFi.Radio.2.',
          band: '5GHz',
          channel: 100,
          autoChannelEnable: false,
        ),
      ]);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(false);
      await notifier.save();

      verify(() => mockService.setIeee80211hEnabled(
            radioPaths: ['Device.WiFi.Radio.1.', 'Device.WiFi.Radio.2.'],
            enabled: false,
            forceAutoChannelPaths: ['Device.WiFi.Radio.2.'],
          )).called(1);
      container.dispose();
    });

    test(
        'disabling DFS does not force auto-channel when the 5 GHz radio is on '
        'a non-DFS channel', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.2.': true,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});

      final container = createContainer(radios: [
        // 5 GHz on ch 36 (non-DFS) — no remediation needed.
        _radioModel(
          instancePath: 'Device.WiFi.Radio.2.',
          band: '5GHz',
          channel: 36,
          autoChannelEnable: false,
        ),
      ]);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(false);
      await notifier.save();

      verify(() => mockService.setIeee80211hEnabled(
            radioPaths: ['Device.WiFi.Radio.2.'],
            enabled: false,
            forceAutoChannelPaths: const [],
          )).called(1);
      container.dispose();
    });

    test('disabling DFS skips a radio already on auto-channel', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.2.': true,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});

      final container = createContainer(radios: [
        // Auto-channel already on: firmware will pick a legal channel itself.
        _radioModel(
          instancePath: 'Device.WiFi.Radio.2.',
          band: '5GHz',
          channel: 100,
          autoChannelEnable: true,
        ),
      ]);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(false);
      await notifier.save();

      verify(() => mockService.setIeee80211hEnabled(
            radioPaths: ['Device.WiFi.Radio.2.'],
            enabled: false,
            forceAutoChannelPaths: const [],
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
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenThrow(const InvalidInputError(detail: 'read-only'));

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
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
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
  _StubWifiDataNotifier(this._radios);

  final List<WifiRadioUIModel> _radios;

  @override
  Future<WifiData> build() async => _radios.isEmpty
      ? const WifiData.empty()
      : WifiData(
          codegenContext: WifiCodegenContext.empty,
          radioModels: _radios,
        );
}
