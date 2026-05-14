import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

// Re-export so existing consumers can still import DevicesCodegenContext from here.
export 'package:privacy_gui/page/devices/services/usp_devices_data_service.dart'
    show DevicesCodegenContext;

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — UIModel only)
// ---------------------------------------------------------------------------

class DevicesData extends Equatable {
  final DevicesCodegenContext codegenContext;
  final MeshTopologyInfo meshTopology;

  // UI models (computed from raw + cross-domain enrichment)
  final List<DeviceUIModel> deviceModels;
  final List<NodeUIModel> nodeModels;

  /// Pre-computed MAC → hostname map for DHCP hostname enrichment.
  final Map<String, String> hostNameByMac;

  const DevicesData({
    this.codegenContext = DevicesCodegenContext.empty,
    this.meshTopology = MeshTopologyInfo.empty,
    this.deviceModels = const [],
    this.nodeModels = const [],
    this.hostNameByMac = const {},
  });

  /// Client devices only (excludes mesh nodes: master/slave).
  List<DeviceUIModel> get clientDevices => deviceModels
      .where((d) => d.deviceRole != 'master' && d.deviceRole != 'slave')
      .toList();

  /// Count of online client devices.
  int get onlineClientCount => clientDevices.where((d) => d.isActive).length;

  /// Total count of client devices.
  int get totalClientCount => clientDevices.length;

  DevicesData copyWith({
    DevicesCodegenContext? codegenContext,
    MeshTopologyInfo? meshTopology,
    List<DeviceUIModel>? deviceModels,
    List<NodeUIModel>? nodeModels,
    Map<String, String>? hostNameByMac,
  }) {
    return DevicesData(
      codegenContext: codegenContext ?? this.codegenContext,
      meshTopology: meshTopology ?? this.meshTopology,
      deviceModels: deviceModels ?? this.deviceModels,
      nodeModels: nodeModels ?? this.nodeModels,
      hostNameByMac: hostNameByMac ?? this.hostNameByMac,
    );
  }

  @override
  List<Object?> get props => [
        codegenContext,
        meshTopology.nodes.length,
        deviceModels,
        nodeModels,
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

  @override
  Future<DevicesData> build() async {
    // SSE: listen for device domain changes → debounce → re-fetch
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.connectedDevices) {
        _debouncedInvalidate();
      }
    });

    // WiFi data changes → rebuild deviceModels with updated enrichment.
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

      final rebuilt = svc.rebuildWithWifiData(
        context: cur.codegenContext,
        wifiClientMap: wd.wifiClientMap,
        connectionDetailMap: wd.connectionDetailMap,
        meshTopology: cur.meshTopology,
        gatewayName: gatewayName,
        systemInfo: sysInfo,
      );

      state = AsyncData(cur.copyWith(
        deviceModels: rebuilt.deviceModels,
        nodeModels: rebuilt.nodeModels,
      ));
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
        'deviceModels: ${result.deviceModels.length}, '
        'nodeModels: ${result.nodeModels.length}');

    // Preserve existing mesh topology during refetch to avoid UI flicker.
    // Fire-and-forget will update it shortly after.
    final existingMesh = state.valueOrNull?.meshTopology ?? MeshTopologyInfo.empty;

    // Fire-and-forget: fetch mesh topology in background, then update state.
    _fetchMeshAndUpdate(svc, wifiData, gatewayName, sysData, result);

    return DevicesData(
      codegenContext: result.codegenContext,
      meshTopology: existingMesh,
      deviceModels: result.deviceModels,
      nodeModels: result.nodeModels,
      hostNameByMac: result.hostNameByMac,
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
    final meshTopology = await svc.fetchMeshTopology();
    if (meshTopology.isEmpty) return;

    final cur = state.valueOrNull;
    if (cur == null) return;

    final rebuilt = svc.rebuildWithMesh(
      context: cur.codegenContext,
      wifiClientMap: wifiData.wifiClientMap,
      connectionDetailMap: wifiData.connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
      systemInfo: sysData?.model,
    );

    logger.d('[USP][DevicesData]: Mesh update — '
        'meshNodes: ${meshTopology.nodes.length}, '
        'nodeModels: ${rebuilt.nodeModels.length}, '
        'deviceModels: ${rebuilt.deviceModels.length}');

    state = AsyncData(cur.copyWith(
      meshTopology: meshTopology,
      deviceModels: rebuilt.deviceModels,
      nodeModels: rebuilt.nodeModels,
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
    final rebuilt = existingMesh.isEmpty
        ? (deviceModels: result.deviceModels, nodeModels: result.nodeModels)
        : svc.rebuildWithMesh(
            context: result.codegenContext,
            wifiClientMap: wifiData.wifiClientMap,
            connectionDetailMap: wifiData.connectionDetailMap,
            meshTopology: existingMesh,
            gatewayName: gatewayName,
            systemInfo: sysData?.model,
          );

    logger.d('[USP][DevicesData]: Refetch (preserve mesh) — '
        'deviceModels: ${rebuilt.deviceModels.length}, '
        'nodeModels: ${rebuilt.nodeModels.length}, '
        'existingMesh: ${existingMesh.nodes.length}');

    // Update state with new device data but preserve existing mesh topology.
    state = AsyncData(DevicesData(
      codegenContext: result.codegenContext,
      meshTopology: existingMesh,
      deviceModels: rebuilt.deviceModels,
      nodeModels: rebuilt.nodeModels,
      hostNameByMac: result.hostNameByMac,
    ));

    // Fire-and-forget: fetch mesh topology in background, then update state.
    _fetchMeshAndUpdate(svc, wifiData, gatewayName, sysData, result);
  }
}
