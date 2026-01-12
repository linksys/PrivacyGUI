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

/// Atomic widget displaying mesh topology tree view.
///
/// Extracted from [DashboardNetworks] for Bento Grid atomic usage.
class DashboardTopology extends ConsumerWidget {
  const DashboardTopology({super.key});

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

    // Calculate topology height
    const topologyItemHeight = 72.0;
    const treeViewBaseHeight = 72.0;
    final routerLength =
        topologyState.root.children.firstOrNull?.toFlatList().length ?? 1;
    final double nodeTopologyHeight = context.isMobileLayout
        ? routerLength * topologyItemHeight
        : min(routerLength * topologyItemHeight, 3 * topologyItemHeight);
    final showAllTopology = context.isMobileLayout || routerLength <= 3;

    return SizedBox(
      height: nodeTopologyHeight + treeViewBaseHeight,
      child: AppTopology(
        topology: meshTopology,
        viewMode: TopologyViewMode.tree,
        enableAnimation: !showAllTopology,
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
          subtitleBuilder: (meshNode) {
            final model = meshNode.extra;
            final deviceCount =
                meshNode.metadata?['connectedDeviceCount'] as int? ?? 0;
            final deviceLabel =
                deviceCount <= 1 ? loc(context).device : loc(context).devices;

            if (model == null || model.isEmpty) {
              return '$deviceCount $deviceLabel';
            }
            return '$model • $deviceCount $deviceLabel';
          },
        ),
      ),
    );
  }
}
