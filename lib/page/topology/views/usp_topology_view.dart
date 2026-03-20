import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Full-page interactive topology view.
///
/// Displays the network topology using [AppTopology] in interactive mode.
/// Tapping a router/extender node navigates to Node Detail; tapping a client
/// navigates to Device Detail.
class UspTopologyView extends ConsumerWidget {
  const UspTopologyView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDevices = ref.watch(devicesDataProvider);

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Network Topology',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      onBackTap: () => context.canPop()
          ? context.pop()
          : context.goNamed(RouteNamed.uspDashboard),
      onRefresh: () => ref.refresh(devicesDataProvider.future),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        return asyncDevices.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.titleMedium('Unable to load topology'),
                AppGap.md(),
                AppButton.text(
                  label: 'Retry',
                  onTap: () => ref.invalidate(devicesDataProvider),
                ),
              ],
            ),
          ),
          data: (data) {
            final sysInfo = ref.read(systemInfoDataProvider).valueOrNull?.model;
            if (sysInfo == null) return const SizedBox.shrink();
            final topology = UspTopologyBuilder.build(
              info: sysInfo,
              devices: data.deviceModels,
              meshNodes: data.meshTopology.nodes,
              coverageColor: Theme.of(context).colorScheme.primary,
            );

            return _buildTopologyCard(context, topology);
          },
        );
      },
    );
  }

  Widget _buildTopologyCard(BuildContext context, MeshTopology topology) {
    // Capture GoRouter from the outer context — the panel's context inside
    // the graph view's Stack may not reliably resolve GoRouter.
    final router = GoRouter.of(context);

    return AppCard(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: _withTopologyAnimation(
          context,
          AppTopology(
            topology: topology,
            viewMode: TopologyViewMode.auto,
            layoutMode: LayoutRecommendation.auto,
            clientVisibility: ClientVisibility.clustered,
            nodeRendererRegistry: NodeRendererRegistry.differentiated,
            enableAnimation: true,
            interactive: true,
            // Tree view (mobile): navigate directly on tap.
            onNodeTap: (nodeId) => _navigateByNodeId(router, nodeId, topology),
            treeConfig: TopologyTreeConfiguration(
              titleBuilder: (node) => node.name,
              subtitleBuilder: (node) => node.extra ?? '',
              preferAnimationNode: true,
              showStatusIndicator: true,
              showStatusText: true,
              expanded: true,
            ),
            // Graph view (desktop): floating panel on router/extender tap.
            // Client nodes are not tappable in graph view (ui_kit design).
            nodeDetailConfig: NodeDetailConfig(
              trigger: NodeDetailTrigger.tap,
              mode: NodeDetailMode.floatingPanel,
              detailBuilder: (ctx, node, metadata) =>
                  _buildDetailPanel(ctx, node, metadata, router),
            ),
          ),
        ),
      ),
    );
  }

  /// Detail panel content shown on router/extender tap (graph view).
  Widget _buildDetailPanel(BuildContext context, MeshNode node,
      Map<String, dynamic>? metadata, GoRouter router) {
    final ipAddress = metadata?['ip'] as String? ?? '';
    final deviceId = metadata?['deviceId'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _detailRow('Type', node.isGateway ? 'Gateway' : 'Extender'),
        _detailRow(
          'Status',
          node.status == MeshNodeStatus.online ? 'Online' : 'Offline',
        ),
        if (ipAddress.isNotEmpty) _detailRow('IP', ipAddress),
        if (node.status == MeshNodeStatus.online)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: deviceId.isNotEmpty
                    ? () => router.pushNamed(
                          RouteNamed.uspNodeDetail,
                          queryParameters: {'deviceId': deviceId},
                        )
                    : null,
                child: Text('Details'),
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

    if (node.type == MeshNodeType.gateway ||
        node.type == MeshNodeType.extender) {
      final deviceId = node.metadata?['deviceId'] as String?;
      if (deviceId != null && deviceId.isNotEmpty) {
        router.pushNamed(
          RouteNamed.uspNodeDetail,
          queryParameters: {'deviceId': deviceId},
        );
      }
    } else if (node.type == MeshNodeType.client) {
      final mac = node.metadata?['mac'] as String?;
      if (mac != null && mac.isNotEmpty) {
        router.pushNamed(
          RouteNamed.uspDeviceDetail,
          queryParameters: {'mac': mac},
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: AppText.bodySmall(label, color: Colors.grey),
          ),
          Expanded(
            flex: 3,
            child: AppText.bodySmall(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _withTopologyAnimation(BuildContext context, Widget child) {
    final appTheme = Theme.of(context).extension<AppDesignTheme>();
    if (appTheme == null) return child;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          appTheme.copyWith(
            visualEffects:
                appTheme.visualEffects | AppThemeConfig.effectTopologyAnimation,
          ),
        ],
      ),
      child: child,
    );
  }
}
