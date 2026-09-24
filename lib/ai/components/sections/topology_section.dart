import 'package:flutter/material.dart';
import 'package:privacy_gui/ai/utils/speed_markers.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/topology/helpers/topology_subtitle.dart';
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
            subtitleBuilder: (node) => TopologySubtitle.build(context, node),
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
            // No spacing multiplier — the third of three sites that carried one,
            // and the one the issue did not list. The measurement that retired all
            // three is recorded once, at `usp_network_topology_card.dart:212`.
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
          // No `wired:` — the extender schema has no medium field to pass.
          level: _rssiToLevel(rssi),
          metadata: {
            if (mac != null) 'mac': mac,
            if (model != null) 'model': model,
            if (rssi != null) 'rssi': rssi,
            if (uplinkRate != null) 'uplinkRate': uplinkRate,
            // No `isWifi`. The prompt's extender schema
            // (`router_system_prompt.dart:223`) is
            // `{name, status?, rssi?, uplinkRate?, mac?, model?}` — it has no such
            // field, so the model cannot tell us, and an extender's backhaul is
            // genuinely sometimes wired. This used to be hardcoded `true`, which
            // asserted Wi-Fi about every one of them.
            //
            // `rssi` is the honest signal: a model that reported one is describing
            // a wireless link, and the panel already draws a Signal row from it.
          },
        ));

        edges.add(GraphEdge(
          // Keyed on the evidence, not asserted. `EdgeKind.indirect` used to be
          // hardcoded here, which said "wireless backhaul" about every extender a
          // model described — and the schema (`:223`) gives no medium field to base
          // that on. An `rssi` is the one thing in it that implies a radio link; a
          // model that reported none has not told us, and 3.4.0 lets the edge say
          // so instead of guessing.
          sourceId: gatewayId,
          targetId: extId,
          kind: rssi == null ? null : EdgeKind.indirect,
          // Null alongside the null kind, not `EdgeStrength.unknown`. The helper maps
          // a null reading to `unknown`, which is a grade — and grading an edge this
          // same line declines to classify says two things about one absent field.
          strength: rssi == null ? null : edgeStrengthFromRssi(rssi),
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
        // Nullable. `isWifi?` **is** in the prompt's client schema (`:224`), so an
        // absent one means the model chose not to say — and the panel now omits the
        // row rather than defaulting it. `?? true` printed "WiFi" for a device
        // nothing had described that way, which on a wired client is wrong in the
        // one direction a viewer would act on.
        final isWifi = client['isWifi'] as bool?;
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
          // A client's schema does carry the medium, so it is passed: known-wired is
          // full, and anything else is graded on the reading or left empty.
          level: _rssiToLevel(rssi, wired: isWifi == null ? null : !isWifi),
          deviceCategory: _inferCategory(name),
          metadata: {
            if (mac != null) 'mac': mac,
            if (ip != null) 'ip': ip,
            if (band != null) 'band': band,
            if (rssi != null) 'rssi': rssi,
            if (downlinkRate != null) 'downlinkRate': downlinkRate,
            if (uplinkRate != null) 'uplinkRate': uplinkRate,
            if (isWifi != null) 'isWifi': isWifi,
          },
        ));

        edges.add(GraphEdge(
          sourceId: resolvedParentId,
          targetId: clientId,
          // Null when the model did not say, which 3.4.0 made expressible: the kit
          // draws an undeclared edge in `undeclaredEdgeStyle` — neutral and never
          // animated, "because a flow animation is a claim about movement and an
          // undeclared edge supports none". Picking `direct` or `indirect` here
          // would be inventing that claim to satisfy a non-null type.
          kind: isWifi == null
              ? null
              : (isWifi ? EdgeKind.indirect : EdgeKind.direct),
          // Only graded for a link we know is wireless. A wired edge has no RSSI by
          // design and an undeclared one has no medium to grade.
          strength: isWifi == true ? edgeStrengthFromRssi(rssi) : null,
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

  /// The fill level for a node, given what the model told us about its link.
  ///
  /// [wired] is explicit because `getWifiSignalLevel(null)` answers `wired`: that
  /// helper treats a missing reading as "no radio", which is right for the host table
  /// it was written for and wrong here, where a missing `rssi` usually means the model
  /// left it out. Routing an absent reading through it drew a full ring — "wired, full
  /// strength" — for an extender whose edge, one line below, had just declined to say
  /// what the link is. So the three cases are separated:
  ///
  /// - known wired → 1.0, as `UspTopologyBuilder` does for a wired client;
  /// - wireless or unknown, with no reading → 0.0, the kit's own default for `level`
  ///   and what `UspTopologyBuilder._rssiValueToLevel(null)` answers;
  /// - a reading → graded.
  double _rssiToLevel(int? rssi, {bool? wired}) {
    if (wired == true) return 1.0;
    if (rssi == null) return 0.0;
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
