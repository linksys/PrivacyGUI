import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/ethernet_interfaces.g.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';

/// Layer 1 Ethernet Data Provider — port UI models.
///
/// NOT autoDispose — persists across tab switches.
/// Listens to [devicesDataProvider] to rebuild port models when device list changes.
final ethernetDataProvider =
    AsyncNotifierProvider<EthernetDataNotifier, EthernetData>(
  EthernetDataNotifier.new,
);

/// Aggregated Ethernet data: presentation-layer port models.
class EthernetData extends Equatable {
  /// Presentation-layer port models (WAN/LAN classified, with connected devices).
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
  List<Object?> get props => [ethernetPortModels];
}

class EthernetDataNotifier extends AsyncNotifier<EthernetData> {
  UspDeviceService get _svc => ref.read(uspDeviceServiceProvider);

  // Internal raw state for listener rebuild (not exposed in EthernetData)
  EthernetInterfaces? _rawInterfaces;
  Map<String, String> _bridgePortMap = const {};

  @override
  Future<EthernetData> build() async {
    // Listen to Devices Data Provider changes → rebuild ethernetPortModels.
    // Device list changes affect which wired devices show on LAN ports.
    // NOTE: Do NOT check state.valueOrNull here — during build()'s async
    // execution, state is AsyncLoading so the check would skip the rebuild.
    // _rawInterfaces alone is sufficient to guard readiness.
    ref.listen(devicesDataProvider, (_, next) {
      final dd = next.valueOrNull;
      final raw = _rawInterfaces;
      if (dd == null || raw == null) return;
      final rebuiltPorts = _svc.buildEthernetPortUIModels(
        ethernetInterfaces: raw,
        deviceModels: dd.deviceModels,
        bridgePortMap: _bridgePortMap,
      );
      state = AsyncData(EthernetData(ethernetPortModels: rebuiltPorts));
    });

    return _fetch();
  }

  Future<EthernetData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }

    // Parallel: fetch Ethernet interfaces + bridge port map
    final List<Object> results;
    try {
      results = await Future.wait([
        EthernetInterfaces.fetch(usp),
        _fetchBridgePortMap(usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    final ethernetInterfaces = results[0] as EthernetInterfaces;
    final bridgePortMap = results[1] as Map<String, String>;

    // Cache raw data for listener rebuild
    _rawInterfaces = ethernetInterfaces;
    _bridgePortMap = bridgePortMap;

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
      ]).timeout(const Duration(seconds: 20));
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
