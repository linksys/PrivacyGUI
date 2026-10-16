import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';

const _mlo = 'Device.X_LINKSYS_Mesh.MLOEnabled';
const _mloStatus = 'Device.X_LINKSYS_Mesh.MLOStatus';
const _client = 'Device.X_LINKSYS_Mesh.ClientSteeringEnabled';
const _node = 'Device.X_LINKSYS_Mesh.NodeSteeringEnabled';
const _r1 = 'Device.WiFi.Radio.1.';
const _r2 = 'Device.WiFi.Radio.2.';

/// A router: a value store the real [UspWifiAdvancedService] reads and writes.
///
/// The notifier runs against the real service, so what these tests pin is the
/// one Set that goes out and what the router reads back — not which service
/// method was called. A Set applies its params unless [refuse] names one, which
/// the router then reports as refused and leaves at its old value — what
/// `allowPartial: true` does on FLWRT 2.0.
class _Router extends Fake implements UspClient {
  _Router(this.values);

  final Map<String, Object?> values;
  final sets = <Map<String, dynamic>>[];
  final setsAllowPartial = <bool>[];
  Set<String> refuse = {};

  /// Read failures to answer before reading normally again.
  int failReads = 0;

  /// When set, the next Set waits on it — a reply lost to the Wi-Fi restart.
  Completer<void>? holdSet;

  @override
  Future<Map<String, dynamic>> get(List<String> paths,
      {RequestPriority? priority, bool fresh = false}) async {
    if (failReads > 0) {
      failReads--;
      throw 'Get failed: Transport error: Failed to fetch';
    }
    final out = <String, dynamic>{};
    for (final p in paths) {
      if (p == 'Device.WiFi.Radio.*.IEEE80211hEnabled') {
        for (final e in values.entries) {
          if (e.key.startsWith('Device.WiFi.Radio.') &&
              e.key.endsWith('.IEEE80211hEnabled')) {
            out[e.key] = e.value;
          }
        }
      } else if (values.containsKey(p)) {
        out[p] = values[p];
      }
    }
    return out;
  }

  @override
  Future<Map<String, dynamic>> set(Object pathOrParams,
      {dynamic singleValue, bool allowPartial = false}) async {
    final params = Map<String, dynamic>.from(pathOrParams as Map);
    sets.add(params);
    setsAllowPartial.add(allowPartial);
    final hold = holdSet;
    if (hold != null) await hold.future;
    final errors = <String, dynamic>{};
    for (final e in params.entries) {
      if (refuse.contains(e.key)) {
        errors[e.key] = {'errorCode': 9001, 'errorMessage': 'Request denied'};
      } else {
        values[e.key] =
            e.value == true ? '1' : (e.value == false ? '0' : e.value);
      }
    }
    return {
      'success': errors.length < params.length,
      'result': {
        'data': {
          for (final k in params.keys)
            if (!errors.containsKey(k)) k: values[k]
        },
        if (errors.isNotEmpty) 'error': errors,
      },
    };
  }
}

