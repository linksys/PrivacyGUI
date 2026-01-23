import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/data/providers/node_internet_status_provider.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/topology_adapter.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/views/components/core/dashboard_loading_wrapper.dart';
import 'package:privacy_gui/page/instant_topology/providers/_providers.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Widget displaying network topology and nodes.
///
/// Supports three display modes:
/// - [DisplayMode.compact]: Minimal view with node/device counts only
/// - [DisplayMode.normal]: Standard view with topology tree
/// - [DisplayMode.expanded]: Full view with detailed topology
class DashboardNetworks extends ConsumerWidget {
  const DashboardNetworks({
    super.key,
    this.displayMode = DisplayMode.normal,
    this.useAppCard = true,
  });

  /// The display mode for this widget
  final DisplayMode displayMode;

  /// Whether to wrap the content in an AppCard (default true).
  final bool useAppCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DashboardLoadingWrapper(
      loadingHeight: _getLoadingHeight(),
      builder: (context, ref) => _buildContent(context, ref),
    );
  }

  double _getLoadingHeight() {
    return switch (displayMode) {
      DisplayMode.compact => 120,
      DisplayMode.normal => 250,
      DisplayMode.expanded => 350,
    };
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return switch (displayMode) {
      DisplayMode.compact => _buildCompactView(context, ref),
      DisplayMode.normal => _buildNormalView(context, ref),
      DisplayMode.expanded => _buildExpandedView(context, ref),
    };
  }

  /// Compact view: Nodes and devices count displayed side by side
  Widget _buildCompactView(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(instantTopologyProvider);
    final nodes = topologyState.root.children.firstOrNull?.toFlatList() ?? [];
    final hasOffline = nodes.any((element) => !element.data.isOnline);
    final externalDeviceCount = ref
        .watch(deviceManagerProvider)
        .externalDevices
        .where((e) => e.isOnline())
        .length;

    final content = InkWell(
      onTap: () => context.pushNamed(RouteNamed.menuInstantTopology),
      child: Row(
        children: [
          // Nodes section
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                hasOffline
                    ? AppIcon.font(AppFontIcons.infoCircle,
                        color: Theme.of(context).colorScheme.error, size: 18)
                    : AppIcon.font(AppFontIcons.networkNode, size: 18),
                AppGap.sm(),
                AppText.titleMedium('${nodes.length}'),
                AppGap.xs(),
                AppText.bodySmall(
                  nodes.length == 1 ? loc(context).node : loc(context).nodes,
                ),
              ],
            ),
          ),
          SizedBox(height: 36, child: VerticalDivider()),
          // Devices section
          Expanded(
            child: InkWell(
              onTap: () => context.pushNamed(RouteNamed.menuInstantDevices),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon.font(AppFontIcons.devices, size: 18),
                  AppGap.sm(),
                  AppText.titleMedium('$externalDeviceCount'),
                  AppGap.xs(),
                  AppText.bodySmall(
                    externalDeviceCount == 1
                        ? loc(context).device
                        : loc(context).devices,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (useAppCard) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );
  }

  /// Normal view: Standard view with topology tree (existing implementation)
  Widget _buildNormalView(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
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

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppGap.lg(),
        _buildNetworkHeader(context, ref, state),
        SizedBox(
          height: nodeTopologyHeight + treeViewBaseHeight,
          child: _buildTopologyView(
            context,
            ref,
            meshTopology,
            topologyState,
            showAllTopology,
          ),
        ),
      ],
    );

    if (useAppCard) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );
  }

  /// Expanded view: Full topology with larger tree and more details
  Widget _buildExpandedView(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    final topologyState = ref.watch(instantTopologyProvider);

    // Convert topology data to ui_kit format
    final meshTopology = TopologyAdapter.convert(topologyState.root.children);

    // Calculate expanded topology height (show more nodes)
    const topologyItemHeight = 80.0;
    const treeViewBaseHeight = 80.0;
    final routerLength =
        topologyState.root.children.firstOrNull?.toFlatList().length ?? 1;
    final double nodeTopologyHeight = routerLength * topologyItemHeight;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppGap.lg(),
        _buildNetworkHeader(context, ref, state),
        SizedBox(
          height: nodeTopologyHeight + treeViewBaseHeight,
          child: _buildTopologyView(
            context,
            ref,
            meshTopology,
            topologyState,
            true, // Always show all in expanded mode
          ),
        ),
      ],
    );

    if (useAppCard) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );
  }

  /// Unified network header with title, firmware status, and info tiles.
  Widget _buildNetworkHeader(
    BuildContext context,
    WidgetRef ref,
    DashboardHomeState state,
  ) {
    final topologyState = ref.watch(instantTopologyProvider);
    final wanStatus = ref.watch(internetStatusProvider);
    final newFirmware = _hasNewFirmware(ref);
    final isOnline = wanStatus == InternetStatus.online;
    final hasLanPort =
        ref.read(dashboardHomeProvider).lanPortConnections.isNotEmpty;

    // Determine layout variant
    final layoutVariant = DashboardLayoutVariant.fromContext(
      context,
      hasLanPort: hasLanPort,
      isHorizontalLayout: state.isHorizontalLayout,
    );
    final useVerticalLayout =
        layoutVariant == DashboardLayoutVariant.desktopVertical ||
            layoutVariant == DashboardLayoutVariant.tabletVertical;

    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(loc(context).myNetwork),
        if (isOnline) _firmwareStatusWidget(context, newFirmware),
      ],
    );

    final infoTilesSection = Row(
      children: [
        Expanded(child: _nodesInfoTile(context, ref, topologyState)),
        AppGap.gutter(),
        Expanded(child: _devicesInfoTile(context, ref, topologyState)),
      ],
    );

    // Desktop vertical layout: title on left, info tiles on right
    if (useVerticalLayout) {
      return Row(
        children: [
          titleSection,
          const Spacer(),
          Expanded(flex: 3, child: infoTilesSection),
        ],
      );
    }

    // Mobile and desktop horizontal layout: title on top, info tiles below
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleSection,
        AppGap.xxl(),
        infoTilesSection,
      ],
    );
  }

  Widget _buildTopologyView(
    BuildContext context,
    WidgetRef ref,
    MeshTopology meshTopology,
    InstantTopologyState topologyState,
    bool showAllTopology,
  ) {
    return AppTopology(
      topology: meshTopology,
      viewMode: TopologyViewMode.tree,
      enableAnimation: !showAllTopology,
      onNodeTap: TopologyAdapter.wrapNodeTapCallback(
        topologyState.root.children,
        (RouterTreeNode node) {
          if (node.data.isOnline) {
            ref.read(nodeDetailIdProvider.notifier).state = node.data.deviceId;
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
    );
  }

  bool _hasNewFirmware(WidgetRef ref) {
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
              : AppStyledText(text: loc(context).dashboardFirmwareUpdateToDate),
          newFirmware
              ? AppIcon.font(
                  AppFontIcons.cloudDownload,
                  color: Theme.of(context).colorScheme.primary,
                )
              : AppIcon.font(
                  AppFontIcons.check,
                  color: Theme.of(context)
                          .extension<AppColorScheme>()
                          ?.semanticSuccess ??
                      Colors.green,
                ),
        ],
      ),
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
      onTap: () => context.pushNamed(RouteNamed.menuInstantDevices),
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
                Flexible(child: AppText.titleSmall('$count')),
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
