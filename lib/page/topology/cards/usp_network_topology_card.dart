import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/_shared/components/dashboard_card_template.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/_shared/components/card_skeleton.dart';
import 'package:privacy_gui/page/topology/helpers/topology_node_content_builder.dart';
import 'package:privacy_gui/page/topology/helpers/usp_topology_builder.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/topology/views/components/node_detail_popup.dart';
import 'package:privacy_gui/route/constants.dart';
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
    );
    final onlineCount = devicesData?.onlineClientCount ??
        devices.where((d) => d.isActive).length;
    final totalCount = devicesData?.totalClientCount ?? devices.length;
    final useRing = totalCount >= 8;

    return DashboardCardTemplate(
      title: loc(context).networkTopology,
      titleBadge: AppBadge(
          label: loc(context)
              .nOnlineOfTotal(onlineCount.toString(), totalCount.toString())),
      detailRoute: RouteNamed.uspDeviceList,
      scrollable: false,
      content: ClipRect(
        child: _withTopologyAnimation(
          context,
          AppTopology(
            topology: topology,
            viewMode: TopologyViewMode.graph,
            layoutMode: LayoutRecommendation.auto,
            clientVisibility:
                useRing ? ClientVisibility.onHover : ClientVisibility.always,
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
                  NodeDetailPopup.builder(ctx, node, metadata),
            ),
          ),
        ),
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
