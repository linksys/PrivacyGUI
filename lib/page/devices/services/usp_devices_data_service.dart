import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/services/empty_row.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/_shared/services/mesh_topology_builder.dart';
import 'package:privacy_gui/page/_shared/services/mesh_network_builder.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';
import 'package:privacy_gui/generated/data_elements_interfaces.g.dart';
import 'package:privacy_gui/generated/data_elements_mlo_clients.g.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/generated/data_elements_network_info.g.dart';

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

  /// Makes every read sent after it, [fetchMeshTopology] included, go to the router
  /// rather than to a result read before a mesh node joined or left (#1828); see
  /// [UspClient.dropSharedReads]. Call it when the app learns of the change.
  void dropSharedReads() => _usp.dropSharedReads();

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
        _fetchControllerId(),
        _fetchMld(),
      ]);
      // A node with every value blank is no node (usp-codegen 0.17 dropped it).
      final network = DataElementsNetwork(
          items: (results[0] as DataElementsNetwork)
              .items
              .where((n) => !isEmptyMeshNode(n))
              .toList());
      final interfaces = results[1] as DataElementsInterfaces?;
      final controllerId = results[2] as String?;
      final mld = results[3] as DataElementsMloClients?;
      if (network.items.isEmpty) {
        logger.d(
            '[USP][Dashboard]: DataElements empty — not a mesh or unsupported');
        return MeshTopologyInfo.empty;
      }
      return _buildTopologyInfo(
          network, bssidToBandMap, interfaces, controllerId, mld);
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
  ///
  /// [macs] are the `PhysAddress` of every row of the device, all written in
  /// the one Set: devidentd keeps the name per MAC, so a row left out keeps
  /// its old name, and the device shows it whenever that row is the only one
  /// present. The rows merge by `X_LINKSYS_DetectedName` (#1719), which the
  /// user's name does not change, so naming them does not regroup them.
  ///
  /// **The rows are found by MAC at the moment of the write, not by a row
  /// number read earlier (#1840).** On FL-WRT 2.0, `Hosts.Host` rows renumber
  /// when a row ahead of them is added or removed. While an agent rejoins, its
  /// backhaul station takes the agent's index for about 50 s and every later
  /// row moves up one. So a row number from the last read can name another
  /// device by the time the user saves, and the Set would succeed on it. This
  /// reads every row's `PhysAddress` in one GET, past the shared-read cache,
  /// and writes the rows that carry one of [macs] now. What is left is the
  /// round trip between that read and the Set.
  ///
  /// The router could find the rows itself from a search path
  /// (`Host.[PhysAddress=="…"].`), which obuspa accepts, but the USP client
  /// refuses such a path before sending it (`validate_path`, 9997).
  ///
  /// A MAC with no row now has nothing to write to and is left out. When none
  /// of [macs] has one, the device has left the network: nothing is written,
  /// and [DeviceNotOnNetworkError] is thrown. No MAC at all, or only blank
  /// ones, is a [ResourceNotFoundError], before anything is read.
  Future<void> updateIdentity({
    required List<String> macs,
    required String name,
    String? userTypeCode,
  }) async {
    // The generated update answers success without a Set when it has no
    // params, which would report a name that was never written. A blank MAC
    // names no row, so a list of only blank MACs is no row either.
    final wanted = {for (final mac in macs) meshNodeMacKey(mac)}..remove('');
    if (wanted.isEmpty) {
      throw const ResourceNotFoundError(
        detail: 'No MAC to find the device identity rows by',
      );
    }
    try {
      final hostInstancePaths = await _currentHostRows(wanted);
      if (hostInstancePaths.isEmpty) {
        throw const DeviceNotOnNetworkError(
          detail: 'No Hosts row carries any of the device MACs now',
        );
      }
      final result = await ConnectedDevices.update(_usp, [
        for (final path in hostInstancePaths)
          ConnectedDeviceUpdate(
            instancePath: path,
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

  /// The `Device.Hosts.Host.{i}.` rows whose `PhysAddress` is one of
  /// [wanted] now, from one fresh GET of every row's `PhysAddress`.
  ///
  /// One GET, so every row number and MAC comes from the same moment: a read
  /// per row could straddle a renumbering. [wanted] is in [meshNodeMacKey]
  /// form and each row's MAC is compared in it, because Hosts reports MACs in
  /// lower case and the app holds them in upper case. Every row carrying a MAC
  /// is returned, so a MAC that has two rows is named on both.
  Future<List<String>> _currentHostRows(Set<String> wanted) async {
    final rows = await _usp.get(const [_hostPhysAddresses], fresh: true);
    return [
      for (final MapEntry(:key, :value) in rows.entries)
        if (_hostPhysAddressPath.firstMatch(key) case final match?
            when value is String && wanted.contains(meshNodeMacKey(value)))
          match.group(1)!,
    ];
  }

  static const _hostPhysAddresses = 'Device.Hosts.Host.*.PhysAddress';
  static final _hostPhysAddressPath =
      RegExp(r'^(Device\.Hosts\.Host\.\d+\.)PhysAddress$');

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
      // A node with no ID is no node (usp-codegen 0.17 dropped it), and its
      // interface MACs must not be counted as the mesh's own.
      final interfaces = await DataElementsInterfaces.fetch(_usp);
      return DataElementsInterfaces(
          items: interfaces.items
              .where((n) => !isEmptyMeshInterfaceNode(n))
              .toList());
    } catch (e) {
      logger.w('[USP][Dashboard]: DataElements interfaces unavailable, wired '
          'clients stay on the master: $e');
      return null;
    }
  }

  /// Reads `Device.WiFi.DataElements.Network.ControllerID`, which tells the
  /// controller apart from an agent whose backhaul is not filled in yet
  /// (#1688 review). Without it such an agent is built as a second master and
  /// drops out of the topology. Isolated like [_fetchInterfaces]: a fault
  /// returns null and the backhaul rule decides, as before.
  Future<String?> _fetchControllerId() async {
    try {
      return (await DataElementsNetworkInfo.fetch(_usp)).controllerId;
    } catch (e) {
      logger.w('[USP][Dashboard]: DataElements ControllerID unavailable, the '
          'controller is told apart by backhaul: $e');
      return null;
    }
  }

  /// Reads `APMLD.{j}.STAMLD.{k}.AffiliatedSTA.{l}`, the client MLDs (#1686
  /// item 2). Isolated like [_fetchInterfaces], so a fault never costs the
  /// topology. Three outcomes, kept apart because the view shows them apart:
  /// - read: the subtree, empty when no client is on MLO (also what firmware
  ///   with MLO switched off answers);
  /// - path not found (7026 and its kin → [ResourceNotFoundError]): firmware
  ///   without the TR-181 2.17 MLD objects, which can have no MLO client, so
  ///   an empty subtree, not "not known" — or every client on such firmware
  ///   would carry "MLO status unavailable" for good;
  /// - any other fault: null, "not known".
  Future<DataElementsMloClients?> _fetchMld() async {
    try {
      return await DataElementsMloClients.fetch(_usp);
    } catch (e) {
      final error = e is ServiceError ? e : mapUspErrorToServiceError(e);
      if (error is ResourceNotFoundError) {
        logger.d('[USP][Dashboard]: no DataElements MLD objects on this '
            'firmware, so no MLO client: $e');
        return const DataElementsMloClients(items: []);
      }
      logger.w('[USP][Dashboard]: DataElements MLD unavailable, MLO clients '
          'are not known: $e');
      return null;
    }
  }

  MeshTopologyInfo _buildTopologyInfo(
    DataElementsNetwork network,
    Map<String, String> bssidToBandMap,
    DataElementsInterfaces? interfaces,
    String? controllerId,
    DataElementsMloClients? mld,
  ) {
    final result = MeshTopologyBuilder.build(
      network,
      bssidToBandMap: bssidToBandMap,
      interfaces: interfaces,
      controllerId: controllerId,
      mld: mld,
    );
    logger.t('[USP][Dashboard]: Mesh nodes: ${result.nodes.length}, '
        'client→node mappings: ${result.clientToNodeMap.length}, '
        'band/SSID mappings: ${result.clientBandSsidMap.length}, '
        'wired client→node: ${result.wiredClientToNodeMap.length}, '
        'ambiguous wired: ${result.ambiguousWiredClients.length}, '
        'MLO clients: ${result.mloClients?.length ?? 'unknown'}');
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
