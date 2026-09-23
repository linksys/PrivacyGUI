import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_backhaul_link.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';
import 'package:privacy_gui/page/topology/helpers/topology_nav_target.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shared popup content for mesh node details.
///
/// Used by both Dashboard topology card and Topology page.
class NodeDetailPopup extends StatelessWidget {
  final GraphNode node;
  final Map<String, dynamic>? metadata;
  final bool showDetailsButton;
  final VoidCallback? onDetailsTap;

  const NodeDetailPopup({
    super.key,
    required this.node,
    this.metadata,
    this.showDetailsButton = false,
    this.onDetailsTap,
  });

  /// Factory for use with AppTopology's detailBuilder.
  static Widget builder(
    BuildContext context,
    GraphNode node,
    Map<String, dynamic>? metadata, {
    bool showDetailsButton = false,
  }) {
    // Where this node's own page is, resolved by the one function that decides
    // it.
    //
    // This used to resolve `deviceId` inline and go to Node Detail, which is a
    // mesh node's page. A leaf carries no `deviceId`, so once ui_kit 3.4.0 began
    // opening a panel for one, the button was drawn and did nothing.
    // `topologyNavTargetFor` already answers this for every kind of node — and
    // carries the offline gate for mesh nodes (#1465) — so reusing it is also
    // what keeps the two routes from drifting apart.
    // Resolved from the same metadata the rows below read, not from
    // `node.metadata` — see `topologyNavTargetFor`'s own note on why those are
    // two things.
    final target = topologyNavTargetFor(node, metadata: metadata);

    return NodeDetailPopup(
      node: node,
      metadata: metadata,
      // Not merely asked for, but reachable: a node with no destination draws no
      // button rather than a dead one.
      showDetailsButton: showDetailsButton && target != null,
      onDetailsTap: showDetailsButton && target != null
          ? () => GoRouter.of(context).pushNamed(
                target.route,
                queryParameters: target.queryParameters,
              )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceId = metadata?['deviceId'] as String? ?? '';
    final model = metadata?['model'] as String? ?? '';
    final manufacturer = metadata?['manufacturer'] as String? ?? '';
    final serialNumber = metadata?['serialNumber'] as String? ?? '';
    final softwareVersion = metadata?['softwareVersion'] as String? ?? '';
    // Which kind of thing this panel is describing.
    //
    // Stated by the builder rather than inferred from which keys are missing: a
    // leaf and a mesh node have disjoint field sets, and keying on absence made
    // every added field a place for the split to drift. Before ui_kit 3.4.0 the
    // question did not arise — the kit refused a leaf its panel — so this widget
    // read `isMaster` unguarded and printed `Slave` for a laptop (#1614 D2).
    final isLeaf = metadata?['isLeaf'] as bool? ?? false;
    final isMaster = metadata?['isMaster'] as bool? ?? false;

    // A device's own facts, for a leaf.
    final mac = metadata?['mac'] as String? ?? '';
    final ip = metadata?['ip'] as String? ?? '';
    final isWifi = metadata?['isWifi'] as bool? ?? false;
    final signalStrength = metadata?['signalStrength'] as int?;
    final band = metadata?['band'] as String?;
    final ssid = metadata?['ssid'] as String?;
    final parentNodeName = metadata?['parentNodeName'] as String?;

    // Backhaul info for Slave nodes
    final backhaulLinkType = metadata?['backhaulLinkType'] as String?;
    final backhaulSignalStrength = metadata?['backhaulSignalStrength'] as int?;
    final backhaulUplinkRate = metadata?['backhaulUplinkRate'] as int?;
    final backhaulDownlinkRate = metadata?['backhaulDownlinkRate'] as int?;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A leaf is a device, so it gets a device's rows and none of a node's.
        if (isLeaf) ...[
          if (ip.isNotEmpty) _row(loc(context).ipAddress, ip),
          if (mac.isNotEmpty) _row(loc(context).macAddress, mac),
          _row(loc(context).connectionType,
              isWifi ? loc(context).wifi : loc(context).ethernet),
          if (ssid != null) _row(loc(context).wifiName, ssid),
          if (band != null) _row(loc(context).band, band),
          // Wireless only, and only when measured — a wired device has no RSSI
          // by design, not by absence.
          if (signalStrength != null)
            // `signalStrengthDbm` rather than a hand-built '$v dBm': the unit's
            // placement is localisable and the key already exists.
            _row(loc(context).signal,
                loc(context).signalStrengthDbm(signalStrength.toString())),
          if (parentNodeName != null)
            _row(loc(context).connectedTo, parentNodeName),
        ] else ...[
          // Everything below belongs to a mesh node, so it all sits inside this
          // arm. It used to trail after the `if`/`else` as five separate
          // `!isLeaf && …` guards, which is the same condition restated by a
          // block that already exists — and one a later row could forget.
          _row(loc(context).role,
              isMaster ? loc(context).master : loc(context).slave),
          if (deviceId.isNotEmpty && deviceId.toUpperCase() != 'GATEWAY')
            _row('MAC', deviceId),
          if (model.isNotEmpty) _row(loc(context).model, model),
          if (manufacturer.isNotEmpty)
            _row(loc(context).manufacturer, manufacturer),
          if (serialNumber.isNotEmpty) _row('S/N', serialNumber),
          if (softwareVersion.isNotEmpty)
            _row(loc(context).firmware, softwareVersion),
          // Backhaul info for slave nodes only — the master has no uplink of this
          // kind to report.
          if (!isMaster) ...[
            if (backhaulLinkType != null && backhaulLinkType.isNotEmpty)
              _row('Backhaul', backhaulLinkType),
            // Shared predicate, not `!= 'Ethernet'`: this row draws a signal
            // reading, so a wired node whose medium is spelled unexpectedly must
            // not fall into it (#1555).
            if (backhaulSignalStrength != null &&
                !isMeshBackhaulEthernet(backhaulLinkType))
              _row('Signal', '$backhaulSignalStrength dBm'),
            if (backhaulUplinkRate != null && backhaulDownlinkRate != null)
              _row(
                'Speed',
                'Up: ${NetworkUtils.formatSpeed(backhaulUplinkRate)} / '
                    'Down: ${NetworkUtils.formatSpeed(backhaulDownlinkRate)}',
              )
            else if (backhaulUplinkRate != null)
              _row('Speed',
                  'Up: ${NetworkUtils.formatSpeed(backhaulUplinkRate)}')
            else if (backhaulDownlinkRate != null)
              _row('Speed',
                  'Down: ${NetworkUtils.formatSpeed(backhaulDownlinkRate)}'),
          ],
        ],
        // Details button (optional)
        if (showDetailsButton && node.status == NodeState.active)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: AppButton.text(
                label: loc(context).details,
                onTap: onDetailsTap,
                // Fixed slug with no per-instance key — unlike the node
                // identifiers in node_identifier.dart, which need one because
                // N nodes coexist in the Semantics tree. This button lives in
                // the graph view's singleton detail panel (one `_selectedNodeId`
                // at a time), so it is unique by construction. Wiring this
                // popup into `TopologyTreeConfiguration.detailBuilder`, which
                // renders per row, would break that: derive the key from the
                // node's MAC first (see shortestUniqueMacSuffixes).
                identifier: kTopologyNodeDetailButtonIdentifier,
              ),
            ),
          ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: AppText.bodySmall(label, color: Colors.grey),
          ),
          Expanded(child: AppText.bodySmall(value)),
        ],
      ),
    );
  }
}
