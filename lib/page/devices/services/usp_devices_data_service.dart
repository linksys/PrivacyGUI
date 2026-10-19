import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_topology_builder.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_network_builder.dart';
import 'package:privacy_gui/generated/data_elements_interfaces.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspDevicesDataServiceProvider = Provider<UspDevicesDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspDevicesDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Opaque codegen context
// ---------------------------------------------------------------------------

/// Opaque wrapper around raw ConnectedDevices codegen data.
///
/// Held by [DevicesDataNotifier] and passed back to [UspDevicesDataService]
/// for incremental rebuilds (WiFi listener, mesh update) without the provider
/// needing to import codegen types.
class DevicesCodegenContext extends Equatable {
  final ConnectedDevices _connectedDevices;

  const DevicesCodegenContext(this._connectedDevices);

  static const empty = DevicesCodegenContext(ConnectedDevices(items: []));

  @override
  List<Object?> get props => [_connectedDevices.items.length];
}

// ---------------------------------------------------------------------------
// Fetch result
// ---------------------------------------------------------------------------

/// Result of a devices data fetch, returned by [UspDevicesDataService.fetch].
class DevicesDataFetchResult {
  final DevicesCodegenContext codegenContext;
  final Map<String, String> hostNameByMac;

  /// Unified MeshNetwork container (SSoT for nodes and clients).
  final MeshNetwork meshNetwork;

