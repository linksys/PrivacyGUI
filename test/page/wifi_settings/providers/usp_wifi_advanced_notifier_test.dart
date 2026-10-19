import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/mlo_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/mlo_status_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

import '../../../mocks/provider_overrides/mock_wifi_settings.dart';

const _mlo = 'Device.X_LINKSYS_Mesh.MLOEnabled';
const _client = 'Device.X_LINKSYS_Mesh.ClientSteeringEnabled';
const _node = 'Device.X_LINKSYS_Mesh.NodeSteeringEnabled';
const _r1 = 'Device.WiFi.Radio.1.';
const _r2 = 'Device.WiFi.Radio.2.';

/// What the device holds, for the mocked service to read and write.
///
/// The notifier runs over a Mocktail service (constitution Article VIII §8.2).
/// Its plan is the real [UspWifiAdvancedService.planSave], so the params and
/// proof under test are production's; sending the plan writes [values] here
/// and records the Set in [sets], and the fetches and the read-back read
/// [values]. A leaf in [refuse] is refused and keeps its old value, which is
/// what `allowPartial: true` does on FLWRT 2.0; a leaf in [sticky] is reported
/// applied but keeps its old value.
class _Device {
  _Device(this.values);

  final Map<String, bool> values;
  final sets = <Map<String, dynamic>>[];
  Set<String> refuse = {};
  Set<String> sticky = {};

  /// Read failures to answer before reading normally again.
  int failReads = 0;

  /// When set, the next Set waits on it — a reply lost to the Wi-Fi restart.
  Completer<void>? holdSet;

  void _read() {
    if (failReads > 0) {
      failReads--;
      throw const NetworkError(detail: 'Failed to fetch');
    }
  }

  void stub(MockUspWifiAdvancedService svc) {
    when(() => svc.fetchIeee80211h()).thenAnswer((_) async {
      _read();
      return {
        for (final e in values.entries)
          if (e.key.endsWith('IEEE80211hEnabled'))
            e.key.substring(0, e.key.length - 'IEEE80211hEnabled'.length):
                e.value,
      };
    });
    when(() => svc.fetchSteering()).thenAnswer((_) async {
      _read();
      return (clientSteering: values[_client]!, nodeSteering: values[_node]!);
    });
    when(() => svc.fetchMloEnabled()).thenAnswer((_) async {
      _read();
      return values[_mlo]!;
    });
    stubRealPlanSave(svc, send: _send);
    when(() => svc.isApplied(any())).thenAnswer((inv) async {
      _read();
      final proof = inv.positionalArguments.first as Map<String, dynamic>;
      return proof.isNotEmpty &&
          proof.entries.every((e) => values[e.key] == e.value);
    });
  }

  Future<WifiWriteOutcome> _send(Map<String, dynamic> params) async {
    sets.add(params);
    final hold = holdSet;
    if (hold != null) await hold.future;
    for (final e in params.entries) {
      if (e.key.endsWith('AutoChannelEnable')) continue;
      if (refuse.contains(e.key) || sticky.contains(e.key)) continue;
      values[e.key] = e.value as bool;
    }
    if (refuse.any(params.containsKey)) {
      throw const UspPartialFailureError(
        summary: 'WiFi Advanced partial failure: Request denied',
        successPaths: [],
        failures: [],
      );
    }
    return WifiWriteOutcome.confirmed;
  }
}

