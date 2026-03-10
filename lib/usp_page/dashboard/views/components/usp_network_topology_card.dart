import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/usp_page/dashboard/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Displays a network topology visualization of the router and connected devices.
///
/// Uses [AppTopology] to render a gateway node (the router) with client nodes
/// (connected devices) linked via WiFi or Ethernet connections.
/// When mesh topology data is available, extender nodes are shown between
/// gateway and their connected clients.
class UspNetworkTopologyCard extends StatelessWidget {
  final SystemInfoUIModel info;
  final List<DeviceUIModel> devices;
  final List<MeshNodeInfo> meshNodes;

  const UspNetworkTopologyCard({
    super.key,
    required this.info,
    required this.devices,
    this.meshNodes = const [],
  });

  @override
  Widget build(BuildContext context) {
    final topology = _buildTopology();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Network Topology'),
              AppText.labelLarge(
                '${devices.where((d) => d.isActive).length} / ${devices.length} online',
              ),
            ],
          ),
          AppGap.xl(),
          SizedBox(
            height: 320,
            child: _withTopologyAnimation(
              context,
              AppTopology(
                topology: topology,
                viewMode: TopologyViewMode.graph,
                layoutMode: LayoutRecommendation.auto,
                clientVisibility: ClientVisibility.onHover,
                nodeRendererRegistry: NodeRendererRegistry.unified,
                enableAnimation: true,
                interactive: false,
                treeConfig: TopologyTreeConfiguration(
                  titleBuilder: (node) => node.name,
                  subtitleBuilder: (node) => node.extra ?? '',
                  preferAnimationNode: true,
                  showStatusIndicator: true,
                  showStatusText: true,
                  expanded: false,
                ),
                nodeDetailConfig: NodeDetailConfig(
                  trigger: NodeDetailTrigger.tap,
                  detailBuilder: (ctx, node, metadata) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.labelLarge(node.name),
                      if (node.extra != null) AppText.bodySmall(node.extra!),
                      AppText.bodySmall(
                        node.status == MeshNodeStatus.online
                            ? 'Online'
                            : 'Offline',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps [child] in a local Theme override that enables topology animation
  /// and increases client–node spacing for the dashboard card.
  Widget _withTopologyAnimation(BuildContext context, Widget child) {
    final appTheme = Theme.of(context).extension<AppDesignTheme>();
    if (appTheme == null) return child;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          appTheme.copyWith(
            visualEffects:
                appTheme.visualEffects | AppThemeConfig.effectTopologyAnimation,
            topologySpec: appTheme.topologySpec.copyWith(
              nodeSpacing: appTheme.topologySpec.nodeSpacing * 1.4,
              orbitRadius: appTheme.topologySpec.orbitRadius * 1.4,
            ),
          ),
        ],
      ),
      child: child,
    );
  }

  MeshTopology _buildTopology() {
    final nodes = <MeshNode>[];
    final links = <MeshLink>[];

    // Gateway node (the router)
    const gatewayId = 'gateway';
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
      ));

      links.add(MeshLink(
        sourceId: parentId,
        targetId: clientId,
        connectionType:
            isEthernet ? ConnectionType.ethernet : ConnectionType.wifi,
        rssi: device.signalStrength,
        throughput:
            device.totalThroughput > 0 ? device.totalThroughput / 1000.0 : null,
      ));
    }

    return MeshTopology(
      nodes: nodes,
      links: links,
      lastUpdated: DateTime.now(),
    );
  }

  /// Maps RSSI to a 0.0–1.0 level for ripple animation color.
  static double _rssiToLevel(DeviceUIModel device) {
    if (!device.isWifi) return 1.0; // wired → green
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
}
