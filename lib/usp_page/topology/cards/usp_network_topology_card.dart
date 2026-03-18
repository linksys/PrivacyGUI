import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/usp_page/_shared/providers/mesh_node_enricher.dart';
import 'package:privacy_gui/usp_page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/usp_page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/usp_page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/usp_page/topology/helpers/usp_topology_builder.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Displays a network topology visualization of the router and connected devices.
///
/// Uses [AppTopology] to render a gateway node (the router) with client nodes
/// (connected devices) linked via WiFi or Ethernet connections.
/// When mesh topology data is available, extender nodes are shown between
/// gateway and their connected clients.
class UspNetworkTopologyCard extends ConsumerWidget {
  final SystemInfoUIModel? info;
  final List<DeviceUIModel>? devices;
  final List<MeshNodeInfo>? meshNodes;

  const UspNetworkTopologyCard({
    super.key,
    this.info,
    this.devices,
    this.meshNodes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final info =
        this.info ?? ref.watch(systemInfoDataProvider).valueOrNull?.model;
    if (info == null) return const CardSkeleton.topology();
    final devices = this.devices ?? devicesData?.deviceModels ?? [];
    final meshNodes = this.meshNodes ?? devicesData?.meshTopology.nodes ?? [];
    final topology = UspTopologyBuilder.build(
      info: info,
      devices: devices,
      meshNodes: meshNodes,
      coverageColor: Theme.of(context).colorScheme.primary,
    );
    final clientCount = devices.length;
    final useRing = clientCount >= 8;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Network Topology'),
              AppText.labelLarge(
                '${devices.where((d) => d.isActive).length} / ${devices.length} online',
              ),
            ],
          ),
          AppGap.xl(),
          SizedBox(
            height: 320,
            child: _withTopologyAnimation(
              context,
              AppTopology(
                topology: topology,
                viewMode: TopologyViewMode.graph,
                layoutMode: LayoutRecommendation.auto,
                clientVisibility: useRing
                    ? ClientVisibility.onHover
                    : ClientVisibility.always,
                nodeRendererRegistry: NodeRendererRegistry.unified,
                enableAnimation: true,
                interactive: false,
                treeConfig: TopologyTreeConfiguration(
                  titleBuilder: (node) => node.name,
                  subtitleBuilder: (node) => node.extra ?? '',
                  preferAnimationNode: true,
                  showStatusIndicator: true,
                  showStatusText: true,
                  expanded: false,
                ),
                nodeDetailConfig: NodeDetailConfig(
                  trigger: NodeDetailTrigger.tap,
                  detailBuilder: (ctx, node, metadata) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.labelLarge(node.name),
                      if (node.extra != null) AppText.bodySmall(node.extra!),
                      AppText.bodySmall(
                        node.status == MeshNodeStatus.online
                            ? 'Online'
                            : 'Offline',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps [child] in a local Theme override that enables topology animation
  /// and increases client–node spacing for the dashboard card.
  Widget _withTopologyAnimation(BuildContext context, Widget child) {
    final appTheme = Theme.of(context).extension<AppDesignTheme>();
    if (appTheme == null) return child;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: <ThemeExtension<dynamic>>[
          appTheme.copyWith(
            visualEffects:
                appTheme.visualEffects | AppThemeConfig.effectTopologyAnimation,
            topologySpec: appTheme.topologySpec.copyWith(
              nodeSpacing: appTheme.topologySpec.nodeSpacing * 1.4,
              orbitRadius: appTheme.topologySpec.orbitRadius * 1.4,
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
