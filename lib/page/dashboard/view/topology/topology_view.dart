import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/dashboard/view/topology/topology_model.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/topology_provider.dart';
import 'package:linksys_app/provider/devices/topology_state.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/topology/tree_item.dart';
import 'package:linksys_widgets/widgets/topology/tree_node.dart';
import 'package:linksys_widgets/widgets/topology/tree_view.dart';

typedef TopologyTreeView = AppTreeView<TopologyModel>;

class TopologyView extends ArgumentsConsumerStatelessView {
  const TopologyView({Key? key, super.args}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(topologyProvider);

    final isShowingDeviceChain =
        ref.watch(topologySelectedIdProvider).isNotEmpty;
    return StyledAppPageView(
      // scrollable: true,
      child: AppBasicLayout(
        content: Column(
          children: [
            Flexible(
              child: TopologyTreeView(
                roots: _getNodes(topologyState, !isShowingDeviceChain),
                itemBuilder: (index, node) {
                  return AppTreeNodeItem(
                    name: node.data.location,
                    image: AppTheme.of(context)
                        .images
                        .devices
                        .getByName(node.data.icon),
                    count:
                        node.data.isOnline && node.type == AppTreeNodeType.node
                            ? node.data.connectedDeviceCount
                            : null,
                    status: node.data.isOnline ? null : 'Offline',
                    tail: node.data.isOnline
                        ? AppIcon.regular(
                            icon: node.data.isWiredConnection
                                ? getWifiSignalIconData(context, null)
                                : getWifiSignalIconData(
                                    context, node.data.signalStrength),
                          )
                        : null,
                    onTap: () {
                      ref.read(deviceDetailIdProvider.notifier).state =
                          node.data.deviceId;
                      if (node.type == AppTreeNodeType.device) {
                        context.pop();
                      } else if (node.data.isOnline) {
                        // Update the current target Id for node state
                        context.pushNamed(RouteNamed.nodeDetails);
                      } else {
                        context.pushNamed(RouteNamed.nodeOffline);
                      }
                    },
                  );
                },
                rootBuilder: (index, node) => InfoCell(
                  type: node.type,
                  name: node.data.location,
                  icon: getCharactersIcons(context).nodesDefault,
                ),
              ),
            ),
            // _buildOfflineNode(context, ref, topologyState.offlineRoot),
          ],
        ),
      ),
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
}
