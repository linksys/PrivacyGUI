import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart'
    hide ConnectionType;
import 'package:privacy_gui/page/_shared/models/backhaul_info.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Builds a [MeshTopology] from USP dashboard state for [AppTopology] widget.
///
/// Shared between the dashboard topology card and the full-page topology view.
class UspTopologyBuilder {
  UspTopologyBuilder._();

  /// Builds topology from new [MeshNetwork] architecture.
  ///
  /// Preferred method — uses SSoT container with pre-organized nodes and clients.
  static MeshTopology buildFromMeshNetwork({
    required MeshNetwork meshNetwork,
    required SystemInfoUIModel info,
  }) {
    final nodes = <MeshNode>[];
    final links = <MeshLink>[];

    final master = meshNetwork.master;

    // Gateway node
    const gatewayId = 'gateway';
    final gatewayIconName = routerIconTestByModel(
      modelNumber: master.model.isNotEmpty ? master.model : info.modelName,
      hardwareVersion: info.hardwareVersion,
    );
    nodes.add(MeshNode(
      id: gatewayId,
      identifier: kTopologyMasterIdentifier,
      name:
          master.displayName.isNotEmpty ? master.displayName : info.gatewayName,
      type: MeshNodeType.gateway,
      status: master.isOnline ? MeshNodeStatus.online : MeshNodeStatus.offline,
      image: DeviceImageHelper.getRouterImage(gatewayIconName),
      extra: master.manufacturer.isNotEmpty
          ? master.manufacturer
          : info.manufacturer,
      level: 1.0,
      metadata: {
        'deviceId': master.deviceId,
        'model': master.model.isNotEmpty ? master.model : info.modelName,
        'manufacturer': master.manufacturer.isNotEmpty
            ? master.manufacturer
            : info.manufacturer,
        'serialNumber': master.serialNumber.isNotEmpty
            ? master.serialNumber
            : info.serialNumber,
        'softwareVersion': master.softwareVersion.isNotEmpty
            ? master.softwareVersion
            : info.softwareVersion,
        'isMaster': true,
      },
    ));

    // Build extender ID lookup maps.
    // Normalized set (no colons, uppercase) for matching against parentNodeId
    // which comes from DataElements clientToNodeMap (no colons).
    // We add BOTH deviceId (from Hosts) and dataElementsId (from DataElements)
    // since they may be different MAC addresses for the same node.
    logger.t('[USP][TopologyBuilder]: hasMesh=${meshNetwork.hasMesh}, '
        'slaveNodes=${meshNetwork.slaves.length}, '
        'slaveDeviceIds=${meshNetwork.slaves.map((n) => '${n.deviceId}|DE:${n.dataElementsId}').toList()}');
    final extenderNodeIdsNormalized = <String>{};
    final normalizedToOriginal = <String, String>{};
    final deviceIdToExtenderId = <String, String>{};

    for (final slave in meshNetwork.slaves) {
      final extenderId = 'extender-${slave.deviceId}';
      final normalizedHostsMac =
          slave.deviceId.toUpperCase().replaceAll(':', '');
      extenderNodeIdsNormalized.add(normalizedHostsMac);
      normalizedToOriginal[normalizedHostsMac] = slave.deviceId;
      deviceIdToExtenderId[normalizedHostsMac] = extenderId;

      if (slave.dataElementsId != null && slave.dataElementsId!.isNotEmpty) {
        final normalizedDeMac =
            slave.dataElementsId!.toUpperCase().replaceAll(':', '');
        if (normalizedDeMac != normalizedHostsMac) {
          extenderNodeIdsNormalized.add(normalizedDeMac);
          normalizedToOriginal[normalizedDeMac] = slave.deviceId;
          deviceIdToExtenderId[normalizedDeMac] = extenderId;
        }
      }
      logger.t('[USP][TopologyBuilder]: Slave ${slave.deviceId} '
          '→ hostsMac: $normalizedHostsMac, '
          'dataElementsId: ${slave.dataElementsId}, '
          'backhaulParentDeviceId: ${slave.backhaul.parentNodeId}');
    }

    // Stable, data-derived E2E identifier keys (Article XVI §16.3): shortest
    // MAC suffix that stays unique within each node group, independent of the
    // display label / node order.
    final slaveIdKeys =
        shortestUniqueMacSuffixes(meshNetwork.slaves.map((s) => s.deviceId));

    // Slave nodes
    for (final slave in meshNetwork.slaves) {
      final extenderId = 'extender-${slave.deviceId}';

      // Resolve parent
      String parentId = gatewayId;
      final parentDeviceId = slave.backhaul.parentNodeId;
      if (parentDeviceId != null && parentDeviceId.isNotEmpty) {
        final normalizedParentId =
            parentDeviceId.toUpperCase().replaceAll(':', '');
        parentId = deviceIdToExtenderId[normalizedParentId] ?? gatewayId;
      }

      final extenderIconName = routerIconTestByModel(modelNumber: slave.model);
      nodes.add(MeshNode(
        id: extenderId,
        identifier: topologySlaveIdentifier(slaveIdKeys[slave.deviceId] ?? ''),
        name: slave.displayName,
        type: MeshNodeType.extender,
        status: slave.isOnline ? MeshNodeStatus.online : MeshNodeStatus.offline,
        parentId: parentId,
        image: DeviceImageHelper.getRouterImage(extenderIconName),
        level: _backhaulLevel(slave.backhaul),
        metadata: {
          'deviceId': slave.deviceId,
          'model': slave.model,
          'manufacturer': slave.manufacturer,
          'serialNumber': slave.serialNumber,
          'softwareVersion': slave.softwareVersion,
          'isMaster': false,
          'backhaulLinkType': slave.backhaul.linkType,
          'backhaulParentDeviceId': slave.backhaul.parentNodeId,
          'backhaulSignalStrength': slave.backhaul.signalStrength,
          'backhaulUplinkRate': slave.backhaul.uplinkRate,
          'backhaulDownlinkRate': slave.backhaul.downlinkRate,
          'lastContactTime': slave.backhaul.lastContactTime,
        },
      ));

      links.add(MeshLink(
        sourceId: parentId,
        targetId: extenderId,
        // An absent backhaul (`!hasInfo`) is neither Ethernet nor Wi-Fi, but
        // ui_kit's `ConnectionType` has only those two members and
        // `MeshLink.connectionType` is non-nullable, so one of them must be
        // claimed. `wifi` is the lesser claim of the two: the tree view never
        // reads `connectionType` (it styles purely from `linkQuality`, see
        // `topology_tree_view.dart`'s `linkStyleFor(item.link!.linkQuality)`),
        // and the graph view routes a non-Ethernet link through
        // `linkStyleFor(link.linkQuality)` too — so `unknown` below lands both
        // views on the neutral `wifiUnknownStyle`. Picking `ethernet` instead
        // would hard-wire `ethernetLinkStyle` and assert a wired backhaul.
        //
        // The one residue is that `wifiUnknownStyle.animationType` is
        // `LinkAnimationType.flow`, so the graph view animates traffic along a
        // link we know nothing about. That cannot be suppressed from here —
        // `MeshLink` carries no per-link style or animation override — so it
        // needs `ConnectionType.unknown` plus a non-animating `LinkStyle` in
        // ui_kit: tracked as `linksys/privacyGUI-UI-kit#87` (verified still
        // open against v3.1.0). Do not hand-roll a link widget here
        // (constitution Article XV).
        connectionType: slave.backhaul.isEthernet
            ? ConnectionType.ethernet
            : ConnectionType.wifi,
        rssi: slave.backhaul.signalStrength,
        // Never derived from `connectionType`: an absent backhaul has no RSSI,
        // so this resolves to `unknown` and both views fall back to the neutral
        // style rather than painting a signal grade that was never measured.
        linkQuality: _rssiToLinkQuality(slave.backhaul.signalStrength),
        throughput: slave.backhaul.uplinkRate != null
            ? slave.backhaul.uplinkRate! / 1000.0
            : null,
      ));
    }

    // Client devices — use allClients which includes master + slave clients
    final clientIdKeys =
        shortestUniqueMacSuffixes(meshNetwork.allClients.map((c) => c.mac));
    for (final client in meshNetwork.allClients) {
      final clientId = 'client-${client.mac}';
      final isEthernet = !client.isWifi;

      // Determine parent node
      String parentId = gatewayId;
      if (meshNetwork.hasMesh && client.parentNodeId != null) {
        final parentNormalized =
            client.parentNodeId!.toUpperCase().replaceAll(':', '');
        logger.t('[USP][TopologyBuilder]: Device ${client.displayName} '
            'parentNodeId=${client.parentNodeId}, '
            'normalized=$parentNormalized, '
            'inExtenders=${extenderNodeIdsNormalized.contains(parentNormalized)}');
        if (extenderNodeIdsNormalized.contains(parentNormalized)) {
          final originalDeviceId = normalizedToOriginal[parentNormalized]!;
          parentId = 'extender-$originalDeviceId';
        }
      } else {
        logger.t('[USP][TopologyBuilder]: Device ${client.displayName} '
            'hasMesh=${meshNetwork.hasMesh}, '
            'parentNodeId=${client.parentNodeId} → gateway');
      }

      final category = DeviceClassifier.classify(
        hostname: client.displayName,
        mac: client.mac,
      );

      nodes.add(MeshNode(
        id: clientId,
        identifier: topologyClientIdentifier(clientIdKeys[client.mac] ?? ''),
        name: client.displayName,
        type: MeshNodeType.client,
        status:
            client.isOnline ? MeshNodeStatus.online : MeshNodeStatus.offline,
        parentId: parentId,
        iconData: category.icon,
        extra: client.ip,
        linkQuality: _resolveLinkQualityForClient(client),
        level: _rssiToLevelForClient(client),
        metadata: {
          'mac': client.mac,
          'hasMultipleInterfaces': client.hasMultipleInterfaces,
          'interfaceCount': client.interfaceCount,
          'allMacAddresses': client.allMacAddresses,
        },
      ));

      links.add(MeshLink(
        sourceId: parentId,
        targetId: clientId,
        connectionType:
            isEthernet ? ConnectionType.ethernet : ConnectionType.wifi,
        rssi: client.signalStrength,
        linkQuality: isEthernet
            ? LinkQuality.stable
            : _rssiToLinkQuality(client.signalStrength),
        throughput: (client.downlinkRate ?? 0) + (client.uplinkRate ?? 0) > 0
            ? ((client.downlinkRate ?? 0) + (client.uplinkRate ?? 0)) / 1000.0
            : null,
        distanceFactor: _rssiToDistanceFactor(client.signalStrength),
      ));
    }

    return MeshTopology(
      nodes: nodes,
      links: links,
      lastUpdated: DateTime.now(),
    );
  }

