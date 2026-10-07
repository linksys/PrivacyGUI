import 'dart:async';

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
    // Every fetch reads the steering switches too (#1661). Stubbed here so the
    // DFS-only tests below need not repeat it; the steering group overrides it.
    when(() => mockService.fetchSteering())
        .thenAnswer((_) async => (clientSteering: false, nodeSteering: false));
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
      // EXACTLY once. This used to be `greaterThanOrEqualTo(1)` with a comment about
      // an SSE listener re-triggering the fetch — that listener was deleted in #1587
      // Phase 1, and the loose matcher would pass whether or not one came back.
      verify(() => mockService.fetchIeee80211h()).called(1);
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

      // Awaited: unawaited, `dispose()` below runs before the save reaches the
      // service, and the matcher sees a disposed-container error instead.
      await expectLater(notifier.save(), throwsA(isA<InvalidInputError>()));
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

  // -------------------------------------------------------------------------
  // linksys/PrivacyGUI#1587 Phase 1 — the two contracts the deletion created.
  //
  // Phase 1 removed `onSseInvalidation()` and, with it, the `ref.listen` that this
  // notifier's DFS remediation had been relying on WITHOUT SAYING SO. Both facts below
  // were true only by accident before, and nothing failed when they stopped being true:
  // the remediation went silent, and no test noticed.
  // -------------------------------------------------------------------------
  group('UspWifiAdvancedNotifier - #1587 Phase 1 contracts', () {
    test('DFS remediation reads L1 by value, not by an incidental subscription',
        () async {
      // WHAT THIS PINS. The remediation used to read `ref.read(wifiDataProvider).valueOrNull`,
      // which returns null unless L1 happens to be built AND settled. Nothing in this
      // notifier guaranteed either — the deleted `onSseInvalidation()` wiring did, as a
      // side effect of holding a `ref.listen`. With it gone, `radioModels` came back empty
      // and the radio parked on a DFS channel was never recognised.
      //
      // The container below subscribes to L2 (which is autoDispose and needs a subscriber
      // to survive between reads at all) but NEVER to `wifiDataProvider`. So L1 is cold
      // when `performSave` reaches it, which is exactly the production shape: a save is the
      // first thing to touch L1 on a page whose widgets never watched it.
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          uspWifiAdvancedServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          wifiDataProvider.overrideWith(() => _StubWifiDataNotifier([
                // Radio 1 parked on a manual DFS channel — the case remediation exists for.
                _radioModel(
                  instancePath: 'Device.WiFi.Radio.1.',
                  band: '5GHz',
                  channel: 52,
                  autoChannelEnable: false,
                ),
              ])),
        ],
      );
      addTearDown(container.dispose);

      // L2 only. Nothing subscribes to `wifiDataProvider`.
      container.listen(uspWifiAdvancedProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      container.read(uspWifiAdvancedProvider.notifier).setDfsEnabled(false);
      await container.read(uspWifiAdvancedProvider.notifier).save();

      // Before the fix this list was EMPTY: the bare `ref.read` returned AsyncLoading,
      // `radioModels` was empty, and the radio parked on channel 52 was never recognised
      // — DFS went off and the radio stayed on a DFS channel.
      final captured = verify(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: false,
            forceAutoChannelPaths: captureAny(named: 'forceAutoChannelPaths'),
          )).captured.single as List<String>;
      expect(captured, ['Device.WiFi.Radio.1.'],
          reason: 'the radio on DFS channel 52 must be forced to auto-channel');
    });

    test('the retry catches an error L1 is not documented to throw', () async {
      // WHY THIS IS SEPARATE FROM THE TEST BELOW. That one throws `NetworkError`, a
      // `ServiceError` subclass — so it passes under both `on ServiceError` and
      // `catch (e)` and cannot distinguish them. Today every path into L1 does throw a
      // `ServiceError` (the service maps USP errors; its provider throws
      // `ServiceNotInitializedError`), but that is the current implementation, not a
      // guarantee in any signature. A narrower catch would turn the day that changes
      // into a save that fails without retrying.
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          uspWifiAdvancedServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          wifiDataProvider.overrideWith(() => _FlakyWifiDataNotifier(
                onBuild: () {},
                // Deliberately NOT a ServiceError.
                firstError: StateError('codegen blew up'),
                radios: [
                  _radioModel(
                    instancePath: 'Device.WiFi.Radio.1.',
                    band: '5GHz',
                    channel: 52,
                    autoChannelEnable: false,
                  ),
                ],
              )),
        ],
      );
      addTearDown(container.dispose);

      container.listen(uspWifiAdvancedProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      container.read(uspWifiAdvancedProvider.notifier).setDfsEnabled(false);
      await container.read(uspWifiAdvancedProvider.notifier).save();

      final captured = verify(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: false,
            forceAutoChannelPaths: captureAny(named: 'forceAutoChannelPaths'),
          )).captured.single as List<String>;
      expect(captured, ['Device.WiFi.Radio.1.'],
          reason: 'a non-ServiceError must be retried too, not propagated');
    });

    test('a cached L1 failure is retried once rather than failing the save',
        () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});

      // Fails the first build, succeeds after a refresh. `wifiDataProvider` is not
      // autoDispose and has no retry, so without the one refresh in `performSave` every
      // later `.future` would replay this same error and DFS saves would stay broken.
      var builds = 0;
      final container = ProviderContainer(
        overrides: [
          uspWifiAdvancedServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          wifiDataProvider.overrideWith(() => _FlakyWifiDataNotifier(
                onBuild: () => builds++,
                radios: [
                  _radioModel(
                    instancePath: 'Device.WiFi.Radio.1.',
                    band: '5GHz',
                    channel: 52,
                    autoChannelEnable: false,
                  ),
                ],
              )),
        ],
      );
      addTearDown(container.dispose);

      container.listen(uspWifiAdvancedProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      container.read(uspWifiAdvancedProvider.notifier).setDfsEnabled(false);
      await container.read(uspWifiAdvancedProvider.notifier).save();

      expect(builds, greaterThanOrEqualTo(2),
          reason:
              'the failed L1 read must be retried, not replayed from cache');
      final captured = verify(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: false,
            forceAutoChannelPaths: captureAny(named: 'forceAutoChannelPaths'),
          )).captured.single as List<String>;
      expect(captured, ['Device.WiFi.Radio.1.'],
          reason: 'remediation must still happen after the retry');
    });
  });

  group('UspWifiAdvancedNotifier - steering (#1661)', () {
    void stubDfs(Map<String, bool> byRadio) {
      when(() => mockService.fetchIeee80211h())
          .thenAnswer((_) async => byRadio);
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async {});
    }

    void stubSteeringRead({required bool client, required bool node}) {
      when(() => mockService.fetchSteering()).thenAnswer(
          (_) async => (clientSteering: client, nodeSteering: node));
    }

    void stubSteeringWrite() {
      when(() => mockService.setSteering(
            clientSteering: any(named: 'clientSteering'),
            nodeSteering: any(named: 'nodeSteering'),
          )).thenAnswer((_) async {});
    }

    test('fetch reads the switches from the device', () async {
      stubDfs({'Device.WiFi.Radio.1.': true});
      stubSteeringRead(client: true, node: false);

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);

      final current = container.read(uspWifiAdvancedProvider).settings.current;
      expect(current.clientSteering, isTrue);
      expect(current.nodeSteering, isFalse);
      expect(current.ieee80211hByRadio, {'Device.WiFi.Radio.1.': true});
    });

    test('a failed steering read fails the tab like a failed DFS read',
        () async {
      stubDfs({'Device.WiFi.Radio.1.': true});
      when(() => mockService.fetchSteering())
          .thenThrow(const NetworkError(detail: 'timeout'));

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.status.error, isA<NetworkError>(),
          reason: 'drawing two switches from a read that failed would state a '
              'setting nobody knows');
    });

    test('each switch edits only itself and marks the tab dirty', () async {
      stubDfs({'Device.WiFi.Radio.1.': true});
      stubSteeringRead(client: false, node: false);

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setClientSteering(true);
      var current = container.read(uspWifiAdvancedProvider).settings.current;
      expect(current.clientSteering, isTrue);
      expect(current.nodeSteering, isFalse);
      expect(container.read(uspWifiAdvancedProvider).isDirty, isTrue);

      notifier.setClientSteering(false);
      notifier.setNodeSteering(true);
      current = container.read(uspWifiAdvancedProvider).settings.current;
      expect(current.clientSteering, isFalse);
      expect(current.nodeSteering, isTrue);
      expect(current.ieee80211hByRadio, {'Device.WiFi.Radio.1.': true});
    });

    test('toggling DFS back to its original keeps a pending steering edit',
        () async {
      // `setDfsEnabled` restores the original radio map when DFS goes back to
      // where it started, so a mixed per-radio original stops reading dirty. It
      // must restore only the map: restoring the whole settings object would
      // silently undo a steering switch the user flipped first.
      stubDfs({'Device.WiFi.Radio.1.': false, 'Device.WiFi.Radio.2.': true});
      stubSteeringRead(client: false, node: false);

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setNodeSteering(true);
      notifier.setDfsEnabled(true);
      notifier.setDfsEnabled(false);

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.current.nodeSteering, isTrue);
      expect(state.settings.current.ieee80211hByRadio,
          {'Device.WiFi.Radio.1.': false, 'Device.WiFi.Radio.2.': true});
      expect(state.isDirty, isTrue);
    });

    test('a steering-only save sends one steering Set and no DFS Set',
        () async {
      stubDfs({'Device.WiFi.Radio.1.': true});
      stubSteeringRead(client: false, node: false);
      stubSteeringWrite();

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setClientSteering(true);
      expect(container.read(uspWifiAdvancedProvider).changesDfs, isFalse);
      await notifier.save();

      // Only the switch that changed, so the other one is not rewritten with
      // the value this page read on entry.
      verify(() => mockService.setSteering(clientSteering: true)).called(1);
      verifyNever(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          ));
    });

    test('both switches changed go out in one steering Set', () async {
      stubDfs({'Device.WiFi.Radio.1.': true});
      stubSteeringRead(client: true, node: false);
      stubSteeringWrite();

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setClientSteering(false);
      notifier.setNodeSteering(true);
      await notifier.save();

      verify(() => mockService.setSteering(
            clientSteering: false,
            nodeSteering: true,
          )).called(1);
    });

    test('a DFS-only save sends no steering Set', () async {
      stubDfs({'Device.WiFi.Radio.1.': false});
      stubSteeringRead(client: false, node: false);
      stubSteeringWrite();

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setDfsEnabled(true);
      expect(container.read(uspWifiAdvancedProvider).changesDfs, isTrue);
      await notifier.save();

      verifyNever(() => mockService.setSteering(
            clientSteering: any(named: 'clientSteering'),
            nodeSteering: any(named: 'nodeSteering'),
          ));
      verify(() => mockService.setIeee80211hEnabled(
            radioPaths: ['Device.WiFi.Radio.1.'],
            enabled: true,
            forceAutoChannelPaths: const [],
          )).called(1);
    });

    test('a mixed save writes steering before the radio-reloading DFS Set',
        () async {
      stubDfs({'Device.WiFi.Radio.1.': false});
      stubSteeringRead(client: false, node: false);
      final calls = <String>[];
      when(() => mockService.setSteering(
            clientSteering: any(named: 'clientSteering'),
            nodeSteering: any(named: 'nodeSteering'),
          )).thenAnswer((_) async => calls.add('steering'));
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async => calls.add('dfs'));

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setNodeSteering(true);
      notifier.setDfsEnabled(true);
      await notifier.save();

      expect(calls, ['steering', 'dfs'],
          reason: 'the DFS write reloads every radio; the steering write must '
              'not be sent into that reload');
    });

    test('a refused steering Set re-reads the device and rethrows', () async {
      stubDfs({'Device.WiFi.Radio.1.': true});
      stubSteeringRead(client: false, node: false);
      when(() => mockService.setSteering(
            clientSteering: any(named: 'clientSteering'),
            nodeSteering: any(named: 'nodeSteering'),
          )).thenThrow(const UnexpectedError(detail: 'refused (9007)'));

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setClientSteering(true);
      await expectLater(notifier.save(), throwsA(isA<UnexpectedError>()));

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.current.clientSteering, isFalse,
          reason: 'the switch shows what the device holds, not the refused '
              'value');
      expect(state.isDirty, isFalse);
      expect(state.status.isSaving, isFalse);
      // Once on entry, once to settle the failure.
      verify(() => mockService.fetchSteering()).called(2);
    });

    test('a steering Set that outlasts the lock is a TimeoutError, re-read',
        () async {
      // The lock throws a bare TimeoutException at its window; unfolded it
      // skipped the re-read and reached the view as an unexpected error.
      stubDfs({'Device.WiFi.Radio.1.': true});
      stubSteeringRead(client: false, node: false);
      stubSteeringWrite();
      final container = ProviderContainer(
        overrides: [
          uspWifiAdvancedServiceProvider.overrideWithValue(mockService),
          // What the real lock throws at its 30 s window, without waiting.
          uspMutationLockProvider.overrideWithValue(_TimingOutLock()),
          wifiDataProvider.overrideWith(() => _StubWifiDataNotifier(const [])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(uspWifiAdvancedProvider, (_, __) {});
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setClientSteering(true);
      await expectLater(notifier.save(), throwsA(isA<TimeoutError>()));

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.current.clientSteering, isFalse);
      expect(state.isDirty, isFalse);
      verify(() => mockService.fetchSteering()).called(2);
    });

    test('a DFS failure after a landed steering write keeps steering saved',
        () async {
      stubDfs({'Device.WiFi.Radio.1.': false});
      stubSteeringRead(client: false, node: false);
      stubSteeringWrite();
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenThrow(const NetworkError(detail: 'radio reload timeout'));

      final container = createContainer();
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);

      notifier.setClientSteering(true);
      notifier.setDfsEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<NetworkError>()));

      final state = container.read(uspWifiAdvancedProvider);
      expect(state.settings.original.clientSteering, isTrue,
          reason: 'the steering Set succeeded, so it is no longer an unsaved '
              'edit');
      expect(state.settings.current.isDfsEnabled, isTrue,
          reason: 'the DFS edit is still pending, as before #1661');
      expect(state.isDirty, isTrue);
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

/// Throws on its first build and succeeds afterwards — for the retry contract.
class _FlakyWifiDataNotifier extends WifiDataNotifier {
  _FlakyWifiDataNotifier({
    required this.onBuild,
    required this.radios,
    this.firstError = const NetworkError(detail: 'L1 unreachable'),
  });

  final void Function() onBuild;
  final List<WifiRadioUIModel> radios;

  /// A parameter rather than a fixed `ServiceError`, because the retry deliberately
  /// catches everything: a test that only throws a `ServiceError` subclass cannot tell
  /// `catch (e)` from `on ServiceError`.
  final Object firstError;
  var _failed = false;

  @override
  Future<WifiData> build() async {
    onBuild();
    if (!_failed) {
      _failed = true;
      throw firstError;
    }
    return WifiData(
      codegenContext: WifiCodegenContext.empty,
      radioModels: radios,
    );
  }
}

/// A lock whose action never finishes inside its window: throws what
/// [UspMutationLock.withLock] throws when the window closes, at once.
class _TimingOutLock extends UspMutationLock {
  @override
  Future<T> withLock<T>(Future<T> Function() action,
          {Duration timeout = UspMutationLock.defaultTimeout}) =>
      Future.error(TimeoutException(
          'USP mutation timed out after ${timeout.inSeconds}s', timeout));
}
