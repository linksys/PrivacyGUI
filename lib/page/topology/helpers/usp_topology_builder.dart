import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Builds a [MeshTopology] from USP dashboard state for [AppTopology] widget.
///
/// Shared between the dashboard topology card and the full-page topology view.
class UspTopologyBuilder {
  UspTopologyBuilder._();

  static MeshTopology build({
    required SystemInfoUIModel info,
    required List<DeviceUIModel> devices,
    required List<NodeUIModel> nodeModels,
  }) {
    final nodes = <MeshNode>[];
    final links = <MeshLink>[];

    // Find master node from nodeModels
    final masterNode = nodeModels.master;

    // Gateway node (the router)
    const gatewayId = 'gateway';
    // Use master node's deviceId (MAC) for navigation, fallback to 'gateway'
    final gatewayDeviceId = masterNode?.deviceId ?? 'gateway';

    final gatewayIconName = routerIconTestByModel(
      modelNumber: info.modelName,
      hardwareVersion: info.hardwareVersion,
    );
    nodes.add(MeshNode(
      id: gatewayId,
      name: masterNode?.displayName ?? info.gatewayName,
      type: MeshNodeType.gateway,
      status: MeshNodeStatus.online,
      image: DeviceImageHelper.getRouterImage(gatewayIconName),
      extra: info.manufacturer,
      level: 1.0,
      metadata: {
        'deviceId': gatewayDeviceId,
        'model': masterNode?.model ?? info.modelName,
        'manufacturer': masterNode?.manufacturer ?? info.manufacturer,
        'serialNumber': masterNode?.serialNumber ?? info.serialNumber,
        'softwareVersion': masterNode?.softwareVersion ?? info.softwareVersion,
        'isMaster': true,
      },
    ));

    // Mesh extender nodes (slave nodes)
    final slaveNodes = nodeModels.slaves;
    final hasMesh = nodeModels.hasMesh;
    logger.t('[USP][TopologyBuilder]: hasMesh=$hasMesh, '
        'slaveNodes=${slaveNodes.length}, '
        'slaveDeviceIds=${slaveNodes.map((n) => '${n.deviceId}|DE:${n.dataElementsId}').toList()}');
    // Normalized set (no colons, uppercase) for matching against parentNodeId
    // which comes from DataElements clientToNodeMap (no colons).
    // We add BOTH deviceId (from Hosts) and dataElementsId (from DataElements)
    // since they may be different MAC addresses for the same node.
    final extenderNodeIdsNormalized = <String>{};
    // Map from normalized ID back to original deviceId for building 'extender-X' IDs.
    final normalizedToOriginal = <String, String>{};
    // Map from normalized Device ID to extender node ID (for parent resolution)
    final deviceIdToExtenderId = <String, String>{};

    for (final slaveNode in slaveNodes) {
      final extenderId = 'extender-${slaveNode.deviceId}';
      // Add Hosts MAC (deviceId)
      final normalizedHostsMac =
          slaveNode.deviceId.toUpperCase().replaceAll(':', '');
      extenderNodeIdsNormalized.add(normalizedHostsMac);
      normalizedToOriginal[normalizedHostsMac] = slaveNode.deviceId;
      deviceIdToExtenderId[normalizedHostsMac] = extenderId;
      // Also add DataElements ID if different (may be a different interface MAC)
      if (slaveNode.dataElementsId != null &&
          slaveNode.dataElementsId!.isNotEmpty) {
        final normalizedDeMac =
            slaveNode.dataElementsId!.toUpperCase().replaceAll(':', '');
        if (normalizedDeMac != normalizedHostsMac) {
          extenderNodeIdsNormalized.add(normalizedDeMac);
          normalizedToOriginal[normalizedDeMac] = slaveNode.deviceId;
          deviceIdToExtenderId[normalizedDeMac] = extenderId;
        }
      }
      logger.t('[USP][TopologyBuilder]: Slave ${slaveNode.deviceId} '
          '→ hostsMac: $normalizedHostsMac, '
          'dataElementsId: ${slaveNode.dataElementsId}, '
          'backhaulParentDeviceId: ${slaveNode.backhaulParentDeviceId}');
    }

    // Helper to resolve slave parent ID using backhaulParentDeviceId
    String resolveSlaveParentId(NodeUIModel slaveNode) {
      final parentDeviceId = slaveNode.backhaulParentDeviceId;
      if (parentDeviceId == null || parentDeviceId.isEmpty) {
        return gatewayId;
      }
      final normalizedParentId =
          parentDeviceId.toUpperCase().replaceAll(':', '');
      return deviceIdToExtenderId[normalizedParentId] ?? gatewayId;
    }

    // Build extender nodes and links
    for (final slaveNode in slaveNodes) {
      final extenderId = 'extender-${slaveNode.deviceId}';
      final parentId = resolveSlaveParentId(slaveNode);

      final extenderIconName = routerIconTestByModel(
        modelNumber: slaveNode.model,
      );
      nodes.add(MeshNode(
        id: extenderId,
        name: slaveNode.displayName,
        type: MeshNodeType.extender,
        status: MeshNodeStatus.online,
        parentId: parentId,
        image: DeviceImageHelper.getRouterImage(extenderIconName),
        level: _backhaulRssiToLevel(slaveNode.backhaulSignalStrength),
        metadata: {
          'deviceId': slaveNode.deviceId,
          'model': slaveNode.model,
          'manufacturer': slaveNode.manufacturer,
          'serialNumber': slaveNode.serialNumber,
          'softwareVersion': slaveNode.softwareVersion,
          'isMaster': false,
          'backhaulLinkType': slaveNode.backhaulLinkType,
          'backhaulParentDeviceId': slaveNode.backhaulParentDeviceId,
          'backhaulSignalStrength': slaveNode.backhaulSignalStrength,
          'backhaulUplinkRate': slaveNode.backhaulUplinkRate,
          'backhaulDownlinkRate': slaveNode.backhaulDownlinkRate,
          'lastContactTime': slaveNode.lastContactTime,
        },
      ));

      links.add(MeshLink(
        sourceId: parentId,
        targetId: extenderId,
        connectionType: slaveNode.backhaulLinkType == 'Ethernet'
            ? ConnectionType.ethernet
            : ConnectionType.wifi,
        rssi: slaveNode.backhaulSignalStrength,
        linkQuality: _rssiToLinkQuality(slaveNode.backhaulSignalStrength),
        throughput: slaveNode.backhaulUplinkRate != null
            ? slaveNode.backhaulUplinkRate! / 1000.0
            : null,
      ));
    }

    // Client nodes from DeviceUIModel (excluding mesh nodes)
    for (final device in devices) {
      // Skip devices that are mesh nodes (master/slave) — already rendered
      // as gateway or extenders. Only show "client" role devices.
      if (device.isMeshNode) {
        continue;
      }

      final clientId = 'client-${device.mac}';
      final isEthernet = !device.isWifi;

      // Determine parent: use parentNodeId from UI Model.
      // parentNodeId comes from DataElements clientToNodeMap (no colons),
      // so we normalize it before matching against extenderNodeIdsNormalized.
      String parentId = gatewayId;
      if (hasMesh && device.parentNodeId != null) {
        final parentNormalized =
            device.parentNodeId!.toUpperCase().replaceAll(':', '');
        logger.t('[USP][TopologyBuilder]: Device ${device.displayName} '
            'parentNodeId=${device.parentNodeId}, '
            'normalized=$parentNormalized, '
            'inExtenders=${extenderNodeIdsNormalized.contains(parentNormalized)}');
        if (extenderNodeIdsNormalized.contains(parentNormalized)) {
          final originalDeviceId = normalizedToOriginal[parentNormalized]!;
          parentId = 'extender-$originalDeviceId';
        }
      } else {
        logger.t('[USP][TopologyBuilder]: Device ${device.displayName} '
            'hasMesh=$hasMesh, parentNodeId=${device.parentNodeId} → gateway');
      }

      // Classify device for icon
      final category = DeviceClassifier.classify(
        hostname: device.displayName,
        mac: device.mac,
      );

      nodes.add(MeshNode(
        id: clientId,
        name: device.displayName,
        type: MeshNodeType.client,
        status:
            device.isActive ? MeshNodeStatus.online : MeshNodeStatus.offline,
        parentId: parentId,
        iconData: category.icon,
        extra: device.ip,
        linkQuality: _resolveLinkQuality(device),
        level: _rssiToLevel(device),
        metadata: {
          'mac': device.mac,
          'hasMultipleInterfaces': device.hasMultipleInterfaces,
          'interfaceCount': device.interfaceCount,
          'allMacAddresses': device.allMacAddresses,
        },
      ));

      links.add(MeshLink(
        sourceId: parentId,
        targetId: clientId,
        connectionType:
            isEthernet ? ConnectionType.ethernet : ConnectionType.wifi,
        rssi: device.signalStrength,
        linkQuality: isEthernet
            ? LinkQuality.stable
            : _rssiToLinkQuality(device.signalStrength),
        throughput:
            device.totalThroughput > 0 ? device.totalThroughput / 1000.0 : null,
        distanceFactor: _rssiToDistanceFactor(device.signalStrength),
      ));
    }

    return MeshTopology(
      nodes: nodes,
      links: links,
      lastUpdated: DateTime.now(),
    );
  }

