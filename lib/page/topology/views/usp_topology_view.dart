import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
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
      title: 'Network Topology',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspMenu,
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

            return _buildTopologyCard(
                context, topology, data.deviceModels.length);
          },
        );
      },
    );
  }

  Widget _buildTopologyCard(
      BuildContext context, MeshTopology topology, int deviceCount) {
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
                detailBuilder: (ctx, node, metadata) =>
                    _buildDetailPanel(ctx, node, metadata, router),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Detail panel content shown on router/extender tap (graph view).
  Widget _buildDetailPanel(BuildContext context, MeshNode node,
      Map<String, dynamic>? metadata, GoRouter router) {
    final deviceId = metadata?['deviceId'] as String? ?? '';
    final model = metadata?['model'] as String? ?? '';
    final manufacturer = metadata?['manufacturer'] as String? ?? '';
    final serialNumber = metadata?['serialNumber'] as String? ?? '';
    final softwareVersion = metadata?['softwareVersion'] as String? ?? '';
    final isMaster = metadata?['isMaster'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Role badge
        _detailRow('Role', isMaster ? 'Master' : 'Slave'),
        // MAC Address (skip synthetic 'gateway')
        if (deviceId.isNotEmpty && deviceId.toUpperCase() != 'GATEWAY')
          _detailRow('MAC', deviceId),
        // Model
        if (model.isNotEmpty) _detailRow('Model', model),
        // Manufacturer
        if (manufacturer.isNotEmpty) _detailRow('Manufacturer', manufacturer),
        // Serial Number
        if (serialNumber.isNotEmpty) _detailRow('S/N', serialNumber),
        // Firmware
        if (softwareVersion.isNotEmpty) _detailRow('Firmware', softwareVersion),
        // Details button
        if (node.status == MeshNodeStatus.online)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerRight,
              child: AppButton.text(
                label: 'Details',
                onTap: deviceId.isNotEmpty
                    ? () => router.pushNamed(
                          RouteNamed.uspNodeDetail,
                          queryParameters: {'deviceId': deviceId},
                        )
                    : null,
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
