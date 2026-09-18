import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_ethernet_data_service.dart';

import '../../../mocks/test_data/devices_test_data.dart';

class MockUspEthernetDataService extends Mock
    implements UspEthernetDataService {}

void main() {
  late MockUspEthernetDataService mockEthernetSvc;

  final samplePortModels = [
    EthernetPortUIModel(
      name: 'eth0',
      label: 'WAN',
      isWan: true,
      isUp: true,
      instancePath: 'Device.Ethernet.Interface.2.',
      currentBitRate: 1000,
    ),
    EthernetPortUIModel(
      name: 'eth1',
      label: 'LAN',
      isWan: false,
      isUp: true,
      instancePath: 'Device.Ethernet.Interface.1.',
      currentBitRate: 1000,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(<ClientDevice>[]);
  });

  setUp(() {
    mockEthernetSvc = MockUspEthernetDataService();

    when(() => mockEthernetSvc.fetch(
          deviceModels: any(named: 'deviceModels'),
        )).thenAnswer(
      (_) async => EthernetDataFetchResult(portModels: samplePortModels),
    );
  });

  ProviderContainer createContainer({
    DevicesData? devicesData,
    Stream<InvalidationEvent>? sse,
  }) {
    return ProviderContainer(
      overrides: [
        uspEthernetDataServiceProvider.overrideWithValue(mockEthernetSvc),
        devicesDataProvider.overrideWith(
          () => _TestDevicesDataNotifier(devicesData ?? _emptyDevicesData()),
        ),
        if (sse != null) sseInvalidationProvider.overrideWith((_) => sse),
      ],
    );
  }

  group('EthernetDataNotifier', () {
    test('build fetches via service and returns port models', () async {
      final container = createContainer();
      final data = await container.read(ethernetDataProvider.future);

      expect(data.ethernetPortModels, hasLength(2));
      expect(data.ethernetPortModels[0].label, 'WAN');
      expect(data.ethernetPortModels[1].label, 'LAN');
      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);
      container.dispose();
    });

    test('build throws when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(null),
          devicesDataProvider.overrideWith(
            () => _TestDevicesDataNotifier(_emptyDevicesData()),
          ),
        ],
      );

      expect(
        container.read(ethernetDataProvider.future),
        throwsA(isA<ServiceNotInitializedError>()),
      );
      container.dispose();
    });

    test('EthernetData copyWith works', () {
      const data = EthernetData();
      expect(data.ethernetPortModels, isEmpty);

      final same = data.copyWith();
      expect(same, equals(data));
    });

    test('EthernetData props uses list for equality', () {
      const a = EthernetData();
      const b = EthernetData();
      expect(a, equals(b));

      final port = EthernetPortUIModel(
        name: 'eth1',
        label: 'LAN',
        isWan: false,
        isUp: true,
        instancePath: 'p',
        currentBitRate: 100,
      );
      final c = EthernetData(ethernetPortModels: [port]);
      expect(a, isNot(equals(c)));
    });
  });

  // ---------------------------------------------------------------------------
  // The devicesDataProvider listener re-fetches only when the input it actually
  // consumes changed.
  //
  // `_fetch()` passes exactly `clientDevices` to the service, but DevicesData
  // emits on any device field (RSSI, band, SSID), and devicesDataProvider
  // assigns state directly rather than invalidating — so before #1502 every
  // unrelated device update cost one Ethernet USP fetch. Causes that are not the
  // device list arrive via the sseInvalidationProvider listener instead.
  // ---------------------------------------------------------------------------
  group('EthernetDataNotifier — devices listener', () {
    /// Builds a container whose devices provider can emit further states.
    (ProviderContainer, _PushableDevicesDataNotifier) pushableContainer(
      DevicesData initial,
    ) {
      final notifier = _PushableDevicesDataNotifier(initial);
      final container = ProviderContainer(
        overrides: [
          uspEthernetDataServiceProvider.overrideWithValue(mockEthernetSvc),
          devicesDataProvider.overrideWith(() => notifier),
        ],
      );
      return (container, notifier);
    }

    test('does not re-fetch when clientDevices is unchanged', () async {
      final client = DevicesTestData.createWiredClient();
      final (container, notifier) = pushableContainer(_devicesWith([client]));
      addTearDown(container.dispose);

      // Settle devices *before* Ethernet is touched at all, so its _fetch()
      // consumes the real list and the boot baseline is 1. This has to come
      // before the container.listen below, which itself initialises the
      // provider; otherwise the boot race applies, the baseline is 2, and it
      // muddles the one thing this test is about: whether a later equal-valued
      // emission re-fetches. That race has its own tests further down.
      await container.read(devicesDataProvider.future);

      // A permanent subscription is required: invalidateSelf() on a provider
      // with no listeners only marks it dirty, and the rebuild is deferred to
      // the next read — so without this, the unguarded version would look
      // identical to the guarded one here.
      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);
      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);

      // A fresh DevicesData carrying an equal client list. ClientDevice has
      // value equality (NetworkEntity with EquatableMixin), so this is the
      // "device changed in a way Ethernet does not read" case.
      notifier.emit(_devicesWith([DevicesTestData.createWiredClient()]));
      await Future.delayed(Duration.zero);

      verifyNever(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          ));
    });

    // The orchestrator triggers devices and ethernet back to back
    // (dashboard_orchestrator.dart:158-159), so at boot this provider's own
    // _fetch() usually reads devicesDataProvider as AsyncLoading and passes an
    // empty list. When the device list then settles *also* empty, the input has
    // not changed and there is nothing to re-fetch — but `prev` carries no
    // value, and `ListEquality.equals(null, [])` is `false`, so without the
    // `?? const []` in the guard the boot settle spends a second USP round-trip
    // on the identical input.
    test('a boot settle with no clients does not cost a second fetch',
        () async {
      final notifier = _SlowDevicesDataNotifier(_devicesWith([]));
      final container = ProviderContainer(overrides: [
        uspEthernetDataServiceProvider.overrideWithValue(mockEthernetSvc),
        devicesDataProvider.overrideWith(() => notifier),
      ]);
      addTearDown(container.dispose);

      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);
      // Let devicesData settle after this provider already holds data.
      await Future.delayed(const Duration(milliseconds: 30));

      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);
    });

    // The same race, but the device list settles non-empty: the first fetch
    // consumed [], so the second one is required, not redundant.
    test('a boot settle that adds clients does re-fetch', () async {
      final notifier = _SlowDevicesDataNotifier(
          _devicesWith([DevicesTestData.createWiredClient()]));
      final container = ProviderContainer(overrides: [
        uspEthernetDataServiceProvider.overrideWithValue(mockEthernetSvc),
        devicesDataProvider.overrideWith(() => notifier),
      ]);
      addTearDown(container.dispose);

      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);
      await Future.delayed(const Duration(milliseconds: 30));

      final captured = verify(() => mockEthernetSvc.fetch(
            deviceModels: captureAny(named: 'deviceModels'),
          )).captured;
      expect(captured, hasLength(2));
      expect(captured[0], isEmpty);
      expect(captured[1], hasLength(1));
    });

    // The other half of the same race. When devicesData settles *while* this
    // provider's own _fetch() is still in flight, the settle must not be lost:
    // the fetch it would have corrected has already consumed [], so dropping it
    // leaves Ethernet serving port models built from an empty device list until
    // the list changes again or an `ethernetInterfaces` SSE event arrives.
    //
    // A `state.hasValue` guard dropped it. On riverpod 2.6.1 that was masked —
    // the next redundant devicesData emission re-invalidated and the staleness
    // healed itself — but a payload diff (and, later, riverpod 3's `==`
    // unification) removes exactly that accidental rescue, which is why the
    // comparison is against the *consumed* input rather than the previous
    // notification.
    test('a settle arriving mid-fetch is not lost', () async {
      final consumed = <int>[];
      when(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).thenAnswer((inv) async {
        consumed.add(
          (inv.namedArguments[const Symbol('deviceModels')] as List).length,
        );
        // Deliberately outlives _SlowDevicesDataNotifier's 10 ms settle.
        await Future.delayed(const Duration(milliseconds: 20));
        return EthernetDataFetchResult(portModels: samplePortModels);
      });

      final notifier = _SlowDevicesDataNotifier(
          _devicesWith([DevicesTestData.createWiredClient()]));
      final container = ProviderContainer(overrides: [
        uspEthernetDataServiceProvider.overrideWithValue(mockEthernetSvc),
        devicesDataProvider.overrideWith(() => notifier),
      ]);
      addTearDown(container.dispose);

      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);
      await Future.delayed(const Duration(milliseconds: 60));

      // Not `[0]`: the mid-fetch settle is honoured, so a second fetch consumes
      // the real list. And not `[0, 1, 1]`: it is honoured exactly once.
      expect(consumed, [0, 1]);
    });

    test('re-fetches when clientDevices changes', () async {
      final (container, notifier) = pushableContainer(_devicesWith([]));
      addTearDown(container.dispose);

      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);
      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);

      notifier.emit(_devicesWith([DevicesTestData.createWiredClient()]));
      await Future.delayed(Duration.zero);

      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(1);
    });
  });

  // -------------------------------------------------------------------------
  // SSE invalidation (#1501)
  //
  // `sseInvalidationProvider` emits `({InvalidationDomain domain, int seq})`.
  // This notifier reads `.domain` and ignores `seq`, whose only job is to keep
  // two consecutive events for the *same* domain unequal — without it,
  // riverpod 3.x's `==`-based `updateShouldNotify` collapses the second one and
  // the repeat below stops re-fetching. So the repeat is the assertion that
  // pins the tag end-to-end at the consumer, not just at the producer.
  //
  // Every test here keeps a standing `container.listen`: `invalidateSelf()` is
  // lazy on a provider with no active listeners — it only marks it dirty and
  // defers the rebuild to the next read — so without one, a "did it re-fetch"
  // assertion passes against a broken listener too.
  // -------------------------------------------------------------------------
  group('EthernetDataNotifier SSE invalidation', () {
    /// Drains enough microtasks for an SSE event to travel
    /// stream -> provider state -> `ref.listen` -> `invalidateSelf()` ->
    /// rebuild -> `_fetch()`. A single `Duration.zero` is not enough here (it is
    /// for the notifiers that call `fetch()` directly), and awaiting
    /// `provider.future` instead does NOT work: it resolves against the future
    /// that is already complete, before the event has propagated at all.
    ///
    /// Both tests below drain the same amount so the negative one cannot pass
    /// merely by looking earlier than the positive one.
    ///
    /// Measured: 2 hops is the minimum that passes here, 1 fails. 4 is
    /// deliberate margin — an extra hop on a chain that has already settled is
    /// free, whereas one too few reads as "the listener is broken".
    Future<void> settle() async {
      for (var i = 0; i < 4; i++) {
        await Future.delayed(Duration.zero);
      }
    }

    void verifyFetches(int count) {
      verify(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          )).called(count);
    }

    test('ethernetInterfaces domain re-fetches, and a repeat re-fetches again',
        () async {
      final sse = StreamController<InvalidationEvent>();
      final container = createContainer(sse: sse.stream);
      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);

      // Drop the build() fetch so the counting below starts from zero.
      verifyFetches(1);
      clearInteractions(mockEthernetSvc);

      sse.add((domain: InvalidationDomain.ethernetInterfaces, seq: 0));
      await settle();
      verifyFetches(1);

      // Same domain again — e.g. a cable unplugged then replugged. `seq` is the
      // only thing that differs between the two events.
      sse.add((domain: InvalidationDomain.ethernetInterfaces, seq: 1));
      await settle();
      verifyFetches(1);

      await sse.close();
      container.dispose();
    });

    test('an unrelated domain does not re-fetch', () async {
      final sse = StreamController<InvalidationEvent>();
      final container = createContainer(sse: sse.stream);
      container.listen(ethernetDataProvider, (_, __) {});
      await container.read(ethernetDataProvider.future);
      clearInteractions(mockEthernetSvc);

      // wanStatus is the plausible-but-wrong neighbour: the WAN port is one of
      // the Ethernet interfaces this provider reports, but its IP-layer status
      // lives on Device.IP.Interface. and must not reload the port list.
      sse.add((domain: InvalidationDomain.wanStatus, seq: 0));
      await settle();

      verifyNever(() => mockEthernetSvc.fetch(
            deviceModels: any(named: 'deviceModels'),
          ));

      await sse.close();
      container.dispose();
    });
  });
}

