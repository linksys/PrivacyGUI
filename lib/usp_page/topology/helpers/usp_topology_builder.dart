import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/usp_page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/providers/mesh_node_enricher.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Builds a [MeshTopology] from USP dashboard state for [AppTopology] widget.
///
/// Shared between the dashboard topology card and the full-page topology view.
class UspTopologyBuilder {
  UspTopologyBuilder._();

  static MeshTopology build({
    required SystemInfoUIModel info,
    required List<DeviceUIModel> devices,
    required List<MeshNodeInfo> meshNodes,
    Color? coverageColor,
  }) {
    final nodes = <MeshNode>[];
    final links = <MeshLink>[];

    // Gateway node (the router)
    const gatewayId = 'gateway';
    // For non-mesh (DataElements empty/unsupported), use 'gateway' as a
    // synthetic identifier so the Detail button can still navigate.
    final gatewayDeviceId =
        meshNodes.isNotEmpty ? meshNodes.first.deviceId : 'gateway';

    final gatewayIconName = routerIconTestByModel(
      modelNumber: info.modelName,
      hardwareVersion: info.hardwareVersion,
    );
    nodes.add(MeshNode(
      id: gatewayId,
      name: info.gatewayName,
      type: MeshNodeType.gateway,
      status: MeshNodeStatus.online,
      image: DeviceImageHelper.getRouterImage(gatewayIconName),
      extra: info.manufacturer,
      level: 1.0,
      metadata: {'deviceId': gatewayDeviceId},
      coverageRings: coverageColor != null
          ? _buildCoverageRings(MeshNodeType.gateway, coverageColor)
          : null,
    ));

    // Mesh extender nodes (if > 1 node, first is gateway)
    final hasMesh = meshNodes.length > 1;
    final extenderNodeIds = <String>{};
    if (hasMesh) {
      for (var i = 1; i < meshNodes.length; i++) {
        final meshNode = meshNodes[i];
        final extenderId = 'extender-${meshNode.deviceId}';
        extenderNodeIds.add(meshNode.deviceId);

        final extenderIconName = routerIconTestByModel(
          modelNumber: meshNode.model,
        );
        nodes.add(MeshNode(
          id: extenderId,
          name: meshNode.model.isNotEmpty
              ? meshNode.model
              : 'Extender ${meshNode.deviceId}',
          type: MeshNodeType.extender,
          status: MeshNodeStatus.online,
          parentId: gatewayId,
          image: DeviceImageHelper.getRouterImage(extenderIconName),
          level: 0.8,
          metadata: {'deviceId': meshNode.deviceId},
          coverageRings: coverageColor != null
              ? _buildCoverageRings(MeshNodeType.extender, coverageColor)
              : null,
        ));

        links.add(MeshLink(
          sourceId: gatewayId,
          targetId: extenderId,
          connectionType: ConnectionType.wifi,
        ));
      }
    }

    // Client nodes from DeviceUIModel
    for (final device in devices) {
      final clientId = 'client-${device.mac}';
      final isEthernet = !device.isWifi;

      // Determine parent: use parentNodeId from UI Model
      String parentId = gatewayId;
      if (hasMesh && device.parentNodeId != null) {
        if (extenderNodeIds.contains(device.parentNodeId)) {
          parentId = 'extender-${device.parentNodeId}';
        }
      }

      nodes.add(MeshNode(
        id: clientId,
        name: device.displayName,
        type: MeshNodeType.client,
        status:
            device.isActive ? MeshNodeStatus.online : MeshNodeStatus.offline,
        parentId: parentId,
        iconData: isEthernet ? Icons.settings_ethernet : Icons.wifi,
        extra: device.ip,
        signalQuality: _resolveSignalQuality(device),
        level: _rssiToLevel(device),
        metadata: {'mac': device.mac},
      ));

      links.add(MeshLink(
        sourceId: parentId,
        targetId: clientId,
        connectionType:
            isEthernet ? ConnectionType.ethernet : ConnectionType.wifi,
        rssi: device.signalStrength,
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
    final rssi = device.signalStrength;
    if (rssi == null) return 0.0;
    if (rssi >= -50) return 0.9;
    if (rssi >= -60) return 0.65;
    if (rssi >= -70) return 0.4;
    return 0.1;
  }

  static SignalQuality _resolveSignalQuality(DeviceUIModel device) {
    if (!device.isWifi) return SignalQuality.wired;
    final rssi = device.signalStrength;
    if (rssi == null) return SignalQuality.unknown;
    if (rssi >= -50) return SignalQuality.strong;
    if (rssi >= -65) return SignalQuality.medium;
    return SignalQuality.weak;
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
  static List<NodeCoverageRing> _buildCoverageRings(
    MeshNodeType type,
    Color color,
  ) {
    final (innerR, outerR, innerOp, outerOp) = switch (type) {
      MeshNodeType.gateway => (100.0, 180.0, 0.18, 0.12),
      MeshNodeType.extender => (80.0, 140.0, 0.15, 0.10),
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