/// What FW 2.0.3.26101472 read on the bench on 2026-10-15, both main radios.
Map<String, bool> _bench({
  bool dfs = false,
  bool client = false,
  bool node = false,
  bool mlo = false,
}) =>
    {
      '${_r1}IEEE80211hEnabled': dfs,
      '${_r2}IEEE80211hEnabled': dfs,
      _client: client,
      _node: node,
      _mlo: mlo,
    };

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
  late MockUspWifiAdvancedService svc;

  /// How many times the L1 MLO status was built: once when first read, and
  /// once more after each invalidation that is read again.
  var statusReads = 0;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(const WifiAdvancedSettings.empty());
  });

  /// A container over [device], with MLO offered unless [mloOffered] is false.
  /// [settle] stands in for the 60 s an MLO save waits for the Wi-Fi restart.
  ProviderContainer createContainer(
    _Device device, {
    bool mloOffered = true,
    List<WifiRadioUIModel> radios = const [],
    WifiDataNotifier Function()? wifiNotifier,
    Duration settle = const Duration(milliseconds: 30),
  }) {
    svc = MockUspWifiAdvancedService();
    device.stub(svc);
    statusReads = 0;
    final container = ProviderContainer(
      overrides: [
        uspWifiAdvancedServiceProvider.overrideWithValue(svc),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        deviceCapabilitiesProvider.overrideWithValue(
            DeviceCapabilities({if (mloOffered) DeviceCapability.wifiMlo})),
        wifiDataProvider
            .overrideWith(wifiNotifier ?? () => _StubWifiDataNotifier(radios)),
        // Short timings, so the read-back path runs without real waits.
        wifiAnswerWindowProvider
            .overrideWithValue(const Duration(milliseconds: 50)),
        wifiReadBackIntervalProvider
            .overrideWithValue(const Duration(milliseconds: 10)),
        wifiSaveDeadlineProvider
            .overrideWithValue(const Duration(milliseconds: 200)),
        wifiSaveHardLimitProvider
            .overrideWithValue(const Duration(milliseconds: 400)),
        mloRestartSettleProvider.overrideWithValue(settle),
        // Counts reads of the L1 status, so a test can tell it was invalidated.
        mloStatusProvider.overrideWith((ref) async {
          statusReads++;
          return MloStatus.disabled;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.listen(uspWifiAdvancedProvider, (_, __) {});
    return container;
  }

  Future<UspWifiAdvancedNotifier> loaded(ProviderContainer c) async {
    await Future<void>.delayed(Duration.zero);
    return c.read(uspWifiAdvancedProvider.notifier);
  }

  group('UspWifiAdvancedNotifier - performFetch', () {
    test('reads DFS, steering and MLO from the device', () async {
      final device = _Device({
        ..._bench(client: true, mlo: true),
        '${_r2}IEEE80211hEnabled': true,
      });
      final c = createContainer(device);
      await loaded(c);

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.status.isLoading, isFalse);
      expect(state.status.error, isNull);
      expect(state.settings.current.ieee80211hByRadio, {_r1: false, _r2: true});
      expect(state.settings.current.clientSteering, isTrue);
      expect(state.settings.current.nodeSteering, isFalse);
      expect(state.settings.current.mloEnabled, isTrue);
    });

    test('a device without MLO reads steering and DFS and no MLO', () async {
      // Firmware before FWDEV#201: the two leaves are not in the schema.
      final device = _Device(_bench(node: true));
      final c = createContainer(device, mloOffered: false);
      await loaded(c);

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.status.error, isNull,
          reason: 'steering and DFS must still read (AC 5)');
      expect(state.settings.current.nodeSteering, isTrue);
      expect(state.settings.current.mloEnabled, isNull);
      verifyNever(() => svc.fetchMloEnabled());
    });

    test('a failed read fails the tab', () async {
      final device = _Device(_bench())..failReads = 1;
      final c = createContainer(device);
      await loaded(c);

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.status.error, isA<ServiceError>());
      expect(state.settings.current.ieee80211hByRadio, isEmpty);
    });
  });

  group('UspWifiAdvancedNotifier - editing', () {
    test('each switch edits only itself and marks the tab dirty', () async {
      final c = createContainer(_Device(_bench()));
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      var current = c.read(uspWifiAdvancedProvider).settings.current;
      expect(current.mloEnabled, isTrue);
      expect(current.clientSteering, isFalse);
      expect(current.isDfsEnabled, isFalse);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isTrue);

      notifier.setMloEnabled(false);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isFalse);

      notifier.setClientSteering(true);
      notifier.setNodeSteering(true);
      current = c.read(uspWifiAdvancedProvider).settings.current;
      expect((current.clientSteering, current.nodeSteering), (true, true));
      expect(current.mloEnabled, isFalse);
    });

    test('DFS toggled on then off clears dirty with a mixed original',
        () async {
      final device = _Device({..._bench(), '${_r1}IEEE80211hEnabled': true});
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(true);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isTrue);
      notifier.setDfsEnabled(false);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isFalse,
          reason: 'restores the original per-radio map');
    });

    test('toggling DFS back keeps a pending steering or MLO edit', () async {
      final c = createContainer(_Device(_bench()));
      final notifier = await loaded(c);

      notifier.setNodeSteering(true);
      notifier.setMloEnabled(true);
      notifier.setDfsEnabled(true);
      notifier.setDfsEnabled(false);

      final current = c.read(uspWifiAdvancedProvider).settings.current;
      expect(current.nodeSteering, isTrue);
      expect(current.mloEnabled, isTrue);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isTrue);
    });

    test('revert restores every switch and sends nothing', () async {
      final device = _Device(_bench());
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(true);
      notifier.setMloEnabled(true);
      notifier.revert();

      expect(c.read(uspWifiAdvancedProvider).isDirty, isFalse);
      expect(device.sets, isEmpty);
    });
  });

  group('UspWifiAdvancedNotifier - restartsWifi', () {
    test('true for an MLO or DFS change, false for steering alone', () async {
      final c = createContainer(_Device(_bench()));
      final notifier = await loaded(c);
      bool restarts() => c.read(uspWifiAdvancedProvider).restartsWifi;

      notifier.setClientSteering(true);
      expect(restarts(), isFalse,
          reason: 'steering applies at once, with no Wi-Fi restart');
      notifier.setMloEnabled(true);
      expect(restarts(), isTrue);
      notifier.setMloEnabled(false);
      notifier.setDfsEnabled(true);
      expect(restarts(), isTrue);
    });
  });

  group('UspWifiAdvancedNotifier - one Set for the tab (#1692)', () {
    test('MLO, DFS and steering changed together go out in ONE Set', () async {
      final device = _Device(_bench());
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      notifier.setMloEnabled(true);
      notifier.setDfsEnabled(true);
      await notifier.save();

      expect(device.sets, [
        {
          _client: true,
          _mlo: true,
          '${_r1}IEEE80211hEnabled': true,
          '${_r2}IEEE80211hEnabled': true,
        }
      ]);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isFalse);
    });

    test('a steering-only save writes the one leaf and nothing else', () async {
      final device = _Device(_bench());
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setNodeSteering(true);
      await notifier.save();

      expect(device.sets, [
        {_node: true}
      ]);
    });

    test('a device without MLO never has the leaf written', () async {
      final device = _Device(_bench());
      final c = createContainer(device, mloOffered: false);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      notifier.setDfsEnabled(true);
      await notifier.save();

      expect(device.sets.single.keys, isNot(contains(_mlo)));
      expect(device.sets.single.keys, hasLength(3));
    });

    test('a part refused inside the Set is a failed save, not "saved"',
        () async {
      // MLO refused (fault 9001: not the mesh controller) while DFS lands.
      final device = _Device(_bench())..refuse = {_mlo};
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      notifier.setDfsEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.settings.current.mloEnabled, isFalse,
          reason: 'the switch shows what the device holds');
      expect(state.settings.current.isDfsEnabled, isTrue,
          reason: 'the part that landed is shown as landed');
      expect(state.isDirty, isFalse,
          reason: 'the form is the device, so a retry starts from the truth');
      expect(state.status.isSaving, isFalse);
    });

    test('a Set the device answers "yes" to but reads back old fails',
        () async {
      // allowPartial can report success for a part that did not apply.
      final device = _Device(_bench())..sticky = {_mlo};
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));
      expect(
          c.read(uspWifiAdvancedProvider).settings.current.mloEnabled, isFalse);
    });

    test('a refused Set leaves the form at the device, then rethrows',
        () async {
      final device = _Device(_bench())..refuse = {_client, _node};
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      notifier.setNodeSteering(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.settings.current.clientSteering, isFalse);
      expect(state.isDirty, isFalse);
    });

    test('a refused save whose re-read fails keeps the edit pending', () async {
      final device = _Device(_bench())..refuse = {_client};
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      device.failReads = 100;
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.settings.current.clientSteering, isTrue);
      expect(state.isDirty, isTrue);
    });

    test('isSaving is set during the save and cleared after', () async {
      final device = _Device(_bench())..holdSet = Completer<void>();
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      final saving = notifier.save();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(uspWifiAdvancedProvider).status.isSaving, isTrue);
      device.holdSet!.complete();
      await saving;
      expect(c.read(uspWifiAdvancedProvider).status.isSaving, isFalse);
    });
  });

  group('UspWifiAdvancedNotifier - a restart is waited out', () {
    test('an MLO save is not over before the restart settle time', () async {
      // Bench 2026-10-15: the MLO Set was answered in 166 ms. FW's contract:
      // Wi-Fi restarts for about 60 s after a change; read MLOStatus after.
      final device = _Device(_bench());
      final c =
          createContainer(device, settle: const Duration(milliseconds: 300));
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      final sw = Stopwatch()..start();
      var done = false;
      final saving = notifier.save().then((_) => done = true);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(done, isFalse);
      await saving;
      expect(
          sw.elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 300)));
    });

    test('a landed MLO save reads the switch back as saved', () async {
      final device = _Device(_bench());
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      await notifier.save();

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.settings.current.mloEnabled, isTrue);
      expect(state.isDirty, isFalse);
      verify(() => svc.isApplied({_mlo: true})).called(greaterThan(0));
    });

    test('a steering-only save does not wait for a restart', () async {
      final device = _Device(_bench());
      final c = createContainer(device, settle: const Duration(seconds: 30));
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      await notifier.save().timeout(const Duration(seconds: 5));
    });

    test('a lost reply is read back before it is reported', () async {
      final device = _Device(_bench())..holdSet = Completer<void>();
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(true);
      final saving = notifier.save();
      // The values land while the reply never comes, as in #1460.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      device.values['${_r1}IEEE80211hEnabled'] = true;
      device.values['${_r2}IEEE80211hEnabled'] = true;

      await expectLater(saving, completes);
    });

    test('a write the device never reads back fails the save', () async {
      final device = _Device(_bench())..holdSet = Completer<void>();
      final c = createContainer(device);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));
    });

    test('a confirmed save is not failed by the L1 refresh after it', () async {
      // The 15 s throttler while the radios reload (#1499).
      final l1 = _FailAfterFirstBuild();
      final device = _Device(_bench());
      final c = createContainer(device, wifiNotifier: () => l1);
      final notifier = await loaded(c);
      notifier.setDfsEnabled(true);
      l1.fail = true;

      await expectLater(notifier.save(), completes);
      expect(l1.failures, greaterThan(0),
          reason: 'the refresh must actually have failed');
    });
  });

  group('UspWifiAdvancedNotifier - the MLO status is read again (#1692)', () {
    // The badge's status is L1's. Nothing pushes it, so every write on this
    // tab invalidates it once settled, as the repo's L2 notifiers do for
    // wifiDataProvider — on success and on failure alike.
    Future<void> watchStatus(ProviderContainer c) async {
      c.listen(mloStatusProvider, (_, __) {});
      await c.read(mloStatusProvider.future);
    }

    test('after a save', () async {
      final device = _Device(_bench());
      final c = createContainer(device);
      final notifier = await loaded(c);
      await watchStatus(c);
      expect(statusReads, 1);

      notifier.setMloEnabled(true);
      await notifier.save();
      await c.read(mloStatusProvider.future);

      expect(statusReads, 2);
    });

    test('after a failed save', () async {
      final device = _Device(_bench())..refuse = {_mlo};
      final c = createContainer(device);
      final notifier = await loaded(c);
      await watchStatus(c);

      notifier.setMloEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));
      await c.read(mloStatusProvider.future);

      expect(statusReads, 2,
          reason: 'a refused part may still have changed what the router '
              'reports');
    });

    test('after a refresh, which also clears a failed read', () async {
      final device = _Device(_bench());
      final c = createContainer(device);
      final notifier = await loaded(c);
      await watchStatus(c);

      await notifier.refresh();
      await c.read(mloStatusProvider.future);

      expect(statusReads, 2);
    });
  });

  group('UspWifiAdvancedNotifier - DFS remediation', () {
    test(
        'disabling DFS forces AutoChannelEnable on a radio parked on a DFS '
        'channel, in the same Set', () async {
      final device = _Device(_bench(dfs: true));
      final c = createContainer(device, radios: [
        // 2.4 GHz on ch 6: never DFS, never forced.
        _radioModel(
            instancePath: _r1,
            band: '2.4GHz',
            channel: 6,
            autoChannelEnable: false),
        // 5 GHz parked on DFS ch 100: forced to auto.
        _radioModel(
            instancePath: _r2,
            band: '5GHz',
            channel: 100,
            autoChannelEnable: false),
      ]);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await notifier.save();

      expect(device.sets.single, {
        '${_r1}IEEE80211hEnabled': false,
        '${_r2}IEEE80211hEnabled': false,
        '${_r2}AutoChannelEnable': true,
      });
    });

    test('a 5 GHz radio on a non-DFS channel or on auto is not forced',
        () async {
      final device = _Device(_bench(dfs: true));
      final c = createContainer(device, radios: [
        _radioModel(
            instancePath: _r1,
            band: '5GHz',
            channel: 36,
            autoChannelEnable: false),
        _radioModel(
            instancePath: _r2,
            band: '5GHz',
            channel: 100,
            autoChannelEnable: true),
      ]);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await notifier.save();

      expect(
          device.sets.single.keys.where((k) => k.endsWith('AutoChannelEnable')),
          isEmpty);
    });

    test('an MLO-only save forces nothing, even with a radio parked on DFS',
        () async {
      // DFS stays on, so the parked radio is legal where it is.
      final device = _Device(_bench(dfs: true));
      final c = createContainer(device, radios: [
        _radioModel(
            instancePath: _r2,
            band: '5GHz',
            channel: 100,
            autoChannelEnable: false),
      ]);
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      await notifier.save();

      expect(device.sets.single, {_mlo: true});
    });
  });

  // -------------------------------------------------------------------------
  // linksys/PrivacyGUI#1587 Phase 1 — the two contracts the deletion created.
  //
  // Phase 1 removed `onSseInvalidation()` and, with it, the `ref.listen` that
  // this notifier's DFS remediation had been relying on WITHOUT SAYING SO.
  // -------------------------------------------------------------------------
  group('UspWifiAdvancedNotifier - #1587 Phase 1 contracts', () {
    final parked = [
      _radioModel(
          instancePath: _r1,
          band: '5GHz',
          channel: 52,
          autoChannelEnable: false),
    ];

    test('DFS remediation reads L1 by value, not by an incidental subscription',
        () async {
      // The container subscribes to L2 but NEVER to `wifiDataProvider`, so L1
      // is cold when the save reaches it — the production shape.
      final device = _Device({'${_r1}IEEE80211hEnabled': true, ..._mesh()});
      final c = createContainer(device, radios: parked);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await notifier.save();

      expect(device.sets.single['${_r1}AutoChannelEnable'], isTrue,
          reason: 'the radio on DFS channel 52 must be forced to auto-channel');
    });

    test('the retry catches an error L1 is not documented to throw', () async {
      // Not a ServiceError, so `on ServiceError` would let it through.
      final device = _Device({'${_r1}IEEE80211hEnabled': true, ..._mesh()});
      final c = createContainer(device,
          wifiNotifier: () => _FlakyWifiDataNotifier(
                onBuild: () {},
                firstError: StateError('codegen blew up'),
                radios: parked,
              ));
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await notifier.save();

      expect(device.sets.single['${_r1}AutoChannelEnable'], isTrue);
    });

    test('L1 failing twice fails the save before anything is sent', () async {
      // The remediation cannot be skipped silently; and a save that sent
      // nothing has nothing to re-read, so the edit stays pending.
      final device = _Device({'${_r1}IEEE80211hEnabled': true, ..._mesh()});
      final c = createContainer(device, wifiNotifier: _AlwaysFailingL1.new);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(device.sets, isEmpty);
      expect(c.read(uspWifiAdvancedProvider).settings.current.isDfsEnabled,
          isFalse);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isTrue);
    });

    test('a cached L1 failure is retried once rather than failing the save',
        () async {
      var builds = 0;
      final device = _Device({'${_r1}IEEE80211hEnabled': true, ..._mesh()});
      final c = createContainer(device,
          wifiNotifier: () => _FlakyWifiDataNotifier(
                onBuild: () => builds++,
                radios: parked,
              ));
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await notifier.save();

      expect(builds, greaterThanOrEqualTo(2),
          reason: 'the failed L1 read must be retried, not replayed');
      expect(device.sets.single['${_r1}AutoChannelEnable'], isTrue);
    });
  });
}

/// The mesh leaves with every switch off.
Map<String, bool> _mesh() => {_client: false, _node: false, _mlo: false};

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

  /// A parameter rather than a fixed `ServiceError`, because the retry
  /// deliberately catches everything: a test that only throws a `ServiceError`
  /// subclass cannot tell `catch (e)` from `on ServiceError`.
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

/// L1 that never builds — the remediation's read and its one retry both fail.
class _AlwaysFailingL1 extends WifiDataNotifier {
  @override
  Future<WifiData> build() async =>
      throw const NetworkError(detail: 'L1 unreachable');
}
