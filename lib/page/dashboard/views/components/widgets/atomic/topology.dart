import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/topology_adapter.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/display_mode_widget.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Atomic widget displaying mesh topology.
///
/// For custom layout (Bento Grid) only.
/// - Compact: Minimal tree view
/// - Normal: Standard tree view
/// - Expanded: Graph view for visualization
class CustomTopology extends DisplayModeConsumerWidget {
  const CustomTopology({
    super.key,
    super.displayMode,
  });

  @override
  double getLoadingHeight(DisplayMode mode) => switch (mode) {
        DisplayMode.compact => 80,
        DisplayMode.normal => 200,
        DisplayMode.expanded => 400,
      };

  @override
  Widget buildCompactView(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(instantTopologyProvider);
    final routerLength =
        topologyState.root.children.firstOrNull?.toFlatList().length ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: AppInkWell(
        customColor: Colors.transparent,
        customBorderWidth: 0,
        onTap: () => context.pushNamed(RouteNamed.menuInstantTopology),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Row(
          children: [
            Icon(
              Icons.hub,
              color: Theme.of(context).colorScheme.primary,
            ),
            AppGap.md(),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).topology),
                AppText.labelSmall(
                  '$routerLength ${routerLength <= 1 ? loc(context).node : loc(context).nodes}',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildNormalView(BuildContext context, WidgetRef ref) {
    return _buildTopologyView(context, ref, isExpanded: false);
  }

  @override
  Widget buildExpandedView(BuildContext context, WidgetRef ref) {
    return _buildTopologyView(context, ref, isExpanded: true);
  }

  Widget _buildTopologyView(
    BuildContext context,
    WidgetRef ref, {
    required bool isExpanded,
  }) {
    final topologyState = ref.watch(instantTopologyProvider);
    final meshTopology = TopologyAdapter.convert(topologyState.root.children);

    const topologyItemHeight = 72.0;
    const treeViewBaseHeight = 72.0;
    final routerLength =
        topologyState.root.children.firstOrNull?.toFlatList().length ?? 1;

    final double nodeTopologyHeight = isExpanded
        ? double.infinity
        : (context.isMobileLayout
            ? routerLength * topologyItemHeight
            : min(routerLength * topologyItemHeight, 3 * topologyItemHeight));

    final showAllTopology = context.isMobileLayout || routerLength <= 3;

    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: SizedBox(
          height: isExpanded
              ? double.infinity
              : (nodeTopologyHeight + treeViewBaseHeight),
          child: AppTopology(
            topology: meshTopology,
            viewMode:
                isExpanded ? TopologyViewMode.graph : TopologyViewMode.tree,
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
            nodeContentBuilder: _buildGraphNodeContent,
            clientVisibility: ClientVisibility.onHover,
            nodeTapFilter: (node) => !node.isInternet,
            interactive:
                false, // Disable interaction to prevent dashboard scroll hijacking
          ),
        ));
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
      content = Image(image: meshNode.image!, fit: BoxFit.contain);
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