  static double _rssiToLevelForClient(ClientDevice client) {
    if (!client.isWifi) return 1.0;
    return _rssiValueToLevel(client.signalStrength);
  }

  static LinkQuality _resolveLinkQualityForClient(ClientDevice client) {
    if (!client.isWifi) return LinkQuality.stable;
    return _rssiToLinkQuality(client.signalStrength);
  }

  /// Converts a slave node's backhaul to a display level.
  ///
  /// - Ethernet backhaul: full level (1.0), matching how wired links are shown
  ///   elsewhere — a wired connection has no RSSI by design, not by absence.
  /// - No backhaul data at all (e.g. an offline node with no DataElements
  ///   match): 0.0 — no signal, not a fabricated mid-strength 0.5 that looks
  ///   like a real reading (#1430, AC4).
  /// - Wi-Fi backhaul with an RSSI: the RSSI-derived level.
  /// - Wi-Fi backhaul whose stats are missing (`BackhaulStats` absent, or an
  ///   RCPI of `0` that [rcpiToRssi] maps to null): the neutral 0.5. The node is
  ///   up and its backhaul is real — only the reading is missing, so 0.0 would
  ///   paint a healthy node as dead. AC4's "no 0.5" applies to an *absent*
  ///   backhaul, which is the first case above. A truthful third state needs a
  ///   nullable level in the ui_kit `MeshNode` (`level` is a non-nullable
  ///   `double`), so this is the least-wrong value the current API allows.
  ///
  /// `isEthernet` is tested **before** `hasInfo`, and the order is load-bearing:
  /// the two read different fields (`linkType` and `mediaType`) and nothing
  /// couples them, so `linkType:'Ethernet'` with an empty `mediaType` is
  /// representable. Checking `hasInfo` first painted that node at 0.0 — dead —
  /// while the `connectionType` above and the node-detail card's arm chain both
  /// resolve `isEthernet` first and call it Ethernet. Same node, same fields,
  /// three answers. All three sites now agree that a positive `linkType` wins.
  static double _backhaulLevel(BackhaulInfo backhaul) {
    if (backhaul.isEthernet) return 1.0;
    if (!backhaul.hasInfo) return 0.0;
    if (backhaul.signalStrength == null) return 0.5;
    return _rssiValueToLevel(backhaul.signalStrength);
  }

