import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/topology_adapter.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacy_gui/page/dashboard/views/components/loading_tile.dart';

import 'package:ui_kit_library/ui_kit.dart';

class DashboardNetworks extends ConsumerStatefulWidget {
  const DashboardNetworks({super.key});

  @override
  ConsumerState<DashboardNetworks> createState() => _DashboardNetworksState();
}

class _DashboardNetworksState extends ConsumerState<DashboardNetworks> {

  @override
  Widget build(BuildContext context) {
    final uptimeInt =
        ref.watch(dashboardHomeProvider.select((value) => value.uptime ?? 0));
    final uptime =
        DateFormatUtils.formatDuration(Duration(seconds: uptimeInt), null);
    final state = ref.watch(dashboardHomeProvider);
    final topologyState = ref.watch(instantTopologyProvider);

    // Convert topology data to ui_kit format
    final meshTopology = TopologyAdapter.convert(topologyState.root.children);

    const topologyItemHeight = 96.0;
    const treeViewBaseHeight = 68.0;
    final routerLength =
        topologyState.root.children.firstOrNull?.toFlatList().length ?? 1;
    final double nodeTopologyHeight = ResponsiveLayout.isMobileLayout(context)
        ? routerLength * topologyItemHeight
        : min(routerLength * topologyItemHeight, 3 * topologyItemHeight);
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;
    final showAllTopology = ResponsiveLayout.isMobileLayout(context) || routerLength <= 3;
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
                AppGap.lg(),
                AppResponsiveLayout(
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
                  child: AppTopology(
                    topology: meshTopology,
                    viewMode: TopologyViewMode.tree, // Force tree view for dashboard
                    enableAnimation: !showAllTopology, // Disable animation for mobile/small screens
                    onNodeTap: TopologyAdapter.wrapNodeTapCallback(
                      topologyState.root.children,
                      (RouterTreeNode node) {
                        if (node.data.isOnline) {
                          ref
                              .read(nodeDetailIdProvider.notifier)
                              .state = node.data.deviceId;
                          context.pushNamed(RouteNamed.nodeDetails);
                        }
                      },
                    ),
                    nodeContentBuilder: (context, meshNode, style, isOffline) {
                      // Find original topology data for extra info (like uptime)
                      final originalNode = _findOriginalNode(
                        topologyState.root.children,
                        meshNode.id,
                      );

                      // Create custom content that matches the original design
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            meshNode.iconData ?? Icons.devices,
                            size: 20,
                            color: isOffline
                                ? Theme.of(context).colorScheme.outline
                                : Theme.of(context).colorScheme.onPrimary,
                          ),
                          if (originalNode?.data.isMaster == true) ...[
                            AppGap.xs(),
                            AppText.labelSmall(
                              '${loc(context).uptime}: $uptime',
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                )
              ],
            ),
          );
  }

  /// Find the original RouterTreeNode by mesh node ID.
  RouterTreeNode? _findOriginalNode(List<RouterTreeNode> rootNodes, String nodeId) {
    for (final rootNode in rootNodes) {
      final flatNodes = rootNode.toFlatList();
      for (final node in flatNodes) {
        if (TopologyAdapter.getNodeId(node) == nodeId) {
          return node;
        }
      }
    }
    return null;
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
          AppGap.lg(),
          _firmwareStatusWidget(context, newFirmware),
        ],
        AppGap.xxl(),
        Row(
          children: [
            Expanded(
              child: _nodesInfoTile(
                context,
                ref,
                topologyState,
              ),
            ),
            AppGap.gutter(),
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
              AppGap.gutter(),
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
        AppGap.xxl(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _nodesInfoTile(
              context,
              ref,
              topologyState,
            )),
            AppGap.gutter(),
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
              ? AppIcon.font(
                  AppFontIcons.cloudDownload,
                  color: Theme.of(context).colorScheme.primary,
                )
              : AppIcon.font(
                  AppFontIcons.check,
                  color: Theme.of(context).extension<AppColorScheme>()?.semanticSuccess ?? Colors.green,
                )
        ],
      ),
    );
  }

  Widget _firmwareUpdateToDateWidget(BuildContext context) {
    return AppStyledText(
      text: loc(context).dashboardFirmwareUpdateToDate,
    );
  }

  Widget _nodesInfoTile(
      BuildContext context, WidgetRef ref, InstantTopologyState state) {
    final nodes = state.root.children.firstOrNull?.toFlatList() ?? [];
    final hasOffline = nodes.any((element) => !element.data.isOnline);
    return _infoTile(
      icon: hasOffline
          ? AppIcon.font(AppFontIcons.infoCircle,
              color: Theme.of(context).colorScheme.error)
          : AppIcon.font(AppFontIcons.networkNode),
      // iconColor is now handled inside the AppIcon or ignored if passed
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

    return _infoTile(
      text:
          externalDeviceCount == 1 ? loc(context).device : loc(context).devices,
      count: externalDeviceCount,
      icon: AppIcon.font(AppFontIcons.devices),
      onTap: () {
        context.pushNamed(RouteNamed.menuInstantDevices);
      },
    );
  }

  Widget _infoTile({
    required String text,
    required int count,
    required Widget icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.titleSmall('$count'),
                icon,
              ],
            ),
            AppGap.lg(),
            AppText.bodySmall(text),
          ],
        ),
      ),
    );
  }
}