  const DevicesDataFetchResult({
    required this.codegenContext,
    required this.hostNameByMac,
    required this.meshNetwork,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching and transforming connected devices data.
///
/// Owns the codegen call, error mapping, and all device/node UI model building
/// for [devicesDataProvider].
class UspDevicesDataService {
  final UspClient _usp;

  UspDevicesDataService(this._usp);

  /// Fetches connected devices and returns a [DevicesDataFetchResult].
  ///
  /// Builds device and node UI models with empty mesh topology.
  /// Mesh topology is fetched separately via [fetchMeshTopology].
  Future<DevicesDataFetchResult> fetch({
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required String gatewayName,
    SystemInfoUIModel? systemInfo,
  }) async {
    final ConnectedDevices connectedDevices;
    try {
      connectedDevices = await ConnectedDevices.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final context = DevicesCodegenContext(connectedDevices);

    final hostNameByMac = _buildHostNameMap(connectedDevices);

    // Build MeshNetwork (SSoT for nodes and clients)
    final meshNetwork = MeshNetworkBuilder.build(
      connectedDevices: connectedDevices,
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      meshTopology: MeshTopologyInfo.empty,
      gatewayName: gatewayName,
      systemInfo: systemInfo,
    );

    return DevicesDataFetchResult(
      codegenContext: context,
      hostNameByMac: hostNameByMac,
      meshNetwork: meshNetwork,
    );
  }

  /// Fetches mesh topology via DataElements (fire-and-forget from provider).
  ///
  /// Delegates nested multi-instance parsing
  /// (Device.{i} → Radio.{j} → BSS.{k} → STA.{l})
  /// to codegen [DataElementsNetwork.fetch], then transforms the tree
  /// into a flat [MeshTopologyInfo] with client→node mapping.
  ///
  /// [bssidToBandMap] is a BSSID → band mapping for resolving band info
  /// for clients on slave nodes. Build it via
  /// [UspWifiDataService.buildBssidToBandMap].
  ///
  /// Returns [MeshTopologyInfo.empty] if the router doesn't support
  /// DataElements or the subtree is empty (non-mesh / single router).
  Future<MeshTopologyInfo> fetchMeshTopology({
    Map<String, String> bssidToBandMap = const {},
  }) async {
    try {
      final results = await Future.wait([
        DataElementsNetwork.fetch(_usp),
        _fetchInterfaces(),
      ]);
      final network = results[0] as DataElementsNetwork;
      final interfaces = results[1] as DataElementsInterfaces?;
      if (network.items.isEmpty) {
        logger.d(
            '[USP][Dashboard]: DataElements empty — not a mesh or unsupported');
        return MeshTopologyInfo.empty;
      }
      return _buildTopologyInfo(network, bssidToBandMap, interfaces);
    } catch (e) {
      // `w`, not `d`. An empty subtree (above) is an expected single-router
      // result; a *fault* means the request did not answer the question, and the
      // two used to be one `d` line apart. That is how a schema mismatch went
      // unnoticed for a whole firmware generation: pre-#1555 this fetch threw
      // `9998` on every call against FL-WRT 2.0 — four required parameters had
      // been removed from the data model — and the entire mesh surface silently
      // degraded to "not a mesh" behind a debug line nobody reads.
      logger.w('[USP][Dashboard]: DataElements fetch faulted, treating the '
          'network as non-mesh: $e');
      return MeshTopologyInfo.empty;
    }
  }

  /// Writes the name and icon the user gave a client, in one Set (#1691).
  ///
  /// The name goes to `X_LINKSYS_UserDeviceLocation`, which the firmware's
  /// `X_LINKSYS_FriendlyName` reads back; the icon is the app's own code
  /// (`DeviceCategory.userTypeCode`) in `X_LINKSYS_UserDeviceType`. `''`
  /// clears either, so the client falls back to what the firmware detected.
  /// A null [userTypeCode] leaves the stored type alone: a name-only edit must
  /// not erase a type another client wrote.
  Future<void> updateIdentity({
    required String hostInstancePath,
    required String name,
    String? userTypeCode,
  }) async {
    try {
      final result = await ConnectedDevices.update(_usp, [
        ConnectedDeviceUpdate(
          instancePath: hostInstancePath,
          linksysUserDeviceLocation: name,
          linksysUserDeviceType: userTypeCode,
        ),
      ]);
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'Device identity partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'Device identity update failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Reads `Interface.{j}.Neighbor.{k}`, the source of wired-client
  /// attribution (#1688 item 2).
  ///
  /// A separate definition and a separate read on purpose: a controller
  /// without this object must lose only wired attribution, never the topology
  /// (`data_elements_interfaces.yaml`). So a fault returns null, which
  /// [MeshTopologyBuilder.build] reads as "wired clients stay on the master",
  /// and is logged rather than rethrown.
  Future<DataElementsInterfaces?> _fetchInterfaces() async {
    try {
      return await DataElementsInterfaces.fetch(_usp);
    } catch (e) {
      logger.w('[USP][Dashboard]: DataElements interfaces unavailable, wired '
          'clients stay on the master: $e');
      return null;
    }
  }

  MeshTopologyInfo _buildTopologyInfo(
    DataElementsNetwork network,
    Map<String, String> bssidToBandMap,
    DataElementsInterfaces? interfaces,
  ) {
    final result = MeshTopologyBuilder.build(
      network,
      bssidToBandMap: bssidToBandMap,
      interfaces: interfaces,
    );
    logger.t('[USP][Dashboard]: Mesh nodes: ${result.nodes.length}, '
        'client→node mappings: ${result.clientToNodeMap.length}, '
        'band/SSID mappings: ${result.clientBandSsidMap.length}, '
        'wired client→node: ${result.wiredClientToNodeMap.length}, '
        'ambiguous wired: ${result.ambiguousWiredClients.length}');
    return result;
  }

  /// Rebuilds MeshNetwork with updated WiFi enrichment data.
  ///
  /// Called by the provider's WiFi listener for incremental rebuild
  /// without re-fetching ConnectedDevices.
  MeshNetwork rebuildWithWifiData({
    required DevicesCodegenContext context,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
    SystemInfoUIModel? systemInfo,
  }) {
    return MeshNetworkBuilder.build(
      connectedDevices: context._connectedDevices,
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
      systemInfo: systemInfo,
    );
  }

  /// Rebuilds MeshNetwork after mesh topology arrives.
  MeshNetwork rebuildWithMesh({
    required DevicesCodegenContext context,
    required Map<String, WifiClientUIModel> wifiClientMap,
    required Map<String, ClientConnectionDetail> connectionDetailMap,
    required MeshTopologyInfo meshTopology,
    required String gatewayName,
    SystemInfoUIModel? systemInfo,
  }) {
    return rebuildWithWifiData(
      context: context,
      wifiClientMap: wifiClientMap,
      connectionDetailMap: connectionDetailMap,
      meshTopology: meshTopology,
      gatewayName: gatewayName,
      systemInfo: systemInfo,
    );
  }

  // ---------------------------------------------------------------------------
  // Private — UI model builders
  // ---------------------------------------------------------------------------

  Map<String, String> _buildHostNameMap(ConnectedDevices devices) {
    final map = <String, String>{};
    for (final d in devices.items) {
      if (d.hostName.isNotEmpty) {
        map[d.macAddress.trim().toUpperCase()] = d.hostName;
      }
    }
    return map;
  }
}
