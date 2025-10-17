import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/ethernet_port_connection_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class DashboardNetworks extends ConsumerStatefulWidget {
  const DashboardNetworks({super.key});

  @override
  ConsumerState<DashboardNetworks> createState() => _DashboardNetworksState();
}

class _DashboardNetworksState extends ConsumerState<DashboardNetworks> {
  late final TreeController<RouterTreeNode> treeController;

  @override
  void initState() {
    super.initState();
    treeController = TreeController<RouterTreeNode>(
      // Provide the root nodes that will be used as a starting point when
      // traversing your hierarchical data.
      roots: [
        OnlineTopologyNode(
            data: const TopologyModel(isOnline: true, location: 'Internet'),
            children: [])
      ],
      childrenProvider: (RouterTreeNode node) => node.children,
    );
  }

  @override
  void dispose() {
    super.dispose();
    treeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uptimeInt =
        ref.watch(dashboardHomeProvider.select((value) => value.uptime ?? 0));
    final uptime =
        DateFormatUtils.formatDuration(Duration(seconds: uptimeInt), null);
    final state = ref.watch(dashboardHomeProvider);
    final topologyState = ref.watch(instantTopologyProvider);
    treeController.roots = topologyState.root.children;
    treeController.expandAll();
    const topologyItemHeight = 96.0;
    const treeViewBaseHeight = 68.0;
    final routerLength =
        topologyState.root.children.firstOrNull?.toFlatList().length ?? 1;
    final double nodeTopologyHeight = ResponsiveLayout.isMobileLayout(context)
        ? routerLength * topologyItemHeight
        : min(routerLength * topologyItemHeight, 3 * topologyItemHeight);
    final hasLanPort =
        ref.watch(ethernetPortConnectionProvider).hasLanPort;
    final showAllTopology =
        ResponsiveLayout.isMobileLayout(context) || routerLength <= 3;
    final isLoading =
        (ref.watch(pollingProvider).value?.isReady ?? false) == false;
    return isLoading
        ? AppCard(
            padding: EdgeInsets.zero,
            child: SizedBox(
                width: double.infinity,
                height: 256,
                child: const LoadingTile()))
        : AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppGap.medium(),
                ResponsiveLayout(
                  desktop: !hasLanPort
                      ? _mobile(context, ref)
                      : state.isHorizontalLayout
                          ? _desktopHorizontal(context, ref)
                          : _desktopVertical(context, ref),
                  mobile: _mobile(context, ref),
                ),
                SizedBox(
                    height: isLoading
                        ? 188
                        : nodeTopologyHeight + treeViewBaseHeight,
                    child: TreeView<RouterTreeNode>(
                      treeController: treeController,
                      physics: showAllTopology
                          ? NeverScrollableScrollPhysics()
                          : ScrollPhysics(),
                      shrinkWrap: true,
                      nodeBuilder: (BuildContext context,
                          TreeEntry<RouterTreeNode> entry) {
                        return TreeIndentation(
                          entry: entry,
                          guide: IndentGuide.connectingLines(
                            color: Theme.of(context).colorScheme.onBackground,
                            indent: 24,
                            thickness: 1,
                            strokeJoin: StrokeJoin.miter,
                            pathModifier: (path) => TopologyNodeItem.buildPath(
                                path, entry.node, entry.node.data.isOnline),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                            child: TopologyNodeItem.simple(
                              node: entry.node,
                              actions: const [],
                              extra: entry.node.data.isMaster
                                  ? '${loc(context).uptime}: $uptime'
                                  : null,
                              onTap: entry.node.data.isOnline
                                  ? () {
                                      ref
                                          .read(nodeDetailIdProvider.notifier)
                                          .state = entry.node.data.deviceId;
                                      if (entry.node.data.isOnline) {
                                        // Update the current target Id for node state
                                        context
                                            .pushNamed(RouteNamed.nodeDetails);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        );
                      },
                    ))
              ],
            ),
          );
  }

  Widget _desktopHorizontal(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(instantTopologyProvider);
    final wanStatus = ref.watch(internetStatusProvider);

    final newFirmware = hasNewFirmware(ref);
    final isOnline = wanStatus == InternetStatus.online;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(loc(context).myNetwork),
        if (isOnline) ...[
          const AppGap.medium(),
          _firmwareStatusWidget(context, newFirmware),
        ],
        const AppGap.large2(),
        Row(
          children: [
            Expanded(
              child: _nodesInfoTile(
                context,
                ref,
                topologyState,
              ),
            ),
            const AppGap.gutter(),
            Expanded(
              child: _devicesInfoTile(
                context,
                ref,
                topologyState,
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _desktopVertical(BuildContext context, WidgetRef ref) {
    final wanStatus = ref.watch(internetStatusProvider);
    final topologyState = ref.watch(instantTopologyProvider);
    final newFirmware = hasNewFirmware(ref);
    final isOnline = wanStatus == InternetStatus.online;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall(loc(context).myNetwork),
            if (isOnline) _firmwareStatusWidget(context, newFirmware),
          ],
        ),
        const Spacer(),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _nodesInfoTile(context, ref, topologyState),
              const AppGap.gutter(),
              _devicesInfoTile(
                context,
                ref,
                topologyState,
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobile(BuildContext context, WidgetRef ref) {
    final newFirmware = hasNewFirmware(ref);
    final wanStatus = ref.watch(internetStatusProvider);
    final isOnline = wanStatus == InternetStatus.online;
    final topologyState = ref.watch(instantTopologyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.titleSmall(loc(context).myNetwork),
            if (isOnline) _firmwareStatusWidget(context, newFirmware),
          ],
        ),
        const AppGap.large2(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _nodesInfoTile(
              context,
              ref,
              topologyState,
            )),
            const AppGap.gutter(),
            Expanded(
              child: _devicesInfoTile(
                context,
                ref,
                topologyState,
              ),
            )
          ],
        ),
      ],
    );
  }

  bool hasNewFirmware(WidgetRef ref) {
    final nodesStatus =
        ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus));
    return nodesStatus?.any((element) => element.availableUpdate != null) ??
        false;
  }

  Widget _firmwareStatusWidget(BuildContext context, bool newFirmware) {
    return InkWell(
      onTap: newFirmware
          ? () => context.pushNamed(RouteNamed.firmwareUpdateDetail)
          : null,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          newFirmware
              ? AppText.labelMedium(
                  loc(context).updateFirmware,
                  color: Theme.of(context).colorScheme.primary,
                )
              : _firmwareUpdateToDateWidget(context),
          newFirmware
              ? Icon(
                  LinksysIcons.cloudDownload,
                  semanticLabel: 'cloud Download',
                  color: Theme.of(context).colorScheme.primary,
                )
              : Icon(
                  LinksysIcons.check,
                  semanticLabel: 'check',
                  color: Theme.of(context).colorSchemeExt.green,
                )
        ],
      ),
    );
  }

  Widget _firmwareUpdateToDateWidget(BuildContext context) {
    return AppStyledText(loc(context).dashboardFirmwareUpdateToDate,
        styleTags: {
          'span': Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(color: Theme.of(context).colorSchemeExt.green)
        },
        defaultTextStyle: Theme.of(context).textTheme.bodySmall,
        callbackTags: const {});
  }

  Widget _nodesInfoTile(
      BuildContext context, WidgetRef ref, InstantTopologyState state) {
    final nodes = state.root.children.firstOrNull?.toFlatList() ?? [];
    final hasOffline = nodes.any((element) => !element.data.isOnline);
    return _infoTile(
      iconData: hasOffline ? LinksysIcons.infoCircle : LinksysIcons.networkNode,
      iconColor: hasOffline ? Theme.of(context).colorScheme.error : null,
      text: nodes.length == 1 ? loc(context).node : loc(context).nodes,
      count: nodes.length,
      onTap: () {
        ref.read(topologySelectedIdProvider.notifier).state = '';
        context.pushNamed(RouteNamed.menuInstantTopology);
      },
    );
  }

  Widget _devicesInfoTile(
      BuildContext context, WidgetRef ref, InstantTopologyState state) {
    final externalDeviceCount = ref
        .watch(deviceManagerProvider)
        .externalDevices
        .where((e) => e.isOnline())
        .length;
    final nodes = state.root.children.firstOrNull?.toFlatList() ?? [];

    return _infoTile(
      text:
          externalDeviceCount == 1 ? loc(context).device : loc(context).devices,
      count: externalDeviceCount,
      iconData: LinksysIcons.devices,
      onTap: () {
        context.pushNamed(RouteNamed.menuInstantDevices);
      },
    );
  }

  Widget _infoTile({
    required String text,
    required int count,
    required IconData iconData,
    Color? iconColor,
    Widget? sub,
    VoidCallback? onTap,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall('$count'),
                Icon(
                  iconData,
                  semanticLabel: 'info icon',
                  size: 20,
                  color: iconColor,
                ),
                if (sub != null) sub,
              ],
            ),
            const AppGap.medium(),
            AppText.titleSmall(text),
          ],
        ),
      ),
    );
  }
}
