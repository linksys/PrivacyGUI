import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/topology/_topology.dart';
import 'package:linksys_app/page/topology/views/_views.dart';
import 'package:linksys_app/page/topology/views/topology_data.dart';
import 'package:linksys_app/page/topology/views/topology_model.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/node_list_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/topology/family_tree/family_tree_view.dart';
import 'package:linksys_widgets/widgets/topology/tree_item.dart';
import 'package:linksys_widgets/widgets/topology/tree_node.dart';
import 'package:linksys_widgets/widgets/topology/tree_view.dart';

class TopologyView extends ArgumentsConsumerStatelessView {
  const TopologyView({Key? key, super.args}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(topologyProvider);

    final isShowingDeviceChain =
        ref.watch(topologySelectedIdProvider).isNotEmpty;
    return StyledAppPageView(
      // scrollable: true,
      padding: EdgeInsets.zero,
      title: loc(context).nNodes(topologyState.nodesCount),

      child: AppBasicLayout(
        content: Column(
          children: [
            Flexible(
              child: ResponsiveLayout.isLayoutBreakpoint(context)
                  ? AppTreeView(
                      onlineRoot: topologyState.onlineRoot,
                      offlineRoot: topologyState.offlineRoot,
                      itemBuilder: (node) {
                        // return Container(color: Colors.amber);
                        return switch (node.runtimeType) {
                          OnlineTopologyNode =>
                            _buildHeader(context, ref, node),
                          OfflineTopologyNode =>
                            _buildHeader(context, ref, node),
                          RouterTopologyNode => _buildNode(context, ref, node),
                          _ => _buildHeader(context, ref, node),
                        };
                      },
                    )
                  : AppFamilyTreeView(
                      onlineRoot: topologyState.onlineRoot,
                      offlineRoot: topologyState.offlineRoot,
                      itemBuilder: (node) {
                        // return Container(color: Colors.amber);
                        return switch (node) {
                          OnlineTopologyNode() =>
                            _buildFamilyHeader(context, ref, node),
                          OfflineTopologyNode() =>
                            AppText.titleMedium(node.data.location),
                          RouterTopologyNode() =>
                            _buildFamilyNode(context, ref, node),
                          DeviceTopologyNode() =>
                            _buildFamilyNode(context, ref, node),
                          _ => throw Exception('Unsupport topology node'),
                        };
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyNode(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return SizedBox(
      width: 300,
      height: 84,
      child: AppNodeListCard(
        leading:
            CustomTheme.of(context).images.devices.getByName(node.data.icon),
        title: node.data.location,
        description: loc(context).nDevices(node.data.connectedDeviceCount),
        trailing: node.data.isOnline
            ? node.data.isWiredConnection
                ? getWifiSignalIconData(context, null)
                : getWifiSignalIconData(context, node.data.signalStrength)
            : null,
        onTap: () => onNodeTap(context, ref, node),
      ),
    );
  }

  Widget _buildFamilyHeader(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(LinksysIcons.language),
        AppGap.regular(),
        AppText.titleMedium('Internet')
      ],
    );
  }

  Widget _buildNode(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return AppTreeNodeItem(
      name: node.data.location,
      image: CustomTheme.of(context).images.devices.getByName(node.data.icon),
      count: node.data.isOnline && node is RouterTopologyNode
          ? node.data.connectedDeviceCount
          : null,
      status: node.data.isOnline ? null : 'Offline',
      tail: node.data.isOnline
          ? Icon(
              node.data.isWiredConnection
                  ? getWifiSignalIconData(context, null)
                  : getWifiSignalIconData(context, node.data.signalStrength),
            )
          : null,
      onTap: () {
        onNodeTap(context, ref, node);
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return InfoCell(
      name: node.data.location == 'Internet'
          ? loc(context).internet
          : node.data.location,
      icon: node is OnlineTopologyNode ? LinksysIcons.language : null,
      showConnector: node is OnlineTopologyNode,
    );
  }

  List<RouterTreeNode> _getNodes(
      TopologyState topologyState, bool showOffline) {
    return [
      topologyState.onlineRoot,
      if (showOffline && topologyState.offlineRoot.children.isNotEmpty)
        topologyState.offlineRoot,
    ];
  }

  void onNodeTap(BuildContext context, WidgetRef ref, RouterTreeNode node) {
    ref.read(deviceDetailIdProvider.notifier).state = node.data.deviceId;
    if (node is DeviceTopologyNode) {
      context.pop();
    } else if (node.data.isOnline) {
      // Update the current target Id for node state
      context.pushNamed(RouteNamed.nodeDetails);
    } else {
      context.pushNamed(RouteNamed.nodeOffline);
    }
  }
}
