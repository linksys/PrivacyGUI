import 'package:flutter/material.dart';
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
    Color? coverageColor,
    double coverageRingScale = 1.0,
  }) {
    final nodes = <MeshNode>[];
    final links = <MeshLink>[];

    // Find master node from nodeModels
    final masterNode = nodeModels.where((n) => n.isMaster).firstOrNull;

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
      coverageRings: coverageColor != null
          ? _buildCoverageRings(
              MeshNodeType.gateway, coverageColor, coverageRingScale)
          : null,
    ));

    // Mesh extender nodes (slave nodes)
    final slaveNodes = nodeModels.where((n) => !n.isMaster).toList();
    final hasMesh = slaveNodes.isNotEmpty;
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
        coverageRings: coverageColor != null
            ? _buildCoverageRings(
                MeshNodeType.extender, coverageColor, coverageRingScale)
            : null,
      ));

      links.add(MeshLink(
        sourceId: gatewayId,
        targetId: extenderId,
        connectionType: ConnectionType.wifi,
        rssi: slaveNode.backhaulSignalStrength,
        signalQuality: _rssiToSignalQuality(slaveNode.backhaulSignalStrength),
        throughput: slaveNode.backhaulUplinkRate != null
            ? slaveNode.backhaulUplinkRate! / 1000.0
            : null,
      ));
    }

    // Client nodes from DeviceUIModel (excluding mesh nodes)
    for (final device in devices) {
      // Skip devices that are mesh nodes (master/slave) — already rendered
      // as gateway or extenders. Only show "client" role devices.
      if (device.deviceRole == 'master' || device.deviceRole == 'slave') {
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
        signalQuality: _resolveSignalQuality(device),
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
        signalQuality: isEthernet
            ? SignalQuality.wired
            : _rssiToSignalQuality(device.signalStrength),
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

  static SignalQuality _resolveSignalQuality(DeviceUIModel device) {
    if (!device.isWifi) return SignalQuality.wired;
    return _rssiToSignalQuality(device.signalStrength);
  }

  /// Converts RSSI to SignalQuality using wifi.dart thresholds.
  ///
  /// Thresholds from [signalThresholdRSSI]: [-65, -71, -78]
  /// - >= -65: excellent/strong
  /// - >= -71: good/medium
  /// - >= -78: fair/medium
  /// - < -78: poor/weak
  static SignalQuality _rssiToSignalQuality(int? rssi) {
    if (rssi == null) return SignalQuality.unknown;
    final level = getWifiSignalLevel(rssi);
    return switch (level) {
      NodeSignalLevel.excellent => SignalQuality.strong,
      NodeSignalLevel.good => SignalQuality.strong,
      NodeSignalLevel.fair => SignalQuality.medium,
      NodeSignalLevel.poor => SignalQuality.weak,
      NodeSignalLevel.none => SignalQuality.unknown,
      NodeSignalLevel.wired => SignalQuality.wired,
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

  /// Builds coverage rings for infrastructure nodes (gateway / extender).
  ///
  /// [scale] shrinks rings for compact contexts (e.g. dashboard card).
  static List<NodeCoverageRing> _buildCoverageRings(
    MeshNodeType type,
    Color color,
    double scale,
  ) {
    // Ring radii: inner gradient ring + outer dashed ring
    // Tuned to not clip while providing clear visual separation
    final (innerR, outerR, innerOp, outerOp) = switch (type) {
      MeshNodeType.gateway => (90.0 * scale, 160.0 * scale, 0.16, 0.10),
      MeshNodeType.extender => (70.0 * scale, 120.0 * scale, 0.14, 0.09),
      _ => (0.0, 0.0, 0.0, 0.0),
    };
    if (innerR == 0) return [];
    return [
      NodeCoverageRing(
        radius: innerR,
        color: color,
        opacity: innerOp,
        style: CoverageRingStyle.gradient,
      ),
      NodeCoverageRing(
        radius: outerR,
        color: color,
        opacity: outerOp,
        style: CoverageRingStyle.dashed,
        strokeWidth: 2.0,
      ),
    ];
  }
}
