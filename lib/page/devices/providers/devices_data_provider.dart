import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart';

// Re-export so existing consumers can still import DevicesCodegenContext from here.
export 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart'
    show DevicesCodegenContext;

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — MeshNetwork as SSoT)
// ---------------------------------------------------------------------------

class DevicesData extends Equatable {
  final DevicesCodegenContext codegenContext;
  final MeshTopologyInfo meshTopology;

  /// Pre-computed MAC → hostname map for DHCP hostname enrichment.
  final Map<String, String> hostNameByMac;

  /// Unified MeshNetwork container (SSoT for nodes and clients).
  final MeshNetwork meshNetwork;

  const DevicesData({
    this.codegenContext = DevicesCodegenContext.empty,
    this.meshTopology = MeshTopologyInfo.empty,
    this.hostNameByMac = const {},
    required this.meshNetwork,
  });

  /// All client devices.
  List<ClientDevice> get clientDevices => meshNetwork.allClients;

  /// All mesh nodes (master + slaves).
  List<NodeEntity> get nodes => meshNetwork.allNodes;

  /// Master node.
  MasterNode get master => meshNetwork.master;

  /// Slave nodes.
  List<SlaveNode> get slaves => meshNetwork.slaves;

  /// Count of online client devices.
  int get onlineClientCount => meshNetwork.onlineClientCount;

  /// Total count of client devices.
  int get totalClientCount => meshNetwork.totalClientCount;

  /// Whether this is a mesh network (has slave nodes).
  bool get hasMesh => meshNetwork.hasMesh;

  DevicesData copyWith({
    DevicesCodegenContext? codegenContext,
    MeshTopologyInfo? meshTopology,
    Map<String, String>? hostNameByMac,
    MeshNetwork? meshNetwork,
  }) {
    return DevicesData(
      codegenContext: codegenContext ?? this.codegenContext,
      meshTopology: meshTopology ?? this.meshTopology,
      hostNameByMac: hostNameByMac ?? this.hostNameByMac,
      meshNetwork: meshNetwork ?? this.meshNetwork,
    );
  }