/// What FW 2.0.3.26101472 read on the bench on 2026-10-15, both main radios.
Map<String, Object?> _bench({
  bool dfs = false,
  bool client = false,
  bool node = false,
  bool? mlo = false,
  String mloStatus = 'Disabled',
}) =>
    {
      '${_r1}IEEE80211hEnabled': dfs ? '1' : '0',
      '${_r2}IEEE80211hEnabled': dfs ? '1' : '0',
      _client: client ? '1' : '0',
      _node: node ? '1' : '0',
      if (mlo != null) _mlo: mlo ? '1' : '0',
      if (mlo != null) _mloStatus: mloStatus,
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
  /// A container over [router], with MLO offered unless [mloOffered] is false.
  /// [settle] stands in for the 60 s an MLO save waits for the Wi-Fi restart.
  ProviderContainer createContainer(
    _Router router, {
    bool mloOffered = true,
    List<WifiRadioUIModel> radios = const [],
    WifiDataNotifier Function()? wifiNotifier,
    Duration settle = const Duration(milliseconds: 30),
  }) {
    final container = ProviderContainer(
      overrides: [
        uspWifiAdvancedServiceProvider
            .overrideWithValue(UspWifiAdvancedService(router)),
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

  group('fetch', () {
    test('reads DFS, steering and MLO from the router', () async {
      final router = _Router({
        ..._bench(client: true, mlo: true, mloStatus: 'Inactive'),
        '${_r2}IEEE80211hEnabled': '1',
      });
      final c = createContainer(router);
      await loaded(c);

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.status.isLoading, isFalse);
      expect(state.status.error, isNull);
      expect(state.settings.current.ieee80211hByRadio, {_r1: false, _r2: true});
      expect(state.settings.current.clientSteering, isTrue);
      expect(state.settings.current.nodeSteering, isFalse);
      expect(state.settings.current.mloEnabled, isTrue);
      expect(state.status.mloStatus, MloStatus.inactive);
    });

    test('a router without MLO reads steering and DFS and no MLO', () async {
      // Firmware before FWDEV#201: the two leaves are not in the schema.
      final router = _Router(_bench(node: true, mlo: null));
      final c = createContainer(router, mloOffered: false);
      await loaded(c);

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.status.error, isNull,
          reason: 'steering and DFS must still read (AC 5)');
      expect(state.settings.current.nodeSteering, isTrue);
      expect(state.settings.current.mloEnabled, isNull);
      expect(state.status.mloStatus, isNull);
    });

    test('a failed read fails the tab', () async {
      final router = _Router(_bench())..failReads = 1;
      final c = createContainer(router);
      await loaded(c);

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.status.error, isA<ServiceError>());
      expect(state.settings.current.ieee80211hByRadio, isEmpty);
    });

    test('an offered MLO with a leaf missing fails the tab, not "off"',
        () async {
      final router = _Router(_bench())..values.remove(_mloStatus);
      final c = createContainer(router);
      await loaded(c);

      expect(c.read(uspWifiAdvancedProvider).status.error, isA<ServiceError>());
    });
  });

  group('editing', () {
    test('each switch edits only itself and marks the tab dirty', () async {
      final c = createContainer(_Router(_bench()));
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
      final router = _Router({..._bench(), '${_r1}IEEE80211hEnabled': '1'});
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(true);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isTrue);
      notifier.setDfsEnabled(false);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isFalse,
          reason: 'restores the original per-radio map');
    });

    test('toggling DFS back keeps a pending steering or MLO edit', () async {
      final c = createContainer(_Router(_bench()));
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
      final router = _Router(_bench());
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(true);
      notifier.setMloEnabled(true);
      notifier.revert();

      expect(c.read(uspWifiAdvancedProvider).isDirty, isFalse);
      expect(router.sets, isEmpty);
    });
  });

  group('restartsWifi', () {
    test('true for an MLO or DFS change, false for steering alone', () async {
      final c = createContainer(_Router(_bench()));
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

  group('save — one Set for the tab (#1692)', () {
    test('MLO, DFS and steering changed together go out in ONE Set', () async {
      final router = _Router(_bench());
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      notifier.setMloEnabled(true);
      notifier.setDfsEnabled(true);
      await notifier.save();

      expect(router.sets, [
        {
          _client: true,
          _mlo: true,
          '${_r1}IEEE80211hEnabled': true,
          '${_r2}IEEE80211hEnabled': true,
        }
      ]);
      expect(router.setsAllowPartial, [true],
          reason: 'dm-reflector and wifidmd are two USP services; an atomic '
              'Set across them is refused with 7005');
      expect(c.read(uspWifiAdvancedProvider).isDirty, isFalse);
    });

    test('a steering-only save writes the one leaf and nothing else', () async {
      final router = _Router(_bench());
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setNodeSteering(true);
      await notifier.save();

      expect(router.sets, [
        {_node: true}
      ]);
    });

    test('a router without MLO never has the leaf written', () async {
      final router = _Router(_bench(mlo: null));
      final c = createContainer(router, mloOffered: false);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      notifier.setDfsEnabled(true);
      await notifier.save();

      expect(router.sets.single.keys, isNot(contains(_mlo)));
      expect(router.sets.single.keys, hasLength(3));
    });

    test('a part refused inside the Set is a failed save, not "saved"',
        () async {
      // MLO refused (fault 9001: not the mesh controller) while DFS lands.
      final router = _Router(_bench())..refuse = {_mlo};
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      notifier.setDfsEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.settings.current.mloEnabled, isFalse,
          reason: 'the switch shows what the router holds');
      expect(state.settings.current.isDfsEnabled, isTrue,
          reason: 'the part that landed is shown as landed');
      expect(state.isDirty, isFalse,
          reason: 'the form is the router, so a retry starts from the truth');
      expect(state.status.isSaving, isFalse);
    });

    test('a Set the router answers "yes" to but reads back old fails',
        () async {
      // allowPartial can report success for a part that did not apply.
      final router = _StickyRouter(_bench(), sticky: {_mlo});
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));
      expect(
          c.read(uspWifiAdvancedProvider).settings.current.mloEnabled, isFalse);
    });

    test('a refused Set leaves the form at the router, then rethrows',
        () async {
      final router = _Router(_bench())..refuse = {_client, _node};
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      notifier.setNodeSteering(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.settings.current.clientSteering, isFalse);
      expect(state.isDirty, isFalse);
    });

    test('a refused save whose re-read fails keeps the edit pending', () async {
      final router = _Router(_bench())..refuse = {_client};
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      router.failReads = 100;
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.settings.current.clientSteering, isTrue);
      expect(state.isDirty, isTrue);
    });

    test('isSaving is set during the save and cleared after', () async {
      final router = _Router(_bench())..holdSet = Completer<void>();
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      final saving = notifier.save();
      await Future<void>.delayed(Duration.zero);
      expect(c.read(uspWifiAdvancedProvider).status.isSaving, isTrue);
      router.holdSet!.complete();
      await saving;
      expect(c.read(uspWifiAdvancedProvider).status.isSaving, isFalse);
    });
  });

  group('save — a restart is waited out', () {
    test('an MLO save is not over before the restart settle time', () async {
      // Bench 2026-10-15: the MLO Set was answered in 166 ms. FW: Wi-Fi
      // restarts for about 60 s after a change; read MLOStatus after that.
      final router = _Router(_bench());
      final c =
          createContainer(router, settle: const Duration(milliseconds: 300));
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

    test('the status is read again after the restart', () async {
      final router = _Router(_bench());
      final c = createContainer(router);
      final notifier = await loaded(c);
      // On WPA2 bands the switch turns on but MLO cannot run (bench).
      notifier.setMloEnabled(true);
      router.values[_mloStatus] = 'Inactive';

      await notifier.save();

      final state = c.read(uspWifiAdvancedProvider);
      expect(state.settings.current.mloEnabled, isTrue);
      expect(state.status.mloStatus, MloStatus.inactive);
    });

    test('a steering-only save does not wait for a restart', () async {
      final router = _Router(_bench());
      final c = createContainer(router, settle: const Duration(seconds: 30));
      final notifier = await loaded(c);

      notifier.setClientSteering(true);
      await notifier.save().timeout(const Duration(seconds: 5));
    });

    test('a lost reply is read back before it is reported', () async {
      final router = _Router(_bench())..holdSet = Completer<void>();
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(true);
      final saving = notifier.save();
      // The values land while the reply never comes, as in #1460.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      router.values['${_r1}IEEE80211hEnabled'] = '1';
      router.values['${_r2}IEEE80211hEnabled'] = '1';

      await expectLater(saving, completes);
    });

    test('a write the router never reads back fails the save', () async {
      final router = _Router(_bench())..holdSet = Completer<void>();
      final c = createContainer(router);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(true);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));
    });

    test('a confirmed save is not failed by the L1 refresh after it', () async {
      // The 15 s throttler while the radios reload (#1499).
      final l1 = _FailAfterFirstBuild();
      final router = _Router(_bench());
      final c = createContainer(router, wifiNotifier: () => l1);
      final notifier = await loaded(c);
      notifier.setDfsEnabled(true);
      l1.fail = true;

      await expectLater(notifier.save(), completes);
      expect(l1.failures, greaterThan(0),
          reason: 'the refresh must actually have failed');
    });
  });

  group('DFS remediation', () {
    test(
        'disabling DFS forces AutoChannelEnable on a radio parked on a DFS '
        'channel, in the same Set', () async {
      final router = _Router(_bench(dfs: true));
      final c = createContainer(router, radios: [
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

      expect(router.sets.single, {
        '${_r1}IEEE80211hEnabled': false,
        '${_r2}IEEE80211hEnabled': false,
        '${_r2}AutoChannelEnable': true,
      });
    });

    test('a 5 GHz radio on a non-DFS channel or on auto is not forced',
        () async {
      final router = _Router(_bench(dfs: true));
      final c = createContainer(router, radios: [
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
          router.sets.single.keys.where((k) => k.endsWith('AutoChannelEnable')),
          isEmpty);
    });

    test('an MLO-only save forces nothing, even with a radio parked on DFS',
        () async {
      // DFS stays on, so the parked radio is legal where it is.
      final router = _Router(_bench(dfs: true));
      final c = createContainer(router, radios: [
        _radioModel(
            instancePath: _r2,
            band: '5GHz',
            channel: 100,
            autoChannelEnable: false),
      ]);
      final notifier = await loaded(c);

      notifier.setMloEnabled(true);
      await notifier.save();

      expect(router.sets.single, {_mlo: true});
    });
  });

  // -------------------------------------------------------------------------
  // linksys/PrivacyGUI#1587 Phase 1 — the two contracts the deletion created.
  //
  // Phase 1 removed `onSseInvalidation()` and, with it, the `ref.listen` that
  // this notifier's DFS remediation had been relying on WITHOUT SAYING SO.
  // -------------------------------------------------------------------------
  group('#1587 Phase 1 contracts', () {
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
      final router = _Router({'${_r1}IEEE80211hEnabled': '1', ..._mesh()});
      final c = createContainer(router, radios: parked);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await notifier.save();

      expect(router.sets.single['${_r1}AutoChannelEnable'], isTrue,
          reason: 'the radio on DFS channel 52 must be forced to auto-channel');
    });

    test('the retry catches an error L1 is not documented to throw', () async {
      // Not a ServiceError, so `on ServiceError` would let it through.
      final router = _Router({'${_r1}IEEE80211hEnabled': '1', ..._mesh()});
      final c = createContainer(router,
          wifiNotifier: () => _FlakyWifiDataNotifier(
                onBuild: () {},
                firstError: StateError('codegen blew up'),
                radios: parked,
              ));
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await notifier.save();

      expect(router.sets.single['${_r1}AutoChannelEnable'], isTrue);
    });

    test('L1 failing twice fails the save before anything is sent', () async {
      // The remediation cannot be skipped silently; and a save that sent
      // nothing has nothing to re-read, so the edit stays pending.
      final router = _Router({'${_r1}IEEE80211hEnabled': '1', ..._mesh()});
      final c = createContainer(router, wifiNotifier: _AlwaysFailingL1.new);
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(router.sets, isEmpty);
      expect(c.read(uspWifiAdvancedProvider).settings.current.isDfsEnabled,
          isFalse);
      expect(c.read(uspWifiAdvancedProvider).isDirty, isTrue);
    });

    test('a cached L1 failure is retried once rather than failing the save',
        () async {
      var builds = 0;
      final router = _Router({'${_r1}IEEE80211hEnabled': '1', ..._mesh()});
      final c = createContainer(router,
          wifiNotifier: () => _FlakyWifiDataNotifier(
                onBuild: () => builds++,
                radios: parked,
              ));
      final notifier = await loaded(c);

      notifier.setDfsEnabled(false);
      await notifier.save();

      expect(builds, greaterThanOrEqualTo(2),
          reason: 'the failed L1 read must be retried, not replayed');
      expect(router.sets.single['${_r1}AutoChannelEnable'], isTrue);
    });
  });
}

/// The mesh leaves with every switch off.
Map<String, Object?> _mesh() => {
      _client: '0',
      _node: '0',
      _mlo: '0',
      _mloStatus: 'Disabled',
    };

/// A router that answers "applied" for [sticky] leaves and keeps their old
/// value: a Set reported as a success that did not change everything.
class _StickyRouter extends _Router {
  _StickyRouter(super.values, {required this.sticky});
  final Set<String> sticky;

  @override
  Future<Map<String, dynamic>> set(Object pathOrParams,
      {dynamic singleValue, bool allowPartial = false}) async {
    final before = {for (final k in sticky) k: values[k]};
    final result = await super.set(pathOrParams,
        singleValue: singleValue, allowPartial: allowPartial);
    values.addAll(before);
    return result;
  }
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
