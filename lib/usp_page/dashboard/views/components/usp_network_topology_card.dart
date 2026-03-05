import 'package:flutter/material.dart';
import 'package:privacy_gui/generated/connected_devices.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/dashboard/providers/wifi_client_enricher.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Displays a network topology visualization of the router and connected devices.
///
/// Uses [AppTopology] to render a gateway node (the router) with client nodes
/// (connected devices) linked via WiFi or Ethernet connections.
/// When mesh topology data is available, extender nodes are shown between
/// gateway and their connected clients.
class UspNetworkTopologyCard extends StatelessWidget {
  final SystemInfo info;
  final List<ConnectedDevice> devices;
  final Map<String, WifiClient> wifiClientMap;
  final MeshTopologyInfo meshTopology;

  const UspNetworkTopologyCard({
    super.key,
    required this.info,
    required this.devices,
    this.wifiClientMap = const {},
    this.meshTopology = MeshTopologyInfo.empty,
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
                viewMode: TopologyViewMode.auto,
                layoutMode: LayoutRecommendation.concentric,
                clientVisibility: ClientVisibility.clustered,
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

  /// Wraps [child] in a local Theme override that enables topology animation.
  ///
  /// The app's default `visualEffects` is 0 (all off). The Graph View checks
  /// `AppDesignTheme.topologyAnimationEnabled` and falls back to static icons
  /// when the bit is not set. This override adds the topology animation flag
  /// without affecting the rest of the theme.
  Widget _withTopologyAnimation(BuildContext context, Widget child) {
    final appTheme = Theme.of(context).extension<AppDesignTheme>();
    if (appTheme == null) return child;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          appTheme.copyWith(
            visualEffects:
                appTheme.visualEffects | AppThemeConfig.effectTopologyAnimation,
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
    nodes.add(MeshNode(
      id: gatewayId,
      name: info.modelName.isNotEmpty ? info.modelName : 'Router',
      type: MeshNodeType.gateway,
      status: MeshNodeStatus.online,
      iconData: Icons.router,
      extra: info.manufacturer,
      level: 1.0,
    ));

    // Mesh extender nodes (if DataElements available and > 1 node)
    // The first node is typically the gateway itself; additional nodes are extenders.
    final hasMesh = meshTopology.isNotEmpty && meshTopology.nodes.length > 1;
    final extenderNodeIds = <String>{}; // node deviceId → topology node id
    if (hasMesh) {
      // Skip the first node (gateway) — add remaining as extenders
      for (var i = 1; i < meshTopology.nodes.length; i++) {
        final meshNode = meshTopology.nodes[i];
        final extenderId = 'extender-${meshNode.deviceId}';
        extenderNodeIds.add(meshNode.deviceId);

        nodes.add(MeshNode(
          id: extenderId,
          name: meshNode.model.isNotEmpty
              ? meshNode.model
              : 'Extender ${meshNode.deviceId}',
          type: MeshNodeType.extender,
          status: MeshNodeStatus.online,
          parentId: gatewayId,
          iconData: Icons.router,
          level: 0.8,
        ));

        links.add(MeshLink(
          sourceId: gatewayId,
          targetId: extenderId,
          connectionType: ConnectionType.wifi,
        ));
      }
    }

    // Client nodes from connected devices
    for (final device in devices) {
      final clientId = device.instancePath;
      final iface = device.interface_.toLowerCase();
      final isEthernet = iface.contains('ethernet');
      final wifiInfo = wifiClientMap[device.macAddress.toUpperCase()];

      // Determine parent: if mesh data available, look up which node this client is on
      String parentId = gatewayId;
      if (hasMesh) {
        final parentNodeId =
            meshTopology.clientToNodeMap[device.macAddress.toUpperCase()];
        if (parentNodeId != null && extenderNodeIds.contains(parentNodeId)) {
          parentId = 'extender-$parentNodeId';
        }
      }

      nodes.add(MeshNode(
        id: clientId,
        name: device.hostName.isNotEmpty
            ? device.hostName
            : device.macAddress,
        type: MeshNodeType.client,
        status: device.isActive
            ? MeshNodeStatus.online
            : MeshNodeStatus.offline,
        parentId: parentId,
        iconData: isEthernet ? Icons.settings_ethernet : Icons.wifi,
        extra: device.ipAddress,
        signalQuality: _resolveSignalQuality(isEthernet, wifiInfo),
        level: _rssiToLevel(isEthernet, wifiInfo),
      ));

      links.add(MeshLink(
        sourceId: parentId,
        targetId: clientId,
        connectionType:
            isEthernet ? ConnectionType.ethernet : ConnectionType.wifi,
        rssi: wifiInfo?.signalStrength,
        throughput: wifiInfo != null
            ? (wifiInfo.lastDataDownlinkRate + wifiInfo.lastDataUplinkRate) /
                1000.0
            : null,
      ));
    }

    return MeshTopology(
      nodes: nodes,
      links: links,
      lastUpdated: DateTime.now(),
    );
  }

  /// Maps RSSI to a 0.0–1.0 level for ripple animation color.
  static double _rssiToLevel(bool isEthernet, WifiClient? wifiInfo) {
    if (isEthernet) return 1.0; // wired → green (3 rings)
    if (wifiInfo == null) return 0.0;
    final rssi = wifiInfo.signalStrength;
    if (rssi >= -50) return 0.9; // strong → green
    if (rssi >= -60) return 0.65; // good → amber
    if (rssi >= -70) return 0.4; // fair → orange
    return 0.1; // weak → red
  }

  static SignalQuality _resolveSignalQuality(
      bool isEthernet, WifiClient? wifiInfo) {
    if (isEthernet) return SignalQuality.wired;
    if (wifiInfo == null) return SignalQuality.unknown;
    final rssi = wifiInfo.signalStrength;
    if (rssi >= -50) return SignalQuality.strong;
    if (rssi >= -65) return SignalQuality.medium;
    return SignalQuality.weak;
  }
}
