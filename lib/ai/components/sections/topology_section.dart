import 'package:flutter/material.dart';
import 'package:privacy_gui/ai/utils/speed_markers.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/topology/helpers/topology_edge_strength.dart';
import 'package:privacy_gui/page/topology/helpers/topology_slots.dart';
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
    final topology = _buildTopology(context);

    // Match dashboard topology card settings exactly
    return SizedBox(
      height: 300,
      child: _withTopologyAnimation(
        context,
        AppTopology(
          topology: topology,
          viewMode: TopologyViewMode.graph,
          layoutMode: LayoutRecommendation.auto,
          leafVisibility: LeafVisibility.always,
          nodeRendererRegistry: NodeRendererRegistry.unified,
          enableAnimation: true,
          interactive: false,
          treeConfig: TopologyTreeConfiguration(
            titleBuilder: (node) => node.name,
            subtitleBuilder: (node) => node.extra ?? '',
            preferAnimationNode: true,
            showStatusIndicator: true,
            // `showType` / `showStatusText` are left at their 3.4.0 default of
            // false: this section pins `viewMode: graph`, so the tree row those
            // labels belong to is never built, and wiring builders here would be
            // wiring something nothing draws.
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
    GraphNode node,
    Map<String, dynamic>? metadata,
  ) {
    final mac = metadata?['mac'] as String? ?? '';
    final ip = metadata?['ip'] as String? ?? '';
    final model = metadata?['model'] as String? ?? '';
    // Resolved here, not stored. `connectionType` used to be written into the
    // metadata as a localised word at construction time, which froze it: a viewer
    // switching language saw the node rebuilt with the string chosen under the
    // previous locale. The map carries the fact (`isWifi`); this picks the word.
    final isWifi = metadata?['isWifi'] as bool?;
    final connectionType = isWifi == null
        ? ''
        : (isWifi ? loc(context).wifi : loc(context).ethernet);
    final band = metadata?['band'] as String? ?? '';
    final rssi = metadata?['rssi'] as int?;
    final downlinkRate = metadata?['downlinkRate'] as int?;
    final uplinkRate = metadata?['uplinkRate'] as int?;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mac.isNotEmpty) _popupRow(context, loc(context).mac, mac),
        if (ip.isNotEmpty) _popupRow(context, loc(context).ipColumn, ip),
        if (model.isNotEmpty) _popupRow(context, loc(context).model, model),
        if (connectionType.isNotEmpty)
          _popupRow(context, loc(context).connection, connectionType),
        if (band.isNotEmpty) _popupRow(context, loc(context).band, band),
        if (rssi != null)
          _popupRow(context, loc(context).signal,
              loc(context).signalStrengthDbm('$rssi')),
        if (downlinkRate != null || uplinkRate != null)
          _speedRow(context, downlinkRate, uplinkRate),
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

  /// The speed row, built directly rather than through [_popupRow], because its
  /// value is icon + text pairs rather than a plain string.
  Widget _speedRow(BuildContext context, int? downlink, int? uplink) {
    final pairs = speedMarkersFor(downlink: downlink, uplink: uplink);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: AppText.bodySmall(loc(context).speed, color: Colors.grey),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              children: [
                for (final pair in pairs)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon.font(pair.icon, size: 12, color: Colors.grey),
                      AppGap.xxs(),
                      AppText.bodySmall(pair.text),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
            // No spacing multiplier. The card and the full page both had one to
            // stop nodes crowding, and both measured it out: ui_kit 3.4.0 sizes
            // every ring from the discs going on it, so the pitch is 51.5px at
            // x1.0, x2.0 and x2.2 alike — and past fit-to-screen the multiplier
            // grows the bounds into the 0.5 fit floor, drawing a *smaller* graph.
            // This section was missed when the other two were changed.
          ),
        ],
      ),
      child: child,
    );
  }

  GraphData _buildTopology(BuildContext context) {
    final nodes = <GraphNode>[];
    final edges = <GraphEdge>[];

    // Gateway node
    const gatewayId = 'gateway';
    nodes.add(GraphNode(
      id: gatewayId,
      name: gatewayName,
      // Stated at the origin, like `UspTopologyBuilder` — this builder also knows
      // which of its three sources each node came from.
      styleSlot: TopologySlots.master,
      status: NodeState.active,
      level: 1.0,
      extra: gatewayModel,
    ));

    // Extender nodes
    if (extenders != null) {
      for (int i = 0; i < extenders!.length; i++) {
        final ext = extenders![i];
        final extId = 'extender-$i';
        final name = ext['name'] as String? ?? loc(context).extenderN(i + 1);
        final status = ext['status'] as String? ?? 'online';
        final rssi = ext['rssi'] as int?;
        final uplinkRate = ext['uplinkRate'] as int?; // bps
        final mac = ext['mac'] as String?;
        final model = ext['model'] as String?;

        nodes.add(GraphNode(
          id: extId,
          name: name,
          styleSlot: TopologySlots.slave,
          parentId: gatewayId,
          status: _parseStatus(status),
          level: _rssiToLevel(rssi),
          metadata: {
            if (mac != null) 'mac': mac,
            if (model != null) 'model': model,
            if (rssi != null) 'rssi': rssi,
            if (uplinkRate != null) 'uplinkRate': uplinkRate,
            'isWifi': true,
          },
        ));

        edges.add(GraphEdge(
          sourceId: gatewayId,
          targetId: extId,
          kind: EdgeKind.indirect,
          strength: edgeStrengthFromRssi(rssi),
        ));
      }
    }

    // Client nodes
    if (clients != null) {
      final displayClients = clients!.take(maxClients).toList();
      for (int i = 0; i < displayClients.length; i++) {
        final client = displayClients[i];
        final clientId = 'client-$i';
        final name = client['name'] as String? ?? loc(context).deviceN(i + 1);
        final parentId = client['parentId'] as String? ?? gatewayId;
        final isWifi = client['isWifi'] as bool? ?? true;
        final rssi = client['rssi'] as int?;
        final status = client['status'] as String? ?? 'online';
        final downlinkRate = client['downlinkRate'] as int?; // bps
        final uplinkRate = client['uplinkRate'] as int?; // bps
        final mac = client['mac'] as String?;
        final ip = client['ip'] as String?;
        final band = client['band'] as String?;

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

        nodes.add(GraphNode(
          id: clientId,
          name: name,
          styleSlot: TopologySlots.device,
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
            'isWifi': isWifi,
          },
        ));

        edges.add(GraphEdge(
          sourceId: resolvedParentId,
          targetId: clientId,
          kind: isWifi ? EdgeKind.indirect : EdgeKind.direct,
          // Null for a wired edge: wiredness is the kind axis, and a direct
          // edge's strength is never read.
          strength: isWifi ? edgeStrengthFromRssi(rssi) : null,
        ));
      }
    }

    return GraphData(
      nodes: nodes,
      edges: edges,
      lastUpdated: DateTime.now(),
    );
  }

  /// Maps a status token to a node status.
  ///
  /// The tokens matched here (and the `'online'` default applied at the call
  /// sites) are wire values supplied by the model, never rendered text, so they
  /// stay English on purpose.
  NodeState _parseStatus(String status) {
    return switch (status.toLowerCase()) {
      'online' || 'connected' || 'up' => NodeState.active,
      'offline' || 'disconnected' || 'down' => NodeState.inactive,
      'highload' || 'busy' => NodeState.alert,
      _ => NodeState.active,
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
