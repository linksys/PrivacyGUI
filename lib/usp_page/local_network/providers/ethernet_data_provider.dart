import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/usp_page/dashboard/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/services/usp_device_service.dart';
import 'package:privacy_gui/usp_page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

/// Layer 1 Ethernet Data Provider — raw EthernetInterfaces + port UI models.
///
/// NOT autoDispose — persists across tab switches.
/// Listens to [devicesDataProvider] to rebuild port models when device list changes.
final ethernetDataProvider =
    AsyncNotifierProvider<EthernetDataNotifier, EthernetData>(
  EthernetDataNotifier.new,
);

/// Aggregated Ethernet data: raw codegen + bridge classification + UI models.
class EthernetData extends Equatable {
  /// Raw codegen Ethernet interfaces.
  final EthernetInterfaces ethernetInterfaces;

  /// Bridge port → Ethernet interface mapping (for WAN/LAN classification).
  final Map<String, String> bridgePortMap;

  /// Presentation-layer port models (WAN/LAN classified, with connected devices).
  final List<EthernetPortUIModel> ethernetPortModels;

  const EthernetData({
    required this.ethernetInterfaces,
    this.bridgePortMap = const {},
    this.ethernetPortModels = const [],
  });

  EthernetData copyWith({
    EthernetInterfaces? ethernetInterfaces,
    Map<String, String>? bridgePortMap,
    List<EthernetPortUIModel>? ethernetPortModels,
  }) {
    return EthernetData(
      ethernetInterfaces: ethernetInterfaces ?? this.ethernetInterfaces,
      bridgePortMap: bridgePortMap ?? this.bridgePortMap,
      ethernetPortModels: ethernetPortModels ?? this.ethernetPortModels,
    );
  }

  @override
  List<Object?> get props => [
        ethernetInterfaces.items.length,
        bridgePortMap.length,
        ethernetPortModels.length,
      ];
}

class EthernetDataNotifier extends AsyncNotifier<EthernetData> {
  UspDeviceService get _svc => ref.read(uspDeviceServiceProvider);

  @override
  Future<EthernetData> build() async {
    // Listen to Devices Data Provider changes → rebuild ethernetPortModels.
    // Device list changes affect which wired devices show on LAN ports.
    ref.listen(devicesDataProvider, (_, next) {
      final dd = next.valueOrNull;
      final cur = state.valueOrNull;
      if (dd == null || cur == null) return;
      final rebuiltPorts = _svc.buildEthernetPortUIModels(
        ethernetInterfaces: cur.ethernetInterfaces,
        deviceModels: dd.deviceModels,
        bridgePortMap: cur.bridgePortMap,
      );
      state = AsyncData(cur.copyWith(ethernetPortModels: rebuiltPorts));
    });

    return _fetch();
  }

  Future<EthernetData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    // Parallel: fetch Ethernet interfaces + bridge port map
    final results = await Future.wait([
      EthernetInterfaces.fetch(usp),
      _fetchBridgePortMap(usp),
    ]);
    final ethernetInterfaces = results[0] as EthernetInterfaces;
    final bridgePortMap = results[1] as Map<String, String>;

    // Read current device models for port ↔ device mapping
    final devicesData = ref.read(devicesDataProvider).valueOrNull;
    final deviceModels = devicesData?.deviceModels ?? [];

    final portModels = _svc.buildEthernetPortUIModels(
      ethernetInterfaces: ethernetInterfaces,
      deviceModels: deviceModels,
      bridgePortMap: bridgePortMap,
    );

    logger.d('[USP][Ethernet]Fetch complete — '
        '${ethernetInterfaces.items.length} interfaces, '
        '${portModels.length} port models');

    return EthernetData(
      ethernetInterfaces: ethernetInterfaces,
      bridgePortMap: bridgePortMap,
      ethernetPortModels: portModels,
    );
  }

  // ---------------------------------------------------------------------------
  // Bridge port → Ethernet interface mapping
  // ---------------------------------------------------------------------------

  Future<Map<String, String>> _fetchBridgePortMap(UspService usp) async {
    try {
      final resp = await usp.get([
        'Device.Bridging.Bridge.*.Port.*.LowerLayers',
      ]).timeout(const Duration(seconds: 10));
      final map = <String, String>{};
      for (final entry in resp.entries) {
        if (!entry.key.endsWith('.LowerLayers')) continue;
        final lowerLayers = entry.value?.toString() ?? '';
        if (lowerLayers.isEmpty) continue;
        final bridgePortPath = entry.key.substring(
          0,
          entry.key.length - 'LowerLayers'.length,
        );
        for (final layer in lowerLayers.split(',')) {
          final trimmed = layer.trim();
          if (trimmed.startsWith('Device.Ethernet.Interface.')) {
            final normalized = trimmed.endsWith('.') ? trimmed : '$trimmed.';
            map[bridgePortPath] = normalized;
            break;
          }
        }
      }
      return map;
    } catch (e) {
      logger.w('[USP][Ethernet]Bridge port map fetch failed: $e');
      return {};
    }
  }
}
