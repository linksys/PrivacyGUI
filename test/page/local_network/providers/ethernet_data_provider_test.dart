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

/// Creates an empty DevicesData for testing.
DevicesData _emptyDevicesData() {
  return DevicesData(
    meshNetwork: MeshNetwork(
      master: MasterNode(deviceId: 'GATEWAY', model: 'TestRouter'),
    ),
  );
}
