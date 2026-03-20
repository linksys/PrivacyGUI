import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — UIModel only)
// ---------------------------------------------------------------------------

class DevicesData extends Equatable {
  final MeshTopologyInfo meshTopology;

  // UI models (computed from raw + cross-domain enrichment)
  final List<DeviceUIModel> deviceModels;
  final List<NodeUIModel> nodeModels;

  /// Pre-computed MAC → hostname map for DHCP hostname enrichment.
  final Map<String, String> hostNameByMac;

  const DevicesData({
    this.meshTopology = MeshTopologyInfo.empty,
    this.deviceModels = const [],
    this.nodeModels = const [],
    this.hostNameByMac = const {},
  });

  DevicesData copyWith({
    MeshTopologyInfo? meshTopology,
    List<DeviceUIModel>? deviceModels,
    List<NodeUIModel>? nodeModels,
    Map<String, String>? hostNameByMac,
  }) {
    return DevicesData(
      meshTopology: meshTopology ?? this.meshTopology,
      deviceModels: deviceModels ?? this.deviceModels,
      nodeModels: nodeModels ?? this.nodeModels,
      hostNameByMac: hostNameByMac ?? this.hostNameByMac,
    );
  }

  @override
  List<Object?> get props => [
        meshTopology.nodes.length,
        deviceModels.length,
        nodeModels.length,
        hostNameByMac.length,
      ];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final devicesDataProvider =
    AsyncNotifierProvider<DevicesDataNotifier, DevicesData>(
        DevicesDataNotifier.new);

// ---------------------------------------------------------------------------
// Notifier (NOT autoDispose — persists for dashboard card lifetime)
// ---------------------------------------------------------------------------

class DevicesDataNotifier extends AsyncNotifier<DevicesData> {
  Timer? _debounce;

  /// Raw codegen kept as internal state for WiFi listener rebuild.
  ConnectedDevices? _rawConnectedDevices;

  @override
  Future<DevicesData> build() async {
    // SSE: listen for device domain changes → debounce → re-fetch
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.connectedDevices) {
        _debouncedInvalidate();
      }
    });

    // WiFi data changes → rebuild deviceModels with updated enrichment
    ref.listen(wifiDataProvider, (_, next) {
      final wd = next.valueOrNull;
      final cur = state.valueOrNull;
      final raw = _rawConnectedDevices;
      if (wd == null || cur == null || raw == null) return;
      final svc = ref.read(uspDeviceServiceProvider);
      final gatewayName =
          ref.read(systemInfoDataProvider).valueOrNull?.model.gatewayName ??
              'Router';
      final rebuiltDevices = svc.buildDeviceUIModels(
        connectedDevices: raw,
        wifiClientMap: wd.wifiClientMap,
        connectionDetailMap: wd.connectionDetailMap,
        meshTopology: cur.meshTopology,
        gatewayName: gatewayName,
      );
      state = AsyncData(cur.copyWith(deviceModels: rebuiltDevices));
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch();
  }

  Future<DevicesData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    // Parallel fetch devices + mesh topology
    final results = await Future.wait([
      ConnectedDevices.fetch(usp),
      fetchMeshNodes(usp),
    ]);

    final connectedDevices = results[0] as ConnectedDevices;
    final meshTopology = results[1] as MeshTopologyInfo;

    // Cache raw for WiFi listener rebuild.
    _rawConnectedDevices = connectedDevices;

    // Build hostname map for DHCP enrichment.
    final hostNameByMac = <String, String>{};
    for (final d in connectedDevices.items) {
      if (d.hostName.isNotEmpty) {
        hostNameByMac[d.macAddress.trim().toUpperCase()] = d.hostName;
      }
    }

    // Read WiFi enrichment data from domain provider
    final wifiData = await ref.read(wifiDataProvider.future);

    // Read system info for gateway name + node model building
    final sysData = ref.read(systemInfoDataProvider).valueOrNull;
    final gatewayName = sysData?.model.gatewayName ?? 'Router';

    // Build UI models
    final svc = ref.read(uspDeviceServiceProvider);
    final deviceModels = svc.buildDeviceUIModels(
      connectedDevices: connectedDevices,
      wifiClientMap: wifiData.wifiClientMap,
      connectionDetailMap: wifiData.connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
    );

    final nodeModels = sysData != null
        ? svc.buildNodeUIModels(
            meshTopology: meshTopology,
            deviceModels: deviceModels,
            systemInfo: sysData.model,
          )
        : <NodeUIModel>[];

    logger.d('[USP][DevicesData] Fetched — '
        'devices: ${connectedDevices.items.length}, '
        'meshNodes: ${meshTopology.nodes.length}, '
        'deviceModels: ${deviceModels.length}, '
        'nodeModels: ${nodeModels.length}');

    return DevicesData(
      meshTopology: meshTopology,
      deviceModels: deviceModels,
      nodeModels: nodeModels,
      hostNameByMac: hostNameByMac,
    );
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }
}
