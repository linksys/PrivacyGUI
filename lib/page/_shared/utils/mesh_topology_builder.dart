import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
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
  /// [bssidToBandMap] is optional mapping of BSSID (uppercase) → band string
  /// (e.g., "2.4GHz", "5GHz"). When provided, allows extracting band info
  /// for clients connected to any node (including slave nodes).
  ///
  /// Set [includeBackhaulStats] to true to include backhaul signal strength
  /// and uplink rate (requires DataElements backhaul stats to be available).
  static MeshTopologyInfo build(
    DataElementsNetwork network, {
    Map<String, String> bssidToBandMap = const {},
    bool includeBackhaulStats = true,
  }) {
    final nodes = <NodeEntity>[];
    final clientToNodeMap = <String, String>{};
    final clientSignalMap = <String, int>{};
    final clientBandSsidMap = <String, ({String band, String ssid})>{};

    for (final node in network.items) {
      final rawId = node.id.trim().toUpperCase();
      final nodeDeviceId = rawId.isNotEmpty ? rawId : node.instancePath;

      // Build client MAC → node ID mapping, signal strength, and band/SSID
      for (final radio in node.radios) {
        for (final bss in radio.bssList) {
          // Resolve band from BSSID → band mapping
          final bssidUpper = bss.bssid.trim().toUpperCase();
          final band = bssidToBandMap[bssidUpper] ?? '';
          final ssid = bss.ssid.trim();

          for (final sta in bss.stations) {
            final mac = sta.macAddress.trim();
            if (mac.isNotEmpty && nodeDeviceId.isNotEmpty) {
              final upperMac = mac.toUpperCase();
              clientToNodeMap[upperMac] = nodeDeviceId;
              // DataElements STA.SignalStrength is RCPI (0-220), convert to RSSI
              final rssi = rcpiToRssi(sta.signalStrength);
              if (rssi != null) {
                clientSignalMap[upperMac] = rssi;
              }
              // Store band + SSID for this client
              if (band.isNotEmpty || ssid.isNotEmpty) {
                clientBandSsidMap[upperMac] = (band: band, ssid: ssid);
              }
            }
          }
        }
      }

      int? backhaulSignalStrength;
      int? backhaulUplinkRate;
      int? backhaulDownlinkRate;
      if (includeBackhaulStats) {
        backhaulSignalStrength = rcpiToRssi(node.backhaulStatsSignalStrength);
        if (node.backhaulStatsLastDataUplinkRate > 0) {
          backhaulUplinkRate = node.backhaulStatsLastDataUplinkRate;
        }
        if (node.backhaulStatsLastDataDownlinkRate > 0) {
          backhaulDownlinkRate = node.backhaulStatsLastDataDownlinkRate;
        }
      }

      // Master node = no backhaul parent (backhaulAlId is empty)
      final isMaster = node.backhaulAlId.trim().isEmpty;

      if (isMaster) {
        nodes.add(MasterNode(
          deviceId: nodeDeviceId,
          model: node.manufacturerModel.trim(),
          manufacturer: node.manufacturer.trim(),
          serialNumber: node.serialNumber.trim(),
          softwareVersion: node.softwareVersion.trim(),
          instancePath: node.instancePath,
        ));
      } else {
        nodes.add(SlaveNode(
          deviceId: nodeDeviceId,
          model: node.manufacturerModel.trim(),
          manufacturer: node.manufacturer.trim(),
          serialNumber: node.serialNumber.trim(),
          softwareVersion: node.softwareVersion.trim(),
          instancePath: node.instancePath,
          backhaul: BackhaulInfo(
            mediaType: node.backhaulMediaType.trim(),
            linkType: node.backhaulLinkType.trim().isNotEmpty
                ? node.backhaulLinkType.trim()
                : null,
            phyRate: node.backhaulPhyRate,
            signalStrength: backhaulSignalStrength,
            uplinkRate: backhaulUplinkRate,
            downlinkRate: backhaulDownlinkRate,
            parentNodeId: node.backhaulBackhaulDeviceId.trim().isNotEmpty
                ? node.backhaulBackhaulDeviceId.trim()
                : null,
            parentBssid: node.backhaulMacAddressMultiAp.trim().isNotEmpty
                ? node.backhaulMacAddressMultiAp.trim()
                : null,
            lastContactTime: node.multiApLastContactTime.trim().isNotEmpty
                ? node.multiApLastContactTime.trim()
                : null,
            backhaulAlId: node.backhaulAlId.trim(),
            backhaulMacAddress: node.backhaulMacAddress.trim(),
          ),
        ));
      }
    }

    return MeshTopologyInfo(
      nodes: nodes,
      clientToNodeMap: clientToNodeMap,
      clientSignalMap: clientSignalMap,
      clientBandSsidMap: clientBandSsidMap,
    );
  }
}