/// Test override for DevicesDataNotifier.
class _TestDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _data;

  _TestDevicesDataNotifier(this._data);

  @override
  Future<DevicesData> build() async => _data;
}

/// Test override that can emit further states, mirroring how the real notifier
/// assigns state directly (devices_data_provider.dart:296) rather than
/// invalidating — so there is no intervening loading frame.
class _PushableDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _initial;

  _PushableDevicesDataNotifier(this._initial);

  @override
  Future<DevicesData> build() async => _initial;

  void emit(DevicesData data) => state = AsyncData(data);
}

/// Test override that settles *after* `ethernetDataProvider`'s own fetch, which
/// is the boot ordering the orchestrator produces: it reads devices and ethernet
/// back to back, so ethernet's `_fetch()` sees devicesData as AsyncLoading.
class _SlowDevicesDataNotifier extends DevicesDataNotifier {
  final DevicesData _data;

  _SlowDevicesDataNotifier(this._data);

  @override
  Future<DevicesData> build() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return _data;
  }
}

/// Creates DevicesData whose `clientDevices` is exactly [clients].
DevicesData _devicesWith(List<ClientDevice> clients) {
  return DevicesData(
    meshNetwork: MeshNetwork(
      master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
      unassignedClients: clients,
    ),
  );
}

/// Creates an empty DevicesData for testing.
DevicesData _emptyDevicesData() {
  return DevicesData(
    meshNetwork: MeshNetwork(
      master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
    ),
  );
}
