import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/topology_adapter.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/page/dashboard/models/display_mode.dart';

/// Atomic widget displaying mesh topology tree view.
///
/// Extracted from [DashboardNetworks] for Bento Grid atomic usage.
class DashboardTopology extends ConsumerWidget {
  final DisplayMode displayMode;

  const DashboardTopology({
    super.key,
    this.displayMode = DisplayMode.normal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: 200,
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(instantTopologyProvider);

    // Convert topology data to ui_kit format
    final meshTopology = TopologyAdapter.convert(topologyState.root.children);

    final isExpanded = displayMode == DisplayMode.expanded;

    // Calculate topology height
    const topologyItemHeight = 72.0;
    const treeViewBaseHeight = 72.0;
    final routerLength =
        topologyState.root.children.firstOrNull?.toFlatList().length ?? 1;

    // In expanded mode, we want more height for the graph
    final double nodeTopologyHeight = isExpanded
        ? 400.0 // Fixed height for graph view (approx 5-6 rows)
        : (context.isMobileLayout
            ? routerLength * topologyItemHeight
            : min(routerLength * topologyItemHeight, 3 * topologyItemHeight));

    final showAllTopology = context.isMobileLayout || routerLength <= 3;

    return SizedBox(
      height: isExpanded
          ? nodeTopologyHeight
          : (nodeTopologyHeight + treeViewBaseHeight),
      child: AppTopology(
        topology: meshTopology,
        // In expanded mode, use auto to allow Graph View if space permits
        viewMode: isExpanded ? TopologyViewMode.graph : TopologyViewMode.tree,
        enableAnimation: isExpanded || !showAllTopology,
        onNodeTap: TopologyAdapter.wrapNodeTapCallback(
          topologyState.root.children,
          (RouterTreeNode node) {
            if (node.data.isOnline) {
              ref.read(nodeDetailIdProvider.notifier).state =
                  node.data.deviceId;
              context.pushNamed(RouteNamed.nodeDetails);
            }
          },
        ),
        indent: 16.0,
        treeConfig: TopologyTreeConfiguration(
          preferAnimationNode: false,
          showType: false,
          showStatusText: false,
          showStatusIndicator: true,
          titleBuilder: (meshNode) => meshNode.name,
          subtitleBuilder: (meshNode) => _buildSubtitle(context, meshNode),
        ),
        // Graph View Configuration
        nodeContentBuilder: (context, meshNode, style, isOffline) =>
            _buildGraphNodeContent(context, meshNode, style, isOffline),
        // Simplified interaction for dashboard
        clientVisibility: ClientVisibility.onHover,
        nodeTapFilter: (node) => !node.isInternet,
      ),
    );
  }

  String _buildSubtitle(BuildContext context, MeshNode meshNode) {
    final model = meshNode.extra;
    final deviceCount = meshNode.metadata?['connectedDeviceCount'] as int? ?? 0;
    final deviceLabel =
        deviceCount <= 1 ? loc(context).device : loc(context).devices;

    if (model == null || model.isEmpty) {
      return '$deviceCount $deviceLabel';
    }
    return '$model • $deviceCount $deviceLabel';
  }

  Widget _buildGraphNodeContent(BuildContext context, MeshNode meshNode,
      NodeStyle style, bool isOffline) {
    final deviceCount = meshNode.metadata?['connectedDeviceCount'] ?? 0;

    Widget content;
    if (meshNode.image != null) {
      content = Image(
        image: meshNode.image!,
        fit: BoxFit.contain,
      );
    } else {
      content = Icon(
        meshNode.iconData ?? Icons.router,
        color: style.iconColor,
        size: style.size * 0.5,
      );
    }

    final paddedContent = Padding(
      padding: const EdgeInsets.all(12.0),
      child: content,
    );

    if (deviceCount > 0) {
      return Stack(
        children: [
          paddedContent,
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  width: 1,
                ),
              ),
              child: Text(
                '$deviceCount',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return paddedContent;
  }
}
