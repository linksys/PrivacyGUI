import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_content_builder.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
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
  final List<NodeUIModel>? nodeModels;

  const UspNetworkTopologyCard({
    super.key,
    this.info,
    this.devices,
    this.nodeModels,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesData = ref.watch(devicesDataProvider).valueOrNull;
    final info =
        this.info ?? ref.watch(systemInfoDataProvider).valueOrNull?.model;
    if (info == null) return const CardSkeleton.topology();
    final devices = this.devices ?? devicesData?.deviceModels ?? [];
    final nodeModels = this.nodeModels ?? devicesData?.nodeModels ?? [];
    final topology = UspTopologyBuilder.build(
      info: info,
      devices: devices,
      nodeModels: nodeModels,
      coverageColor: Theme.of(context).colorScheme.primary,
      // Shrink coverage rings for dashboard card context — ui_kit's
      // calculateBounds() ignores ring radii, so full-size rings
      // overflow the fitScale viewport. Revisit if calculateBounds is
      // updated to include ring extents.
      coverageRingScale: 0.85,
    );
    final onlineCount = devicesData?.onlineClientCount ??
        devices.where((d) => d.isActive).length;
    final totalCount = devicesData?.totalClientCount ?? devices.length;
    final useRing = totalCount >= 8;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Network Topology'),
              AppText.labelLarge(
                '$onlineCount / $totalCount online',
              ),
            ],
          ),
          AppGap.xl(),
          Expanded(
            child: ClipRect(
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
                  nodeContentBuilder: TopologyNodeContentBuilder.build,
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
                    detailBuilder: (ctx, node, metadata) =>
                        _buildNodeDetailPopup(ctx, node, metadata),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeDetailPopup(
      BuildContext context, MeshNode node, Map<String, dynamic>? metadata) {
    final deviceId = metadata?['deviceId'] as String? ?? '';
    final model = metadata?['model'] as String? ?? '';
    final manufacturer = metadata?['manufacturer'] as String? ?? '';
    final serialNumber = metadata?['serialNumber'] as String? ?? '';
    final softwareVersion = metadata?['softwareVersion'] as String? ?? '';
    final isMaster = metadata?['isMaster'] as bool? ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _popupRow('Role', isMaster ? 'Master' : 'Slave'),
        if (deviceId.isNotEmpty && deviceId.toUpperCase() != 'GATEWAY')
          _popupRow('MAC', deviceId),
        if (model.isNotEmpty) _popupRow('Model', model),
        if (manufacturer.isNotEmpty) _popupRow('Manufacturer', manufacturer),
        if (serialNumber.isNotEmpty) _popupRow('S/N', serialNumber),
        if (softwareVersion.isNotEmpty) _popupRow('Firmware', softwareVersion),
      ],
    );
  }

  Widget _popupRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: AppText.bodySmall(label, color: Colors.grey),
          ),
          Expanded(child: AppText.bodySmall(value)),
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
              nodeSpacing: appTheme.topologySpec.nodeSpacing * 2.0,
              orbitRadius: appTheme.topologySpec.orbitRadius * 2.0,
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}