  /// Common RSSI to level conversion. Uses [getWifiSignalLevel] as the single
  /// source of truth for RSSI thresholds.
  static double _rssiValueToLevel(int? rssi) {
    if (rssi == null) return 0.0;
    return switch (getWifiSignalLevel(rssi)) {
      NodeSignalLevel.excellent => 0.9,
      NodeSignalLevel.good => 0.65,
      NodeSignalLevel.fair => 0.4,
      NodeSignalLevel.poor => 0.1,
      NodeSignalLevel.none => 0.0,
      NodeSignalLevel.wired => 1.0,
    };
  }

  /// Converts RSSI to LinkQuality using wifi.dart thresholds.
  ///
  /// Maps [NodeSignalLevel] 1:1 to [LinkQuality] for consistency with
  /// [UspSignalStrengthIndicator] and other signal displays.
  ///
  /// Thresholds from [signalThresholdRSSI]: [-65, -71, -78]
  /// - >= -65: excellent
  /// - >= -71: good
  /// - >= -78: fair
  /// - < -78: poor (unknown in LinkQuality)
  static LinkQuality _rssiToLinkQuality(int? rssi) {
    if (rssi == null) return LinkQuality.unknown;
    final level = getWifiSignalLevel(rssi);
    return switch (level) {
      NodeSignalLevel.excellent => LinkQuality.excellent,
      NodeSignalLevel.good => LinkQuality.good,
      NodeSignalLevel.fair => LinkQuality.fair,
      NodeSignalLevel.poor => LinkQuality.unknown,
      NodeSignalLevel.none => LinkQuality.unknown,
      NodeSignalLevel.wired => LinkQuality.stable,
    };
  }

  /// Maps RSSI (dBm) to normalized distance factor [0.0, 1.0].
  static double? _rssiToDistanceFactor(int? rssi) {
    if (rssi == null) return null;
    final clamped = rssi.clamp(-90, -50);
    return (clamped - (-50)).abs() / 40.0;
  }
}
