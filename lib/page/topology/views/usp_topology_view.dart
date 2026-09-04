import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/components/views/service_error_view.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_content_builder.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:privacy_gui/page/topology/views/components/node_detail_popup.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Full-page interactive topology view.
///
/// Displays the network topology using [AppTopology] in interactive mode.
/// Tapping a router/extender node navigates to Node Detail; tapping a client
/// navigates to Device Detail.
class UspTopologyView extends ConsumerStatefulWidget {
  const UspTopologyView({super.key});

  @override
  ConsumerState<UspTopologyView> createState() => _UspTopologyViewState();
}

class _UspTopologyViewState extends ConsumerState<UspTopologyView> {
  bool _showDevices = true;

  @override
  Widget build(BuildContext context) {
    final asyncDevices = ref.watch(devicesDataProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: loc(context).networkTopology,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
      onRefresh: () => ref.refresh(devicesDataProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncDevices.when(
          loading: () => const Center(child: AppLoader()),
          error: (error, _) => ServiceErrorView(
            error: error is ServiceError ? error : null,
            title: loc(context).unableToLoadTopology,
            onRetry: () => ref.invalidate(devicesDataProvider),
          ),
          data: (data) {
            final sysInfo = ref.read(systemInfoDataProvider).valueOrNull?.model;
            if (sysInfo == null) {
              return const SizedBox.shrink();
            }
            final topology = UspTopologyBuilder.buildFromMeshNetwork(
              meshNetwork: data.meshNetwork,
              info: sysInfo,
            );

            return _buildTopologyCard(context, topology);
          },
        );
      },
    );
  }

  Widget _buildTopologyCard(BuildContext context, MeshTopology topology) {
    final router = GoRouter.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        Row(
          children: [
            Expanded(child: const SizedBox.shrink()),
            AppText.labelMedium(
              'Show Devices',
              color: colorScheme.onSurfaceVariant,
            ),
            AppGap.sm(),
            AppSwitch(
              value: _showDevices,
              onChanged: (value) => setState(() => _showDevices = value),
            ),
          ],
        ),
        AppGap.sm(),
        // Topology view
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: _withTopologyAnimation(
            context,
            AppTopology(
              topology: topology,
              viewMode: TopologyViewMode.auto,
              layoutMode: LayoutRecommendation.auto,
              clientVisibility: _showDevices
                  ? ClientVisibility.always
                  : ClientVisibility.onHover,
              nodeRendererRegistry: NodeRendererRegistry.unified,
              enableAnimation: true,
              interactive: false,
              onNodeTap: (nodeId) =>
                  _navigateByNodeId(router, nodeId, topology),
              nodeContentBuilder: TopologyNodeContentBuilder.build,
              treeConfig: TopologyTreeConfiguration(
                titleBuilder: (node) => node.name,
                subtitleBuilder: (node) => node.extra ?? '',
                preferAnimationNode: true,
                showStatusIndicator: true,
                showStatusText: true,
                expanded: true,
              ),
              nodeDetailConfig: NodeDetailConfig(
                trigger: NodeDetailTrigger.tap,
                mode: NodeDetailMode.floatingPanel,
                detailBuilder: (ctx, node, metadata) => NodeDetailPopup.builder(
                    ctx, node, metadata,
                    showDetailsButton: true),
              ),
              nodeComparator: _nodeComparator,
            ),
          ),
        ),
      ],
    );
  }

  /// Navigate by MeshNode id — used by tree view onNodeTap.
  void _navigateByNodeId(
      GoRouter router, String nodeId, MeshTopology topology) {
    final node = topology.nodes.where((n) => n.id == nodeId).firstOrNull;
    if (node == null) return;

    final target = topologyNavTargetFor(node);
    if (target == null) return;

    router.pushNamed(target.route, queryParameters: target.queryParameters);
  }

  /// Comparator for sorting nodes: online first, then infra nodes before clients, then alphabetical.
  static int _nodeComparator(MeshNode a, MeshNode b) {
    // 1. Online before offline
    if (a.isOffline && !b.isOffline) return 1;
    if (!a.isOffline && b.isOffline) return -1;
    // 2. Node type priority: gateway > extender > client > internet
    final typePriority = _nodeTypePriority(a.type) - _nodeTypePriority(b.type);
    if (typePriority != 0) return typePriority;
    // 3. Alphabetical by name
    return a.name.compareTo(b.name);
  }

  static int _nodeTypePriority(MeshNodeType type) => switch (type) {
        MeshNodeType.gateway => 0,
        MeshNodeType.extender => 1,
        MeshNodeType.client => 2,
        MeshNodeType.internet => 3,
      };

  Widget _withTopologyAnimation(BuildContext context, Widget child) {
    final appTheme = Theme.of(context).extension<AppDesignTheme>();
    if (appTheme == null) return child;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          appTheme.copyWith(
            visualEffects:
                appTheme.visualEffects | AppThemeConfig.effectTopologyAnimation,
            // Increase spacing to prevent client nodes overlapping with gateway
            topologySpec: appTheme.topologySpec.copyWith(
              nodeSpacing: appTheme.topologySpec.nodeSpacing * 2.2,
              orbitRadius: appTheme.topologySpec.orbitRadius * 2.2,
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// A resolved navigation target for a tapped topology node: the named route
/// plus its query parameters.
@immutable
class TopologyNavTarget {
  const TopologyNavTarget(this.route, this.queryParameters);

  final String route;
  final Map<String, String> queryParameters;
}

/// Pure mapping from a tapped [MeshNode] to its navigation target, or `null`
/// when the node is not navigable.
///
/// Extracted so the decision is unit-testable without a widget/router.
///
/// The two node families are deliberately treated differently:
///
/// - **Clients** are navigable regardless of status. An offline client opens
///   its Device Detail page just like it does from the device list and from a
///   node's "Connected devices" list; the destination already renders the
///   correct online/offline state, so there is nothing to gate against.
/// - **Gateway / extender** keep an offline gate. Their Node Detail page still
///   hardcodes an active status badge, so opening it for a powered-off node
///   would show a wrong (green) status. That is tracked by #1465; until it is
///   fixed, the node arm stays gated. Do NOT "tidy" the client arm to match
///   the node arm — the difference is intentional.
@visibleForTesting
TopologyNavTarget? topologyNavTargetFor(MeshNode node) {
  switch (node.type) {
    case MeshNodeType.gateway:
    case MeshNodeType.extender:
      // Offline gate for infra nodes only — see #1465 (doc above).
      if (node.status == MeshNodeStatus.offline) return null;
      final deviceId = node.metadata?['deviceId'] as String?;
      if (deviceId == null || deviceId.isEmpty) return null;
      return TopologyNavTarget(
        RouteNamed.uspNodeDetail,
        {'deviceId': deviceId},
      );
    case MeshNodeType.client:
      final mac = node.metadata?['mac'] as String?;
      if (mac == null || mac.isEmpty) return null;
      return TopologyNavTarget(
        RouteNamed.uspDeviceDetail,
        {'mac': mac},
      );
    case MeshNodeType.internet:
      return null;
  }
}
