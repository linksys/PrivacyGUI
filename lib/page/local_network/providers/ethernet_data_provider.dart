import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_ethernet_data_service.dart';

/// Layer 1 Ethernet Data Provider — port UI models.
///
/// NOT autoDispose — persists across tab switches.
/// Listens to [devicesDataProvider] to re-fetch when device list changes.
final ethernetDataProvider =
    AsyncNotifierProvider<EthernetDataNotifier, EthernetData>(
  EthernetDataNotifier.new,
);

/// Aggregated Ethernet data: presentation-layer port models.
class EthernetData extends Equatable with DiagnosticLoggable {
  final List<EthernetPortUIModel> ethernetPortModels;

  const EthernetData({
    this.ethernetPortModels = const [],
  });

  EthernetData copyWith({
    List<EthernetPortUIModel>? ethernetPortModels,
  }) {
    return EthernetData(
      ethernetPortModels: ethernetPortModels ?? this.ethernetPortModels,
    );
  }

  @override
  String get diagnosticName => 'EthernetData';

  @override
  Map<String, Object?> get namedProps => {
        'ethernetPortModels': ethernetPortModels,
      };
}

class EthernetDataNotifier extends AsyncNotifier<EthernetData> {
  /// The `deviceModels` list the most recent [_fetch] passed to the service.
  ///
  /// This, not the listener's `prev` argument, is what the devices listener
  /// compares against — see the comment at the listener. Whether riverpod
  /// reuses this notifier across builds or creates a fresh one does not matter:
  /// [_fetch] writes the field before its await, so the listener never compares
  /// against a stale generation, and the initial `const []` is exactly what the
  /// first fetch consumes when `devicesDataProvider` has not settled yet.
  List<ClientDevice> _consumedDevices = const [];

  @override
  Future<EthernetData> build() async {
    // SSE listener: Ethernet interface status changes (link up/down)
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.value == InvalidationDomain.ethernetInterfaces) {
        ref.invalidateSelf();
      }
    });

    // Devices listener: device list changes affect which wired devices
    // show on LAN ports. Re-fetch to get fresh Ethernet data.
    //
    // Compare the exact input _fetch() consumes — `clientDevices`, the only
    // thing passed to the service at :78 — rather than re-fetching on every
    // DevicesData emission. In riverpod 2.6.1 an AsyncNotifier re-notifies on
    // every data→data transition even when the payload is identical, so the
    // unguarded version spent one Ethernet USP fetch per redundant emission.
    // Skipping is lossless: causes that are not the device list arrive via the
    // SSE listener above.
    //
    // `ListEquality`, not `==`: `clientDevices` is a plain List built fresh by
    // `MeshNetwork.allClients`, so `==` is reference equality and would make
    // this guard inert. Template: dhcp_data_provider.dart:58 (MapEquality).
    // The *elements* do compare by value — `ClientDevice extends NetworkEntity`,
    // which is `EquatableMixin` — so the comparison is deep end to end. If a
    // future model drops that, this guard silently reverts to always-unequal.
    //
    // The comparison is against [_consumedDevices] — what the last _fetch()
    // actually passed to the service — not against `prev`. Using `prev` was
    // wrong in two ways, both reachable on a normal dashboard boot, because
    // the orchestrator triggers devices and ethernet back to back
    // (dashboard_orchestrator.dart:158-159) so the two settle in a race:
    //
    //  - Ethernet wins: its _fetch() read devicesData as AsyncLoading and
    //    passed []. At the settle `prev` carries no value, and
    //    `ListEquality.equals(null, [...])` is false, so an *empty* device list
    //    looked like a change and cost a second fetch on identical input.
    //  - Devices wins: the settle arrives while this provider's own _fetch() is
    //    still in flight, so a `state.hasValue` guard drops it — and the fetch
    //    it would have corrected already consumed []. Ethernet then serves port
    //    models built from an empty device list until the list changes again or
    //    an `ethernetInterfaces` SSE event lands.
    //
    // A field holding the consumed input answers both without a special case
    // for "no previous value": it starts as the empty list the first fetch
    // really does consume, and it is written before the await, so a settle
    // arriving mid-fetch still compares against the right thing.
    ref.listen(devicesDataProvider, (_, next) {
      final devices = next.valueOrNull?.clientDevices;
      if (devices == null) return;
      if (const ListEquality<ClientDevice>().equals(_consumedDevices, devices)) {
        return;
      }
      ref.invalidateSelf();
    });

    return _fetch();
  }

  Future<EthernetData> _fetch() async {
    final svc = ref.read(uspEthernetDataServiceProvider);
    final devicesData = ref.read(devicesDataProvider).valueOrNull;
    final devices = devicesData?.clientDevices ?? const <ClientDevice>[];
    // Written before the await so a settle arriving mid-fetch compares against
    // the input this fetch is actually consuming.
    _consumedDevices = devices;

    final result = await svc.fetch(deviceModels: devices);

    return EthernetData(ethernetPortModels: result.portModels);
  }
}
