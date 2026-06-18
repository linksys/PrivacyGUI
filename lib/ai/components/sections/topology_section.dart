import 'package:flutter/material.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Network topology visualization section.
///
/// Displays a simplified mesh topology with gateway, extenders, and clients.
/// The topology is static (non-interactive) for AI-generated displays.
class TopologySection extends StatelessWidget {
  /// Gateway/router info.
  final String gatewayName;
  final String? gatewayModel;

  /// Extender nodes (optional for mesh networks).
  final List<Map<String, dynamic>>? extenders;

  /// Client devices connected to the network.
  final List<Map<String, dynamic>>? clients;

  /// Maximum number of clients to display (default: 8).
  final int maxClients;

  const TopologySection({
    super.key,
    required this.gatewayName,
    this.gatewayModel,
    this.extenders,
    this.clients,
    this.maxClients = 8,
  });

  @override
  Widget build(BuildContext context) {
    final topology = _buildTopology();

    // Match dashboard topology card settings exactly
    return SizedBox(
      height: 300,
      child: _withTopologyAnimation(
        context,
        AppTopology(
          topology: topology,
          viewMode: TopologyViewMode.graph,
          layoutMode: LayoutRecommendation.auto,
          clientVisibility: ClientVisibility.always,
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
            detailBuilder: _buildNodeDetailPopup,
          ),
        ),
      ),
    );
  }

  Widget _buildNodeDetailPopup(
    BuildContext context,
    MeshNode node,
    Map<String, dynamic>? metadata,
  ) {
    final mac = metadata?['mac'] as String? ?? '';
    final ip = metadata?['ip'] as String? ?? '';
    final model = metadata?['model'] as String? ?? '';
    final connectionType = metadata?['connectionType'] as String? ?? '';
    final band = metadata?['band'] as String? ?? '';
    final rssi = metadata?['rssi'] as int?;
    final downlinkRate = metadata?['downlinkRate'] as int?;
    final uplinkRate = metadata?['uplinkRate'] as int?;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mac.isNotEmpty) _popupRow(context, 'MAC', mac),
        if (ip.isNotEmpty) _popupRow(context, 'IP', ip),
        if (model.isNotEmpty) _popupRow(context, 'Model', model),
        if (connectionType.isNotEmpty)
          _popupRow(context, 'Connection', connectionType),
        if (band.isNotEmpty) _popupRow(context, 'Band', band),
        if (rssi != null) _popupRow(context, 'Signal', '$rssi dBm'),
        if (downlinkRate != null || uplinkRate != null)
          _popupRow(
            context,
            'Speed',
            _formatSpeedPair(downlinkRate, uplinkRate),
          ),
      ],
    );
  }

  Widget _popupRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: AppText.bodySmall(label, color: Colors.grey),
          ),
          Expanded(child: AppText.bodySmall(value)),
        ],
      ),
    );
  }

  String _formatSpeedPair(int? downlink, int? uplink) {
    final down = _formatSpeed(downlink);
    final up = _formatSpeed(uplink);
    if (down != null && up != null) return '↓$down ↑$up';
    if (down != null) return '↓$down';
    if (up != null) return '↑$up';
    return '';
  }

  String? _formatSpeed(int? bps) {
    if (bps == null || bps == 0) return null;
    final mbps = bps / 1000000;
    if (mbps >= 1000) return '${(mbps / 1000).toStringAsFixed(1)} Gbps';
    if (mbps >= 1) return '${mbps.toStringAsFixed(1)} Mbps';
    return '${(bps / 1000).toStringAsFixed(0)} Kbps';
  }

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
              nodeSpacing: appTheme.topologySpec.nodeSpacing * 2.0,
              orbitRadius: appTheme.topologySpec.orbitRadius * 2.0,
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

    // Gateway node
    const gatewayId = 'gateway';
    nodes.add(MeshNode(
      id: gatewayId,
      name: gatewayName,
      type: MeshNodeType.gateway,
      status: MeshNodeStatus.online,
      level: 1.0,
      extra: gatewayModel,
    ));

    // Extender nodes
    if (extenders != null) {
      for (int i = 0; i < extenders!.length; i++) {
        final ext = extenders![i];
        final extId = 'extender-$i';
        final name = ext['name'] as String? ?? 'Extender ${i + 1}';
        final status = ext['status'] as String? ?? 'online';
        final rssi = ext['rssi'] as int?;
        final uplinkRate = ext['uplinkRate'] as int?; // bps
        final mac = ext['mac'] as String?;
        final model = ext['model'] as String?;

        nodes.add(MeshNode(
          id: extId,
          name: name,
          type: MeshNodeType.extender,
          parentId: gatewayId,
          status: _parseStatus(status),
          level: _rssiToLevel(rssi),
          metadata: {
            if (mac != null) 'mac': mac,
            if (model != null) 'model': model,
            if (rssi != null) 'rssi': rssi,
            if (uplinkRate != null) 'uplinkRate': uplinkRate,
            'connectionType': 'WiFi',
          },
        ));

        links.add(MeshLink(
          sourceId: gatewayId,
          targetId: extId,
          connectionType: ConnectionType.wifi,
          rssi: rssi,
          linkQuality: _rssiToQuality(rssi),
          throughput: uplinkRate != null ? uplinkRate / 1000.0 : null, // Kbps
        ));
      }
    }

    // Client nodes
    if (clients != null) {
      final displayClients = clients!.take(maxClients).toList();
      for (int i = 0; i < displayClients.length; i++) {
        final client = displayClients[i];
        final clientId = 'client-$i';
        final name = client['name'] as String? ?? 'Device ${i + 1}';
        final parentId = client['parentId'] as String? ?? gatewayId;
        final isWifi = client['isWifi'] as bool? ?? true;
        final rssi = client['rssi'] as int?;
        final status = client['status'] as String? ?? 'online';
        final downlinkRate = client['downlinkRate'] as int?; // bps
        final uplinkRate = client['uplinkRate'] as int?; // bps
        final mac = client['mac'] as String?;
        final ip = client['ip'] as String?;
        final band = client['band'] as String?;
        final totalThroughput = (downlinkRate ?? 0) + (uplinkRate ?? 0);

        // Resolve parent ID
        String resolvedParentId = gatewayId;
        if (parentId != gatewayId && extenders != null) {
          // Try to find matching extender
          for (int j = 0; j < extenders!.length; j++) {
            final extName = extenders![j]['name'] as String? ?? '';
            final extMac = extenders![j]['mac'] as String? ?? '';
            if (parentId == extName || parentId == extMac) {
              resolvedParentId = 'extender-$j';
              break;
            }
          }
        }

        nodes.add(MeshNode(
          id: clientId,
          name: name,
          type: MeshNodeType.client,
          parentId: resolvedParentId,
          status: _parseStatus(status),
          level: _rssiToLevel(rssi),
          deviceCategory: _inferCategory(name),
          metadata: {
            if (mac != null) 'mac': mac,
            if (ip != null) 'ip': ip,
            if (band != null) 'band': band,
            if (rssi != null) 'rssi': rssi,
            if (downlinkRate != null) 'downlinkRate': downlinkRate,
            if (uplinkRate != null) 'uplinkRate': uplinkRate,
            'connectionType': isWifi ? 'WiFi' : 'Ethernet',
          },
        ));

        links.add(MeshLink(
          sourceId: resolvedParentId,
          targetId: clientId,
          connectionType:
              isWifi ? ConnectionType.wifi : ConnectionType.ethernet,
          rssi: isWifi ? rssi : null,
          linkQuality: isWifi ? _rssiToQuality(rssi) : LinkQuality.stable,
          throughput:
              totalThroughput > 0 ? totalThroughput / 1000.0 : null, // Kbps
        ));
      }
    }

    return MeshTopology(
      nodes: nodes,
      links: links,
      lastUpdated: DateTime.now(),
    );
  }

  MeshNodeStatus _parseStatus(String status) {
    return switch (status.toLowerCase()) {
      'online' || 'connected' || 'up' => MeshNodeStatus.online,
      'offline' || 'disconnected' || 'down' => MeshNodeStatus.offline,
      'highload' || 'busy' => MeshNodeStatus.highLoad,
      _ => MeshNodeStatus.online,
    };
  }

  double _rssiToLevel(int? rssi) {
    final level = getWifiSignalLevel(rssi);
    return switch (level) {
      NodeSignalLevel.excellent => 0.9,
      NodeSignalLevel.good => 0.7,
      NodeSignalLevel.fair => 0.5,
      NodeSignalLevel.poor => 0.2,
      NodeSignalLevel.none => 0.0,
      NodeSignalLevel.wired => 1.0,
    };
  }

  LinkQuality _rssiToQuality(int? rssi) {
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

  String _inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('iphone') || lower.contains('android')) {
      return 'smartphone';
    }
    if (lower.contains('mac') ||
        lower.contains('laptop') ||
        lower.contains('book')) {
      return 'laptop';
    }
    if (lower.contains('tv') || lower.contains('roku')) return 'tv';
    if (lower.contains('printer')) return 'printer';
    if (lower.contains('camera')) return 'camera';
    return 'unknown';
  }
}
