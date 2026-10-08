import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

class MockUspWifiAdvancedService extends Mock
    implements UspWifiAdvancedService {}

/// The plan builder never touches the client; this only satisfies its type.
class _NoUsp extends Mock implements UspClient {}

/// The real service, with its one GET answered by [_source]'s stub — so the
/// read-back comparison under test is the production one.
class _ReadBackVia extends UspWifiAdvancedService {
  _ReadBackVia(this._source) : super(_NoUsp());
  final UspWifiAdvancedService _source;

  @override
  Future<Map<String, bool>> fetchIeee80211h() => _source.fetchIeee80211h();
}

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
    // The plan and its read-back are the real service's, so these tests pin
    // the real params and proof. Only the SET and the GET are mocked: `send`
    // goes through the mocked setIeee80211hEnabled, so every `verify` of it
    // below still sees the call, and the read-back reads fetchIeee80211h.
    when(() => mockService.planIeee80211h(
          current: any(named: 'current'),
          radioPaths: any(named: 'radioPaths'),
          enabled: any(named: 'enabled'),
          forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
        )).thenAnswer((inv) {
      final current = inv.namedArguments[#current] as Map<String, bool>;
      final radioPaths = inv.namedArguments[#radioPaths] as List<String>;
      final enabled = inv.namedArguments[#enabled] as bool;
      final force = inv.namedArguments[#forceAutoChannelPaths] as List<String>;
      final real = UspWifiAdvancedService(_NoUsp()).planIeee80211h(
        current: current,
        radioPaths: radioPaths,
        enabled: enabled,
        forceAutoChannelPaths: force,
      );
      return WifiWritePlan(
        params: real.params,
        proof: real.proof,
        send: () => mockService.setIeee80211hEnabled(
          radioPaths: radioPaths,
          enabled: enabled,
          forceAutoChannelPaths: force,
        ),
      );
    });
    // The real comparison, over the mocked GET — not a copy of it.
    when(() => mockService.isIeee80211hApplied(any())).thenAnswer((inv) =>
        _ReadBackVia(mockService).isIeee80211hApplied(
            inv.positionalArguments.first as Map<String, dynamic>));
  });

  setUpAll(() {
    registerFallbackValue(<String, bool>{});
    registerFallbackValue(<String, dynamic>{});
  });

  ProviderContainer createContainer({
    List<WifiRadioUIModel> radios = const [],
    WifiDataNotifier Function()? wifiNotifier,
  }) {
    final container = ProviderContainer(
      overrides: [
        uspWifiAdvancedServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        wifiDataProvider
            .overrideWith(wifiNotifier ?? () => _StubWifiDataNotifier(radios)),
        // Short timings, so the read-back path runs without real waits.
        wifiAnswerWindowProvider
            .overrideWithValue(const Duration(milliseconds: 50)),
        wifiReadBackIntervalProvider
            .overrideWithValue(const Duration(milliseconds: 10)),
        wifiSaveDeadlineProvider
            .overrideWithValue(const Duration(milliseconds: 200)),
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
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);

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
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);

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
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);

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
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);

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
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);

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
  group('UspWifiAdvancedNotifier - a lost reply is read back (#1460)', () {
    // #1460: over Remote Assistance the DFS SET took 35.4 s and returned
    // success, but the lock gave up at 30 s and the page reported a failure.
    void stubDfs({required Map<String, bool> readsBack}) {
      var first = true;
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async {
        if (first) {
          first = false;
          return {'Device.WiFi.Radio.1.': true};
        }
        return readsBack;
      });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async => WifiWriteOutcome.unanswered);
    }

    test('succeeds when the radios read back the new DFS state', () async {
      stubDfs(readsBack: {'Device.WiFi.Radio.1.': false});
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(false);

      await notifier.save();

      expect(container.read(uspWifiAdvancedProvider).status.isSaving, isFalse);
      container.dispose();
    });

    test('outlasting the lock window is read back, not reported', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
          });
      when(() => mockService.setIeee80211hEnabled(
                radioPaths: any(named: 'radioPaths'),
                enabled: any(named: 'enabled'),
                forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
              ))
          // Never answers inside the 50 ms window — #1460's 35.4 s against 30.
          .thenAnswer((_) => Completer<WifiWriteOutcome>().future);
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(true);
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': true,
          });

      await expectLater(notifier.save(), completes,
          reason: 'past the window is a read-back, not an error');

      // The SET never answered, so only reading the radios back could have
      // settled the save.
      verify(() => mockService.isIeee80211hApplied(
          {'Device.WiFi.Radio.1.IEEE80211hEnabled': true})).called(1);
      container.dispose();
    });

    test(
        'a confirmed DFS write is NOT failed by the L1 refresh after it '
        '(the 15 s throttler while the radios reload)', () async {
      when(() => mockService.fetchIeee80211h()).thenAnswer((_) async => {
            'Device.WiFi.Radio.1.': false,
          });
      when(() => mockService.setIeee80211hEnabled(
            radioPaths: any(named: 'radioPaths'),
            enabled: any(named: 'enabled'),
            forceAutoChannelPaths: any(named: 'forceAutoChannelPaths'),
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);
      final l1 = _FailAfterFirstBuild();
      final container = createContainer(wifiNotifier: () => l1);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(true);
      l1.fail = true;

      await expectLater(notifier.save(), completes);

      expect(l1.failures, greaterThan(0),
          reason: 'the refresh must actually have failed, or this test '
              'proves nothing');

      verify(() => mockService.setIeee80211hEnabled(
            radioPaths: ['Device.WiFi.Radio.1.'],
            enabled: true,
            forceAutoChannelPaths: const [],
          )).called(1);
      container.dispose();
    });

    test('fails when the radios never read back the new state', () async {
      stubDfs(readsBack: {'Device.WiFi.Radio.1.': true});
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspWifiAdvancedProvider.notifier);
      notifier.setDfsEnabled(false);

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));
      container.dispose();
    });
  });

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
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);

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
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);

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
          )).thenAnswer((_) async => WifiWriteOutcome.confirmed);

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

/// Builds normally until [fail] is set, then throws — the post-save refresh
/// hitting the 15 s throttler.
class _FailAfterFirstBuild extends WifiDataNotifier {
  bool fail = false;
  int failures = 0;

  @override
  Future<WifiData> build() async {
    if (fail) {
      failures++;
      throw const NetworkError(detail: 'Throttler: request exceeded 15s');
    }
    return const WifiData.empty();
  }
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
