import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/wifi_ui.dart';

/// Builds [MeshTopologyInfo] from DataElements network data.
///
/// Shared utility for converting TR-181 DataElements to UI models.
/// Used by both [UspDevicesDataService] and [PnpService].
class MeshTopologyBuilder {
  MeshTopologyBuilder._();

  /// Converts [DataElementsNetwork] to [MeshTopologyInfo].
  ///
  /// Extracts mesh nodes and builds client MAC → node ID mapping
  /// for determining which mesh node each client device is connected to.
  ///
  /// Set [includeBackhaulStats] to true to include backhaul signal strength
  /// and uplink rate (requires DataElements backhaul stats to be available).
  static MeshTopologyInfo build(
    DataElementsNetwork network, {
    bool includeBackhaulStats = true,
  }) {
    final nodes = <NodeUIModel>[];
    final clientToNodeMap = <String, String>{};

    for (final node in network.items) {
      final rawId = node.id.trim().toUpperCase();
      final nodeDeviceId = rawId.isNotEmpty ? rawId : node.instancePath;

      // Build client MAC → node ID mapping from station list
      for (final radio in node.radios) {
        for (final bss in radio.bssList) {
          for (final sta in bss.stations) {
            final mac = sta.macAddress.trim();
            if (mac.isNotEmpty && nodeDeviceId.isNotEmpty) {
              clientToNodeMap[mac.toUpperCase()] = nodeDeviceId;
            }
          }
        }
      }

      int? backhaulSignalStrength;
      int? backhaulUplinkRate;
      if (includeBackhaulStats) {
        backhaulSignalStrength = rcpiToRssi(node.backhaulStatsSignalStrength);
        if (node.backhaulStatsLastDataUplinkRate > 0) {
          backhaulUplinkRate = node.backhaulStatsLastDataUplinkRate;
        }
      }

      // Master node = no backhaul parent (backhaulAlId is empty)
      final isMaster = node.backhaulAlId.trim().isEmpty;

      // Downlink rate (kbps)
      int? backhaulDownlinkRate;
      if (includeBackhaulStats && node.backhaulStatsLastDataDownlinkRate > 0) {
        backhaulDownlinkRate = node.backhaulStatsLastDataDownlinkRate;
      }

      nodes.add(NodeUIModel(
        deviceId: nodeDeviceId,
        model: node.manufacturerModel.trim(),
        manufacturer: node.manufacturer.trim(),
        serialNumber: node.serialNumber.trim(),
        softwareVersion: node.softwareVersion.trim(),
        isMaster: isMaster,
        backhaulMediaType: node.backhaulMediaType.trim(),
        backhaulPhyRate: node.backhaulPhyRate,
        backhaulSignalStrength: backhaulSignalStrength,
        backhaulUplinkRate: backhaulUplinkRate,
        instancePath: node.instancePath,
        backhaulAlId: node.backhaulAlId.trim(),
        backhaulMacAddress: node.backhaulMacAddress.trim(),
        backhaulLinkType: node.backhaulLinkType.trim().isNotEmpty
            ? node.backhaulLinkType.trim()
            : null,
        backhaulDownlinkRate: backhaulDownlinkRate,
        backhaulParentDeviceId: node.backhaulBackhaulDeviceId.trim().isNotEmpty
            ? node.backhaulBackhaulDeviceId.trim()
            : null,
        backhaulParentBssid: node.backhaulMacAddressMultiAp.trim().isNotEmpty
            ? node.backhaulMacAddressMultiAp.trim()
            : null,
        lastContactTime: node.multiApLastContactTime.trim().isNotEmpty
            ? node.multiApLastContactTime.trim()
            : null,
      ));
    }

    return MeshTopologyInfo(nodes: nodes, clientToNodeMap: clientToNodeMap);
  }
}
