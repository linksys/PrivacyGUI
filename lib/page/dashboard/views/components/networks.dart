import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
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
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;
    final showAllTopology =
        ResponsiveLayout.isMobileLayout(context) || routerLength <= 3;
    final isLoading = ref.watch(deviceManagerProvider).deviceList.isEmpty;

    return AppCard(
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
              height: isLoading ? 188 : nodeTopologyHeight + treeViewBaseHeight,
              child: TreeView<RouterTreeNode>(
                treeController: treeController,
                physics: showAllTopology
                    ? NeverScrollableScrollPhysics()
                    : ScrollPhysics(),
                shrinkWrap: true,
                nodeBuilder:
                    (BuildContext context, TreeEntry<RouterTreeNode> entry) {
                  return TreeIndentation(
                    entry: entry,
                    guide: IndentGuide.connectingLines(
                        color: Theme.of(context).colorScheme.onBackground,
                        indent: 24,
                        thickness: 1,
                        strokeJoin: StrokeJoin.miter),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                      child: SimpleTreeNodeItem(
                        node: entry.node,
                        extra: entry.node.data.isMaster
                            ? '${loc(context).uptime}: $uptime'
                            : null,
                        onTap: entry.node.data.isOnline && !isBridge
                            ? () {
                                ref.read(nodeDetailIdProvider.notifier).state =
                                    entry.node.data.deviceId;
                                if (entry.node.data.isOnline) {
                                  // Update the current target Id for node state
                                  context.pushNamed(RouteNamed.nodeDetails);
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
    final wanStatus = ref.watch(nodeWanStatusProvider);

    final newFirmware = hasNewFirmware(ref);
    final isOnline = wanStatus == NodeWANStatus.online;

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
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final topologyState = ref.watch(instantTopologyProvider);
    final newFirmware = hasNewFirmware(ref);
    final isOnline = wanStatus == NodeWANStatus.online;

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
    final wanStatus = ref.watch(nodeWanStatusProvider);
    final isOnline = wanStatus == NodeWANStatus.online;
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;
    final hasOffline = nodes.any((element) => !element.data.isOnline);
    return _infoTile(
      iconData: hasOffline ? LinksysIcons.infoCircle : LinksysIcons.networkNode,
      iconColor: hasOffline ? Theme.of(context).colorScheme.error : null,
      text: nodes.length == 1 ? loc(context).node : loc(context).nodes,
      count: nodes.length,
      onTap: isBridge
          ? null
          : () {
              ref.read(topologySelectedIdProvider.notifier).state = '';
              context.pushNamed(RouteNamed.menuInstantTopology);
            },
    );
  }

  Widget _devicesInfoTile(
      BuildContext context, WidgetRef ref, InstantTopologyState state) {
    final nodes = state.root.children.firstOrNull?.toFlatList() ?? [];
    final isBridge = ref.watch(dashboardHomeProvider).isBridgeMode;
    final count = nodes.fold(
        0,
        (previousValue, element) =>
            previousValue += element.data.connectedDeviceCount);
    return _infoTile(
      text: count == 1 ? loc(context).device : loc(context).devices,
      count: count,
      iconData: LinksysIcons.devices,
      onTap: isBridge
          ? null
          : () {
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
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall('$count'),
                const AppGap.medium(),
                AppText.titleSmall(text),
              ],
            ),
            Icon(
              iconData,
              semanticLabel: 'info icon',
              size: 20,
              color: iconColor,
            ),
            if (sub != null) sub,
          ],
        ),
      ),
    );
  }
}

final _onlineRoot = OnlineTopologyNode(
  data: const TopologyModel(isOnline: true, location: 'Internet'),
  children: [],
);

final _masterNode = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-MASTER-DEVICEID-000001',
    location: 'Living room',
    isMaster: true,
    isOnline: true,
    isWiredConnection: true,
    signalStrength: 0,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 30,
  ),
  children: [],
);

final _slaveNode1 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Kitchen',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -44,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 20,
  ),
  children: [],
);

final _slaveNode2 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000002',
    location: 'Basement',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -66,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 17,
  ),
  children: [],
);

final _slaveNode3 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000003',
    location: 'Bed room 1',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -58,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 7,
  ),
  children: [],
);