  @override
  List<Object?> get props => [
        codegenContext,
        meshTopology,
        hostNameByMac,
        meshNetwork,
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

  @override
  Future<DevicesData> build() async {
    // SSE: listen for device domain changes → debounce → re-fetch
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.connectedDevices) {
        _debouncedInvalidate();
      }
    });

    // WiFi data changes → rebuild MeshNetwork with updated enrichment.
    ref.listen(wifiDataProvider, (_, next) {
      final wd = next.valueOrNull;
      final cur = state.valueOrNull;
      if (wd == null || cur == null) return;
      if (cur.codegenContext == DevicesCodegenContext.empty) return;

      final svc = ref.read(uspDevicesDataServiceProvider);
      final gatewayName =
          ref.read(systemInfoDataProvider).valueOrNull?.model.gatewayName ??
              'Router';
      final sysInfo = ref.read(systemInfoDataProvider).valueOrNull?.model;

      final meshNetwork = svc.rebuildWithWifiData(
        context: cur.codegenContext,
        wifiClientMap: wd.wifiClientMap,
        connectionDetailMap: wd.connectionDetailMap,
        meshTopology: cur.meshTopology,
        gatewayName: gatewayName,
        systemInfo: sysInfo,
      );

      state = AsyncData(cur.copyWith(meshNetwork: meshNetwork));
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch();
  }

  Future<DevicesData> _fetch() async {
    final svc = ref.read(uspDevicesDataServiceProvider);

    // Read WiFi enrichment data — soft dependency with timeout.
    WifiData wifiData;
    try {
      wifiData = await ref
          .read(wifiDataProvider.future)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      logger.w(
          '[USP][DevicesData]: WiFi data unavailable, proceeding without: $e');
      wifiData = const WifiData.empty();
    }

    // Read system info for gateway name + node model building
    final sysData = ref.read(systemInfoDataProvider).valueOrNull;
    final gatewayName = sysData?.model.gatewayName ?? 'Router';

    final result = await svc.fetch(
      wifiClientMap: wifiData.wifiClientMap,
      connectionDetailMap: wifiData.connectionDetailMap,
      gatewayName: gatewayName,
      systemInfo: sysData?.model,
    );

    logger.d('[USP][DevicesData]: Fetched — '
        'clients: ${result.meshNetwork.totalClientCount}, '
        'nodes: ${result.meshNetwork.allNodes.length}');

    // Preserve existing mesh topology during refetch to avoid UI flicker.
    // Fire-and-forget will update it shortly after.
    final existingMesh =
        state.valueOrNull?.meshTopology ?? MeshTopologyInfo.empty;

    // Fire-and-forget: fetch mesh topology in background, then update state.
    _fetchMeshAndUpdate(svc, wifiData, gatewayName, sysData, result);

    return DevicesData(
      codegenContext: result.codegenContext,
      meshTopology: existingMesh,
      hostNameByMac: result.hostNameByMac,
      meshNetwork: result.meshNetwork,
    );
  }

  /// Background mesh topology fetch — updates state when complete.
  void _fetchMeshAndUpdate(
    UspDevicesDataService svc,
    WifiData wifiData,
    String gatewayName,
    SystemInfoData? sysData,
    DevicesDataFetchResult fetchResult,
  ) async {
    // Build BSSID → band mapping for slave client band resolution
    final wifiCodegen = wifiData.codegenContext.raw;
    final bssidToBandMap = UspWifiDataService.buildBssidToBandMap(
      ssids: wifiCodegen.ssids,
      radios: wifiCodegen.radios,
    );

    final meshTopology = await svc.fetchMeshTopology(
      bssidToBandMap: bssidToBandMap,
    );
    if (meshTopology.isEmpty) return;

    final cur = state.valueOrNull;
    if (cur == null) return;

    final meshNetwork = svc.rebuildWithMesh(
      context: cur.codegenContext,
      wifiClientMap: wifiData.wifiClientMap,
      connectionDetailMap: wifiData.connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
      systemInfo: sysData?.model,
    );

    logger.d('[USP][DevicesData]: Mesh update — '
        'meshNodes: ${meshTopology.nodes.length}, '
        'clients: ${meshNetwork.totalClientCount}');

    state = AsyncData(cur.copyWith(
      meshTopology: meshTopology,
      meshNetwork: meshNetwork,
    ));
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _refetchPreservingMesh();
    });
  }

  /// Refetch device data while preserving the existing mesh topology.
  /// This prevents the slave node from flickering during SSE-triggered refreshes.
  Future<void> _refetchPreservingMesh() async {
    final currentState = state.valueOrNull;
    final existingMesh = currentState?.meshTopology ?? MeshTopologyInfo.empty;
    logger.d('[USP][DevicesData]: _refetchPreservingMesh — '
        'currentState: ${currentState != null}, '
        'existingMesh nodes: ${existingMesh.nodes.length}');

    final svc = ref.read(uspDevicesDataServiceProvider);

    // Read WiFi enrichment data — soft dependency with timeout.
    WifiData wifiData;
    try {
      wifiData = await ref
          .read(wifiDataProvider.future)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      logger.w(
          '[USP][DevicesData]: WiFi data unavailable, proceeding without: $e');
      wifiData = const WifiData.empty();
    }

    // Read system info for gateway name + node model building
    final sysData = ref.read(systemInfoDataProvider).valueOrNull;
    final gatewayName = sysData?.model.gatewayName ?? 'Router';

    final result = await svc.fetch(
      wifiClientMap: wifiData.wifiClientMap,
      connectionDetailMap: wifiData.connectionDetailMap,
      gatewayName: gatewayName,
      systemInfo: sysData?.model,
    );

    // Rebuild with existing mesh to preserve slave node visibility.
    final meshNetwork = existingMesh.isEmpty
        ? result.meshNetwork
        : svc.rebuildWithMesh(
            context: result.codegenContext,
            wifiClientMap: wifiData.wifiClientMap,
            connectionDetailMap: wifiData.connectionDetailMap,
            meshTopology: existingMesh,
            gatewayName: gatewayName,
            systemInfo: sysData?.model,
          );

    logger.d('[USP][DevicesData]: Refetch (preserve mesh) — '
        'clients: ${meshNetwork.totalClientCount}, '
        'existingMesh: ${existingMesh.nodes.length}');

    // Update state with new device data but preserve existing mesh topology.
    state = AsyncData(DevicesData(
      codegenContext: result.codegenContext,
      meshTopology: existingMesh,
      hostNameByMac: result.hostNameByMac,
      meshNetwork: meshNetwork,
    ));

    // Fire-and-forget: fetch mesh topology in background, then update state.
    _fetchMeshAndUpdate(svc, wifiData, gatewayName, sysData, result);
  }
}
