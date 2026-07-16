import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
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
    ref.listen(devicesDataProvider, (_, next) {
      if (next.hasValue && state.hasValue) {
        ref.invalidateSelf();
      }
    });

    return _fetch();
  }

  Future<EthernetData> _fetch() async {
    final svc = ref.read(uspEthernetDataServiceProvider);
    final devicesData = ref.read(devicesDataProvider).valueOrNull;
    final devices = devicesData?.clientDevices ?? [];

    final result = await svc.fetch(deviceModels: devices);

    return EthernetData(ethernetPortModels: result.portModels);
  }
}
