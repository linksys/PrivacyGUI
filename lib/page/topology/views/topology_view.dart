import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/topology/_topology.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:privacygui_widgets/widgets/topology/tree_item.dart';
import 'package:privacygui_widgets/widgets/topology/tree_node.dart';
import 'package:privacygui_widgets/widgets/topology/tree_view.dart';

class TopologyView extends ArgumentsConsumerStatefulView {
  const TopologyView({super.key, super.args});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopologyViewState();
}

class _TopologyViewState extends ConsumerState<TopologyView> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final topologyState = ref.watch(topologyProvider);

    final isShowingDeviceChain =
        ref.watch(topologySelectedIdProvider).isNotEmpty;
    final autoOnboarding =
        ref.read(topologyProvider.notifier).isSupportAutoOnboarding();
    return LayoutBuilder(builder: (context, constraint) {
      return _isLoading
          ? AppFullScreenSpinner(
              text: loc(context).processing,
            )
          : StyledAppPageView(
              // scrollable: true,
              padding: EdgeInsets.zero,
              title: loc(context).node,
              actions: [
                if (autoOnboarding)
                  AppTextButton.noPadding(
                    loc(context).addNodes,
                    icon: LinksysIcons.add,
                    onTap: () {
                      context.pushNamed(RouteNamed.addNodes).then((result) {
                        if (result is bool && result) {
                          _showMoveChildNodesModal();
                        }
                      });
                    },
                  )
              ],
              child: AppBasicLayout(
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                        child: AppTreeView(
                      onlineRoot: topologyState.onlineRoot
                        ..width = ResponsiveLayout.isMobileLayout(context)
                            ? constraint.maxWidth
                            : 280,
                      offlineRoot: topologyState.offlineRoot,
                      itemBuilder: (node) {
                        // return Container(color: Colors.amber);
                        return switch (node.runtimeType) {
                          OnlineTopologyNode =>
                            _buildHeader(context, ref, node),
                          OfflineTopologyNode =>
                            _buildOfflineHeader(context, ref, node),
                          RouterTopologyNode =>
                            topologyState.onlineRoot.toFlatList().length == 2
                                ? _buildNodeLarge(context, ref, node)
                                : _buildNode(context, ref, node),
                          _ => _buildHeader(context, ref, node),
                        };
                      },
                    )),
                  ],
                ),
              ),
            );
    });
  }

  Widget _buildNodeLarge(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return AppTreeNodeItemLarge(
      name: node.data.location,
      image: CustomTheme.of(context).images.devices.getByName(node.data.icon),
      status: node.data.isOnline
          ? loc(context).nDevices(node.data.connectedDeviceCount)
          : loc(context).offline,
      tail: node.data.isOnline
          ? Icon(
              node.data.isWiredConnection
                  ? WiFiUtils.getWifiSignalIconData(context, null)
                  : WiFiUtils.getWifiSignalIconData(
                      context, node.data.signalStrength),
              semanticLabel: 'signal strength icon',
            )
          : null,
      background: node.data.isOnline
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surfaceVariant,
      onTap: () {
        onNodeTap(context, ref, node);
      },
    );
  }

  Widget _buildNode(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return AppTreeNodeItem(
      name: node.data.location,
      image: CustomTheme.of(context).images.devices.getByName(node.data.icon),
      status: node.data.isOnline
          ? loc(context).nDevices(node.data.connectedDeviceCount)
          : 'Offline',
      tail: node.data.isOnline
          ? Icon(
              node.data.isWiredConnection
                  ? WiFiUtils.getWifiSignalIconData(context, null)
                  : WiFiUtils.getWifiSignalIconData(context, node.data.signalStrength),
              semanticLabel: 'signal strength icon',
            )
          : null,
      background: node.data.isOnline
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surfaceVariant,
      onTap: () {
        onNodeTap(context, ref, node);
      },
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return BorderInfoCell(
      name: node.data.location == 'Internet'
          ? loc(context).internet
          : node.data.location,
      icon: node is OnlineTopologyNode ? LinksysIcons.language : null,
      showConnector: node is OnlineTopologyNode,
      width: node.width,
    );
  }

  Widget _buildOfflineHeader(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoCell(
          name: loc(context).nNodesOffline(node.children.length),
        ),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          children:
              node.children.map((e) => _buildNode(context, ref, e)).toList(),
        ),
      ],
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
    ref.read(nodeDetailIdProvider.notifier).state = node.data.deviceId;
    if (node is DeviceTopologyNode) {
      context.pop();
    } else if (node.data.isOnline) {
      // Update the current target Id for node state
      context.pushNamed(RouteNamed.nodeDetails);
    } else {
      // context.pushNamed(RouteNamed.nodeOffline);
      _showOfflineNodeModal(node).then((value) {
        if (value == 'nightMode') {
        } else if (value == 'remove') {
          _showRemoveNodeModal(node).then((value) {
            if ((value ?? false)) {
              // Do remove
              _doRemoveNode(node).then((result) {
                showSimpleSnackBar(context, loc(context).nodeRemoved);
              }).onError((error, stackTrace) {
                showSimpleSnackBar(context, loc(context).unknownError);
              });
            }
          });
        }
      });
    }
  }

  Future<String?> _showOfflineNodeModal(RouterTreeNode node) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).modalOfflineNodeTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AbsorbPointer(
                    child: _buildNode(context, ref, node),
                  ),
                ),
                AppBulletList(
                  style: AppBulletStyle.number,
                  itemSpacing: 24,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                            loc(context).modalOfflineNodeCheckTitle1),
                        AppText.bodyMedium(
                            loc(context).modalOfflineNodeCheckDesc1),
                        const AppGap.medium(),
                        AppTextButton.noPadding(
                          loc(context).modalOfflineNodeGoToNightMode,
                          onTap: () {
                            context.pop('nightMode');
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                            loc(context).modalOfflineNodeCheckTitle2),
                        AppText.bodyMedium(
                            loc(context).modalOfflineNodeCheckDesc2),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                            loc(context).modalOfflineNodeCheckTitle3),
                        AppText.bodyMedium(
                            loc(context).modalOfflineNodeCheckDesc3),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppTextButton(
                    loc(context).modalOfflineRemoveNodeFromNetwork,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      context.pop('remove');
                    },
                  ),
                ),
                const AppGap.medium(),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppTextButton(
                    loc(context).close,
                    onTap: () {
                      context.pop();
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<bool?> _showRemoveNodeModal(RouterTreeNode node) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).modalOfflineNodeTitle),
            actions: [
              AppTextButton.noPadding(
                loc(context).cancel,
                onTap: () => context.pop(),
              ),
              AppTextButton.noPadding(
                loc(context).removeNode,
                color: Theme.of(context).colorScheme.error,
                onTap: () => context.pop(true),
              )
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AppText.bodyMedium(
                      loc(context).modalRemoveNodeDesc(node.data.location)),
                ),
              ],
            ),
          );
        });
  }

  Future<void> _doRemoveNode(RouterTreeNode node) {
    setState(() {
      _isLoading = true;
    });
    final targetId = node.data.deviceId;
    return ref
        .read(deviceManagerProvider.notifier)
        .deleteDevices(deviceIds: [targetId]).then((value) {
      setState(() {
        _isLoading = false;
        context.goNamed(RouteNamed.menuInstantTopology);
      });
    }).onError((error, stackTrace) {
      logger.e(error.toString());
      setState(() {
        _isLoading = false;
      });
      throw error ?? Exception('Unknown Error');
    });
  }

  _showMoveChildNodesModal() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).modalMoveChildNodesTitle),
            actions: [
              AppTextButton(
                loc(context).close,
                onTap: () {
                  context.pop();
                },
              ),
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.bodyMedium(loc(context).modalMoveChildNodesDesc),
                const AppGap.large2(),
                SvgPicture(
                  CustomTheme.of(context).images.imgMoveNodes,
                  semanticsLabel: 'move nodes image',
                ),
              ],
            ),
          );
        });
  }
}