  static double _rssiToLevel(DeviceUIModel device) {
    if (!device.isWifi) return 1.0;
    return _rssiValueToLevel(device.signalStrength);
  }

  /// Converts backhaul RSSI to level for extender nodes.
  static double _backhaulRssiToLevel(int? rssi) {
    if (rssi == null) return 0.5; // Default when no data
    return _rssiValueToLevel(rssi);
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

  static LinkQuality _resolveLinkQuality(DeviceUIModel device) {
    if (!device.isWifi) return LinkQuality.stable;
    return _rssiToLinkQuality(device.signalStrength);
  }

  /// Converts RSSI to LinkQuality using wifi.dart thresholds.
  ///
  /// Thresholds from [signalThresholdRSSI]: [-65, -71, -78]
  /// - >= -65: excellent/strong
  /// - >= -71: good/medium
  /// - >= -78: fair/medium
  /// - < -78: poor/weak
  static LinkQuality _rssiToLinkQuality(int? rssi) {
    if (rssi == null) return LinkQuality.unknown;
    final level = getWifiSignalLevel(rssi);
    return switch (level) {
      NodeSignalLevel.excellent => LinkQuality.excellent,
      NodeSignalLevel.good => LinkQuality.excellent,
      NodeSignalLevel.fair => LinkQuality.good,
      NodeSignalLevel.poor => LinkQuality.fair,
      NodeSignalLevel.none => LinkQuality.unknown,
      NodeSignalLevel.wired => LinkQuality.stable,
    };
  }

  /// Maps RSSI (dBm) to normalized distance factor [0.0, 1.0].
  ///
  /// Aligned with [signalThresholdRSSI] from wifi.dart: [-65, -71, -78]
  /// - >= -65 (excellent): close (0.0 - 0.25)
  /// - >= -78 (fair): medium (0.25 - 0.75)
  /// - < -78 (poor): far (0.75 - 1.0)
  ///
  /// Ethernet (null RSSI) → null (use default spacing).
  static double? _rssiToDistanceFactor(int? rssi) {
    if (rssi == null) return null;
    // Range: -90 (far) to -50 (close)
    final clamped = rssi.clamp(-90, -50);
    return (clamped - (-50)).abs() / 40.0;
  }
}
