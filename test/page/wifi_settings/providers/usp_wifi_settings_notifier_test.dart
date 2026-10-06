import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

import '../../../../test/mocks/test_data/wifi_settings_test_data.dart';

class MockUspWifiSettingsService extends Mock
    implements UspWifiSettingsService {}

class MockUspClient extends Mock implements UspClient {}

class MockUspAuthCoordinator extends Mock implements UspAuthCoordinator {}

const _written = {'Device.WiFi.SSID.1.SSID': 'Changed'};

/// A plan whose one SET the router answers.
WifiWritePlan confirmedPlan() => WifiWritePlan(
      params: _written,
      send: () async => WifiWriteOutcome.confirmed,
    );

void main() {
  late MockUspWifiSettingsService mockService;
  late MockUspClient mockUsp;
  late MockUspAuthCoordinator mockAuthCoordinator;

  setUpAll(() {
    registerFallbackValue(const WiFiSsids(items: []));
    registerFallbackValue(const WiFiAccessPoints(items: []));
    registerFallbackValue(const WiFiRadios(items: []));
    registerFallbackValue(<WifiNetworkUIModel>[]);
    registerFallbackValue(WifiSettingsSettings.empty());
    registerFallbackValue(const WifiSettingsStatus());
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockService = MockUspWifiSettingsService();
    mockUsp = MockUspClient();
    mockAuthCoordinator = MockUspAuthCoordinator();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
  });

  ProviderContainer createContainer({
    WifiData? wifiData,
    WifiDataNotifier Function()? wifiNotifier,
  }) {
    final data = wifiData ?? WifiSettingsTestData.createWifiData();
    final container = ProviderContainer(
      overrides: [
        uspWifiSettingsServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        uspClientProvider.overrideWithValue(mockUsp),
        uspAuthCoordinatorProvider.overrideWithValue(mockAuthCoordinator),
        wifiDataProvider
            .overrideWith(wifiNotifier ?? () => _FakeWifiDataNotifier(data)),
        // Short timings, so the read-back path runs without real waits.
        wifiAnswerWindowProvider
            .overrideWithValue(const Duration(milliseconds: 50)),
        wifiReadBackIntervalProvider
            .overrideWithValue(const Duration(milliseconds: 10)),
        wifiSaveDeadlineProvider
            .overrideWithValue(const Duration(milliseconds: 200)),
      ],
    );
    container.listen(uspWifiSettingsProvider, (_, __) {});
    return container;
  }

  group('UspWifiSettingsNotifier', () {
    // -----------------------------------------------------------------------
    // build / performFetch
    // -----------------------------------------------------------------------

    test('build returns initial loading state', () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: WifiSettingsTestData.createQuickSetupAggregate(),
        guest: null,
        isQuickSetup: true,
      ));

      final container = createContainer();
      final state = container.read(uspWifiSettingsProvider);

      expect(state.status.isLoading, isTrue);
      expect(state.settings.current.networks, isEmpty);

      // Let microtask (Future.microtask in build) complete before disposing
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);
      container.dispose();
    });

    test('fetch populates networks from L1 wifi data', () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: WifiSettingsTestData.createQuickSetupAggregate(),
        guest: null,
        isQuickSetup: true,
      ));

      final container = createContainer();
      // Wait for microtask (Future.microtask in build) + fetch
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiSettingsProvider);
      expect(state.settings.current.networks, hasLength(3));
      expect(state.status.isLoading, isFalse);
      container.dispose();
    });

    test('fetch sets error status when USP service unavailable', () async {
      final container = ProviderContainer(
        overrides: [
          uspWifiSettingsServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          uspClientProvider.overrideWithValue(null),
          uspAuthCoordinatorProvider.overrideWithValue(mockAuthCoordinator),
          wifiDataProvider.overrideWith(() =>
              _FakeWifiDataNotifier(WifiSettingsTestData.createWifiData())),
        ],
      );
      container.listen(uspWifiSettingsProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiSettingsProvider);
      expect(state.status.error, isA<ServiceNotInitializedError>());
      container.dispose();
    });

    // Regression: issue #1119. The provider must NOT gate its fetch on the raw
    // usp.isAuthenticated flag — in Remote Assistance that flag stays false by
    // design (authToken bypass), yet the WiFi data layer serves fine. Auth is
    // enforced by the router, not here.
    test('fetch proceeds when usp.isAuthenticated is false (RA bypass)',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: WifiSettingsTestData.createQuickSetupAggregate(),
        guest: null,
        isQuickSetup: true,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiSettingsProvider);
      expect(state.status.error, isNull);
      expect(state.settings.current.networks, hasLength(3));
      expect(state.status.isLoading, isFalse);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // updateNetworkField
    // -----------------------------------------------------------------------

    test('updateNetworkField changes SSID for target network', () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: WifiSettingsTestData.createQuickSetupAggregate(),
        guest: null,
        isQuickSetup: true,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.updateNetworkField('Device.WiFi.SSID.1.', ssid: 'NewSSID');

      final state = container.read(uspWifiSettingsProvider);
      final n1 = state.settings.current.networks
          .firstWhere((n) => n.ssidInstancePath == 'Device.WiFi.SSID.1.');
      expect(n1.ssid, 'NewSSID');
      expect(state.isDirty, isTrue);
      container.dispose();
    });

    test(
        'updateNetworkField auto-resets channel to auto when bandwidth changes and channel invalid',
        () async {
      final networks = [
        WifiSettingsTestData.createNetworkUIModel(
          ssidInstancePath: 'Device.WiFi.SSID.1.',
          band: '5GHz',
          channel: 100,
          autoChannelEnable: false,
          availableChannelsPerBandwidth: {
            '20MHz': [36, 40, 44, 48, 100, 104],
            '80MHz': [36, 40, 44, 48],
          },
        ),
      ];
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: null,
        guest: null,
        isQuickSetup: true,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      // Channel 100 is valid for 20MHz but not 80MHz
      notifier.updateNetworkField('Device.WiFi.SSID.1.',
          channelBandwidth: '80MHz');

      final state = container.read(uspWifiSettingsProvider);
      final n1 = state.settings.current.networks.first;
      // Should auto-reset to auto channel since 100 is not in 80MHz list
      expect(n1.autoChannelEnable, isTrue);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // setQuickSetupEnabled
    // -----------------------------------------------------------------------

    test(
        'setQuickSetupEnabled initializes quick setup settings from aggregates',
        () async {
      final networks = WifiSettingsTestData.createNetworks();
      final mainAggregate = WifiSettingsTestData.createQuickSetupAggregate();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: mainAggregate,
        guest: null,
        isQuickSetup: false,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.setQuickSetupEnabled(true);

      final state = container.read(uspWifiSettingsProvider);
      expect(state.settings.current.quickSetupEnabled, isTrue);
      expect(state.settings.current.quickSetupMain, isNotNull);
      expect(state.settings.current.quickSetupMain!.ssid, 'Home');
      expect(state.settings.current.quickSetupMain!.password, isEmpty);
      container.dispose();
    });

    test('setQuickSetupEnabled does not make state dirty', () async {
      final networks = WifiSettingsTestData.createNetworks();
      final mainAggregate = WifiSettingsTestData.createQuickSetupAggregate();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: mainAggregate,
        guest: null,
        isQuickSetup: false,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.setQuickSetupEnabled(true);

      expect(notifier.isDirty(), isFalse);

      final state = container.read(uspWifiSettingsProvider);
      expect(state.settings.original.quickSetupMain, isNotNull);
      expect(state.settings.original.quickSetupMain,
          state.settings.current.quickSetupMain);
      container.dispose();
    });

    test('updateQuickSetupField makes state dirty after setQuickSetupEnabled',
        () async {
      final networks = WifiSettingsTestData.createNetworks();
      final mainAggregate = WifiSettingsTestData.createQuickSetupAggregate();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: mainAggregate,
        guest: null,
        isQuickSetup: false,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.setQuickSetupEnabled(true);
      expect(notifier.isDirty(), isFalse);

      notifier.updateQuickSetupField(
        isGuest: false,
        securityMode: 'WPA3-Personal',
      );
      expect(notifier.isDirty(), isTrue);
      container.dispose();
    });

    test('setQuickSetupEnabled(false) clears quick setup settings', () async {
      final networks = WifiSettingsTestData.createNetworks();
      final mainAggregate = WifiSettingsTestData.createQuickSetupAggregate();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: mainAggregate,
        guest: null,
        isQuickSetup: false,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.setQuickSetupEnabled(true);
      notifier.setQuickSetupEnabled(false);

      final state = container.read(uspWifiSettingsProvider);
      expect(state.settings.current.quickSetupEnabled, isFalse);
      expect(state.settings.current.quickSetupMain, isNull);
      expect(state.settings.current.quickSetupGuest, isNull);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // updateQuickSetupField
    // -----------------------------------------------------------------------

    test('updateQuickSetupField updates main group fields', () async {
      final networks = WifiSettingsTestData.createNetworks();
      final mainAggregate = WifiSettingsTestData.createQuickSetupAggregate();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: mainAggregate,
        guest: null,
        isQuickSetup: true,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.updateQuickSetupField(
        isGuest: false,
        ssid: 'NewSSID',
        password: 'newpass1',
      );

      final state = container.read(uspWifiSettingsProvider);
      expect(state.settings.current.quickSetupMain!.ssid, 'NewSSID');
      expect(state.settings.current.quickSetupMain!.password, 'newpass1');
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // performSave
    // -----------------------------------------------------------------------

    test('save calls saveAdvanced when not in quick setup mode', () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: null,
        guest: null,
        isQuickSetup: false,
      ));
      when(() => mockService.saveAdvanced(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenReturn(confirmedPlan());

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.updateNetworkField('Device.WiFi.SSID.1.', ssid: 'Changed');
      await notifier.save();

      verify(() => mockService.saveAdvanced(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).called(1);
      verifyNever(() => mockService.saveQuickSetup(
            original: any(named: 'original'),
            current: any(named: 'current'),
            status: any(named: 'status'),
          ));
      container.dispose();
    });

    test('save calls saveQuickSetup when in quick setup mode', () async {
      final networks = WifiSettingsTestData.createNetworks();
      final mainAggregate = WifiSettingsTestData.createQuickSetupAggregate();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: mainAggregate,
        guest: null,
        isQuickSetup: true,
      ));
      when(() => mockService.saveQuickSetup(
            original: any(named: 'original'),
            current: any(named: 'current'),
            status: any(named: 'status'),
          )).thenReturn(confirmedPlan());

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.updateQuickSetupField(
        isGuest: false,
        password: 'newpass1',
      );
      await notifier.save();

      verify(() => mockService.saveQuickSetup(
            original: any(named: 'original'),
            current: any(named: 'current'),
            status: any(named: 'status'),
          )).called(1);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // performSave — a lost reply is read back, not reported (#1499, CG#215)
    // -----------------------------------------------------------------------

    group('save when the reply is lost to the WiFi reload', () {
      Future<UspWifiSettingsNotifier> quickSetupNotifier(
          ProviderContainer container) async {
        await Future.delayed(Duration.zero);
        await Future.delayed(Duration.zero);
        final notifier = container.read(uspWifiSettingsProvider.notifier);
        notifier.updateQuickSetupField(isGuest: false, password: 'newpass1');
        return notifier;
      }

      setUp(() {
        when(() => mockService.buildWifiNetworks(
              ssids: any(named: 'ssids'),
              accessPoints: any(named: 'accessPoints'),
              radios: any(named: 'radios'),
            )).thenReturn(WifiSettingsTestData.createNetworks());
        when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
          main: WifiSettingsTestData.createQuickSetupAggregate(),
          guest: null,
          isQuickSetup: true,
        ));
        when(() => mockService.saveQuickSetup(
              original: any(named: 'original'),
              current: any(named: 'current'),
              status: any(named: 'status'),
            )).thenReturn(WifiWritePlan(
          params: _written,
          // A rename: its new SSID is what a read-back can confirm.
          proof: _written,
          send: () async => WifiWriteOutcome.unanswered,
        ));
      });

      test('succeeds once the router reads back what was written', () async {
        when(() => mockService.isApplied(any())).thenAnswer((_) async => true);
        final container = createContainer();
        final notifier = await quickSetupNotifier(container);

        await notifier.save();

        verify(() => mockService.isApplied(_written)).called(1);
        expect(
            container.read(uspWifiSettingsProvider).status.isSaving, isFalse);
        container.dispose();
      });

      test(
          'a confirmed write is NOT failed by the L1 refresh timing out after '
          'it (#1499: both SETs had succeeded; the 15 s throttler on the '
          'post-save refresh is what the user saw)', () async {
        when(() => mockService.isApplied(any())).thenAnswer((_) async => true);
        final notifier = _ThrowOnRefresh();
        final container = createContainer(wifiNotifier: () => notifier);
        final settings = await quickSetupNotifier(container);
        // From here on L1 fails, as it did while the radios reloaded.
        notifier.failNext = true;

        await expectLater(settings.save(), completes);

        expect(notifier.failures, greaterThan(0),
            reason: 'the refresh must actually have failed, or this test '
                'proves nothing');
        container.dispose();
      });

      test('fails — never a false success — when it never reads back',
          () async {
        when(() => mockService.isApplied(any())).thenAnswer((_) async => false);
        final container = createContainer();
        final notifier = await quickSetupNotifier(container);

        await expectLater(notifier.save(), throwsA(isA<ServiceError>()));
        container.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // Dashboard quick actions — same write-then-confirm as the page save
    // -----------------------------------------------------------------------

    group('dashboard quick actions', () {
      setUp(() {
        when(() => mockService.buildWifiNetworks(
              ssids: any(named: 'ssids'),
              accessPoints: any(named: 'accessPoints'),
              radios: any(named: 'radios'),
            )).thenReturn(WifiSettingsTestData.createNetworks());
        when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
          main: null,
          guest: null,
          isQuickSetup: false,
        ));
      });

      test('toggleSsidsByName: an unanswered toggle is read back, then done',
          () async {
        when(() => mockService.toggleSsidsByName(any(), any(), any(), any()))
            .thenReturn(WifiWritePlan(
          params: const {'Device.WiFi.SSID.1.Enable': false},
          proof: const {'Device.WiFi.SSID.1.Enable': false},
          count: 1,
          send: () async => WifiWriteOutcome.unanswered,
        ));
        when(() => mockService.isApplied(any())).thenAnswer((_) async => true);
        final container = createContainer();
        await Future.delayed(Duration.zero);

        await container
            .read(uspWifiSettingsProvider.notifier)
            .toggleSsidsByName('Home', false);

        verify(() => mockService
            .isApplied(const {'Device.WiFi.SSID.1.Enable': false})).called(1);
        container.dispose();
      });

      test('toggleSsidsByName: no matching SSID is still an InvalidInputError',
          () async {
        when(() => mockService.toggleSsidsByName(any(), any(), any(), any()))
            .thenReturn(WifiWritePlan(
          params: const {},
          count: 0,
          send: () async => WifiWriteOutcome.confirmed,
        ));
        final container = createContainer();
        await Future.delayed(Duration.zero);

        await expectLater(
          container
              .read(uspWifiSettingsProvider.notifier)
              .toggleSsidsByName('Nope', false),
          throwsA(isA<InvalidInputError>()),
        );
        container.dispose();
      });

      test(
          'updateRadioChannel: an unanswered write that never reads back fails',
          () async {
        when(() => mockService.updateRadioChannel(
              any(),
              channel: any(named: 'channel'),
              autoChannel: any(named: 'autoChannel'),
            )).thenReturn(WifiWritePlan(
          params: const {'Device.WiFi.Radio.1.Channel': 40},
          proof: const {'Device.WiFi.Radio.1.Channel': 40},
          send: () async => WifiWriteOutcome.unanswered,
        ));
        when(() => mockService.isApplied(any())).thenAnswer((_) async => false);
        final container = createContainer();
        await Future.delayed(Duration.zero);

        await expectLater(
          container.read(uspWifiSettingsProvider.notifier).updateRadioChannel(
              'Device.WiFi.Radio.1.',
              channel: 40,
              autoChannel: false),
          throwsA(isA<ServiceError>()),
        );
        container.dispose();
      });
    });

    // -----------------------------------------------------------------------
    // isDirty / revert
    // -----------------------------------------------------------------------

    test('isDirty false initially, true after edit, false after revert',
        () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: null,
        guest: null,
        isQuickSetup: false,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.updateNetworkField('Device.WiFi.SSID.1.', ssid: 'Edited');
      expect(notifier.isDirty(), isTrue);

      notifier.revert();
      expect(notifier.isDirty(), isFalse);

      final state = container.read(uspWifiSettingsProvider);
      expect(state.settings.current.networks.first.ssid, 'Home');
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // effectiveNetwork
    // -----------------------------------------------------------------------

    test('effectiveNetwork returns matching network from current settings',
        () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: null,
        guest: null,
        isQuickSetup: false,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      final n = notifier.effectiveNetwork('Device.WiFi.SSID.2.');

      expect(n, isNotNull);
      expect(n!.band, '5GHz');
      container.dispose();
    });

    test('effectiveNetwork returns null for unknown path', () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: null,
        guest: null,
        isQuickSetup: false,
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      expect(notifier.effectiveNetwork('Device.WiFi.SSID.99.'), isNull);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Error handling — performFetch
    // -----------------------------------------------------------------------

    test(
        'performFetch returns error status when wifiDataProvider throws ServiceError',
        () async {
      final container = ProviderContainer(
        overrides: [
          uspWifiSettingsServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          uspClientProvider.overrideWithValue(mockUsp),
          uspAuthCoordinatorProvider.overrideWithValue(mockAuthCoordinator),
          wifiDataProvider.overrideWith(() =>
              _ErrorWifiDataNotifier(const NetworkError(detail: 'timeout'))),
        ],
      );
      container.listen(uspWifiSettingsProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiSettingsProvider);
      expect(state.status.error, isA<NetworkError>());
      expect(state.settings.current.networks, isEmpty);
      container.dispose();
    });

    // -----------------------------------------------------------------------
    // Error handling — save
    // -----------------------------------------------------------------------

    test('save rethrows ServiceError from service', () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: null,
        guest: null,
        isQuickSetup: false,
      ));
      when(() => mockService.saveAdvanced(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenReturn(WifiWritePlan(
        params: _written,
        send: () async => throw const NetworkError(detail: 'HTTP 504'),
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.updateNetworkField('Device.WiFi.SSID.1.', ssid: 'Changed');

      // Use await + expectLater so the finally block completes before dispose
      await expectLater(
        notifier.save(),
        throwsA(isA<NetworkError>()),
      );
      container.dispose();
    });

    test('save resets isSaving flag after ServiceError', () async {
      final networks = WifiSettingsTestData.createNetworks();
      when(() => mockService.buildWifiNetworks(
            ssids: any(named: 'ssids'),
            accessPoints: any(named: 'accessPoints'),
            radios: any(named: 'radios'),
          )).thenReturn(networks);
      when(() => mockService.buildQuickSetupNetworks(any())).thenReturn((
        main: null,
        guest: null,
        isQuickSetup: false,
      ));
      when(() => mockService.saveAdvanced(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenReturn(WifiWritePlan(
        params: _written,
        send: () async => throw const NetworkError(detail: 'HTTP 504'),
      ));

      final container = createContainer();
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspWifiSettingsProvider.notifier);
      notifier.updateNetworkField('Device.WiFi.SSID.1.', ssid: 'Changed');

      try {
        await notifier.save();
      } on ServiceError catch (_) {
        // expected
      }

      final state = container.read(uspWifiSettingsProvider);
      expect(state.status.isSaving, isFalse);
      container.dispose();
    });
  });
}

// ---------------------------------------------------------------------------
// Fake WifiDataNotifier that returns pre-built data without real USP calls
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Fake WifiDataNotifier that returns pre-built data without real USP calls
// ---------------------------------------------------------------------------

class _FakeWifiDataNotifier extends AsyncNotifier<WifiData>
    implements WifiDataNotifier {
  final WifiData _data;
  _FakeWifiDataNotifier(this._data);

  @override
  Future<WifiData> build() async => _data;
}

/// Builds normally, then throws on the next build once [failNext] is set — the
/// post-save refresh hitting the 15 s throttler while the radios reload.
class _ThrowOnRefresh extends AsyncNotifier<WifiData>
    implements WifiDataNotifier {
  bool failNext = false;
  int failures = 0;

  @override
  Future<WifiData> build() async {
    if (failNext) {
      failures++;
      throw const NetworkError(
          detail: 'TimeoutException after 0:00:15.000000: Throttler: request '
              'exceeded 15s');
    }
    return WifiSettingsTestData.createWifiData();
  }
}

// ---------------------------------------------------------------------------
// Fake WifiDataNotifier that throws ServiceError on build
// ---------------------------------------------------------------------------

class _ErrorWifiDataNotifier extends AsyncNotifier<WifiData>
    implements WifiDataNotifier {
  final ServiceError _error;
  _ErrorWifiDataNotifier(this._error);

  @override
  Future<WifiData> build() async => throw _error;
}
