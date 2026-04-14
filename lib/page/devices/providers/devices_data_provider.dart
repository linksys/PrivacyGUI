import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/page/devices/services/connected_devices_service.dart';
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

    // WiFi data changes → rebuild deviceModels with updated enrichment.
    // NOTE: Do NOT check state.valueOrNull — during build()'s async
    // execution, state is AsyncLoading so the check would skip the rebuild.
    ref.listen(wifiDataProvider, (_, next) {
      final wd = next.valueOrNull;
      final raw = _rawConnectedDevices;
      final cur = state.valueOrNull;
      if (wd == null || raw == null || cur == null) return;
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
    // REFACTORED: Use ConnectedDevicesService instead of direct codegen
    final connectedDevicesService = ref.read(connectedDevicesServiceProvider);

    try {
      // Service layer handles:
      // - ConnectedDevices.fetch() with structured error handling
      // - Multi-model aggregation and business logic
      // - UspDeviceService integration for UI model building
      final serviceResult =
          await connectedDevicesService.fetchConnectedDevicesData();

      // REFACTORED: Service now exposes both raw data and UI models
      // Raw data for WiFi listener compatibility, UI models for immediate use
      _rawConnectedDevices = serviceResult.rawConnectedDevices;

      // Use service result directly
      final deviceModels = serviceResult.deviceModels;
      final meshTopology = serviceResult.meshTopology;
      final nodeModels = serviceResult.nodeModels;
      final hostNameByMac = serviceResult.hostNameByMac;

      logger.d('[USP][DevicesData] Service layer fetch completed — '
          'deviceModels: ${deviceModels.length}, '
          'nodeModels: ${nodeModels.length}');

      // Note: Background mesh fetching is now handled within ConnectedDevicesService
      // This is a cleaner separation of concerns

      return DevicesData(
        meshTopology: meshTopology,
        deviceModels: deviceModels,
        nodeModels: nodeModels,
        hostNameByMac: hostNameByMac,
      );
    } catch (e) {
      // Service layer converts USP/WASM errors to ServiceError
      logger.e('[USP][DevicesData] Service layer error: $e');
      rethrow;
    }
  }

  // TODO [Service Refactor]: Background mesh fetching removed in Service layer integration.
  // The original _fetchMeshAndUpdate() provided performance optimization by:
  // 1. Showing devices immediately with empty mesh
  // 2. Background fetching mesh topology and updating state
  //
  // This pattern needs to be supported in Service layer design for complete refactor.
  // Options:
  // A) Service.fetchInitial() + Service.fetchBackgroundUpdates()
  // B) Service with stream/subscription pattern for progressive updates
  // C) Service with callback pattern for background updates

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }
}