final _slaveNode4 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000004',
    location: 'Bed room 2',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -55,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 1,
  ),
  children: [],
);

final _slaveNode5 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000005',
    location: 'A super long long long long long long cool name',
    isMaster: false,
    isOnline: true,
    isWiredConnection: false,
    signalStrength: -70,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 999,
  ),
  children: [],
);

final _slaveOfflineNode1 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000001',
    location: 'Kitchen',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -49,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 20,
  ),
  children: [],
);

final _slaveOfflineNode2 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000002',
    location: 'Basement',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -78,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 17,
  ),
  children: [],
);

final _slaveOfflineNode3 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000003',
    location: 'Bed room 1',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -55,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 7,
  ),
  children: [],
);

final _slaveOfflineNode4 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000004',
    location: 'Bed room 2',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -58,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 1,
  ),
  children: [],
);

final _slaveOfflineNode5 = RouterTopologyNode(
  data: const TopologyModel(
    deviceId: 'ROUTER-SLAVE-DEVICEID-000005',
    location: 'A super long long long long long long cool name',
    isMaster: false,
    isOnline: false,
    isWiredConnection: false,
    signalStrength: -70,
    isRouter: true,
    icon: 'routerMx6200',
    connectedDeviceCount: 999,
  ),
  children: [],
);

/// State
final testTopologyMasterOnlyState = InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot,
    ),
);

final testTopology1SlaveState = InstantTopologyState(
  root: _onlineRoot
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveNode1..parent = _masterNode),
    ),
);

final testTopology2SlavesStarState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode2
          ..children.clear()
          ..parent = _masterNode
      ])),
);

final testTopology2SlavesDaisyState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode
          ..children.addAll([
            _slaveNode2
              ..children.clear()
              ..parent = _slaveNode1
          ]),
      ])),
);

final testTopology5SlavesStarState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode3
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode4
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode5
          ..children.clear()
          ..parent = _masterNode,
      ])),
);

final testTopology5SlavesDaisyState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode
          ..children.addAll([
            _slaveNode2
              ..children.clear()
              ..parent = _slaveNode1
              ..children.addAll([
                _slaveNode3
                  ..children.clear()
                  ..parent = _slaveNode2
                  ..children.addAll([
                    _slaveNode4
                      ..children.clear()
                      ..parent = _slaveNode3
                      ..children.addAll([
                        _slaveNode5
                          ..children.clear()
                          ..parent = _slaveNode4,
                      ]),
                  ]),
              ]),
          ]),
      ])),
);

final testTopology5SlavesMixedState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode
          ..children.addAll([
            _slaveNode2
              ..children.clear()
              ..parent = _slaveNode1,
            _slaveNode3
              ..children.clear()
              ..parent = _slaveNode1
              ..children.addAll([
                _slaveNode4
                  ..children.clear()
                  ..parent = _slaveNode3,
                _slaveNode5
                  ..children.clear()
                  ..parent = _slaveNode3,
              ]),
          ]),
      ])),
);

final testTopology1OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(
          _slaveOfflineNode1
            ..children.clear()
            ..parent = _masterNode,
        ),
    ),
);

final testTopology2OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(
      _masterNode
        ..children.clear()
        ..parent = _onlineRoot
        ..children.add(_slaveOfflineNode1
          ..children.clear()
          ..parent = _masterNode)
        ..children.add(_slaveOfflineNode2
          ..children.clear()
          ..parent = _masterNode),
    ),
);

final testTopology3OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode3
          ..children.clear()
          ..parent = _masterNode,
      ])),
);

final testTopology4OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode3
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode4
          ..children.clear()
          ..parent = _masterNode,
      ])),
);

final testTopology5OfflineState = InstantTopologyState(
  root: _onlineRoot
    ..children.clear()
    ..children.add(_masterNode
      ..parent = _onlineRoot
      ..children.clear()
      ..children.addAll([
        _slaveOfflineNode1
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode2
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode3
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode4
          ..children.clear()
          ..parent = _masterNode,
        _slaveOfflineNode5
          ..children.clear()
          ..parent = _masterNode,
      ])),
);
