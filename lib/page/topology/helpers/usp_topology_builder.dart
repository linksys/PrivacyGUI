import 'package:privacy_gui/core/utils/device_classifier.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
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
    final extenderNodeIds = <String>{};
    for (final slaveNode in slaveNodes) {
      final extenderId = 'extender-${slaveNode.deviceId}';
      extenderNodeIds.add(slaveNode.deviceId);

      final extenderIconName = routerIconTestByModel(
        modelNumber: slaveNode.model,
      );
      nodes.add(MeshNode(
        id: extenderId,
        name: slaveNode.displayName,
        type: MeshNodeType.extender,
        status: MeshNodeStatus.online,
        parentId: gatewayId,
        image: DeviceImageHelper.getRouterImage(extenderIconName),
        level: _backhaulRssiToLevel(slaveNode.backhaulSignalStrength),
        metadata: {
          'deviceId': slaveNode.deviceId,
          'model': slaveNode.model,
          'manufacturer': slaveNode.manufacturer,
          'serialNumber': slaveNode.serialNumber,
          'softwareVersion': slaveNode.softwareVersion,
          'isMaster': false,
        },
      ));

      links.add(MeshLink(
        sourceId: gatewayId,
        targetId: extenderId,
        connectionType: ConnectionType.wifi,
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

      // Determine parent: use parentNodeId from UI Model
      String parentId = gatewayId;
      if (hasMesh && device.parentNodeId != null) {
        if (extenderNodeIds.contains(device.parentNodeId)) {
          parentId = 'extender-${device.parentNodeId}';
        }
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

  /// Common RSSI to level conversion.
  static double _rssiValueToLevel(int? rssi) {
    if (rssi == null) return 0.0;
    if (rssi >= -50) return 0.9;
    if (rssi >= -60) return 0.65;
    if (rssi >= -70) return 0.4;
    return 0.1;
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
  /// Strong signal (>= -45) → close (0.0), Weak signal (<= -75) → far (1.0).
  /// Ethernet (null RSSI) → null (use default spacing).
  static double? _rssiToDistanceFactor(int? rssi) {
    if (rssi == null) return null;
    final clamped = rssi.clamp(-75, -45);
    return (clamped - (-45)).abs() / 30.0;
  }
}
