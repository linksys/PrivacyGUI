import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/components/backhaul_signal_indicator.dart';
import 'package:privacy_gui/util/date_format_utils.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Node detail page — displays mesh node info and connected devices.
class UspNodeDetailView extends ConsumerWidget {
  final String deviceId;

  const UspNodeDetailView({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(uspNodeDetailProvider(deviceId));

    return UiKitPageView.withSliver(
      scrollable: true,
      title: 'Node Detail',
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspTopology,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) {
        if (detail.node == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.titleMedium('Node not found'),
                AppGap.lg(),
                AppButton.text(
                  label: 'Back to Topology',
                  onTap: () =>
                      context.navigateBack(fallback: RouteNamed.uspTopology),
                ),
              ],
            ),
          );
        }

        final node = detail.node!;
        return AppResponsiveLayout(
          mobile: (_) => _buildMobileLayout(context, ref, node, detail),
          tablet: (_) => _buildMobileLayout(context, ref, node, detail),
          desktop: (_) => _buildDesktopLayout(context, ref, node, detail),
        );
      },
    );
  }

  // ===========================================================================
  // Layouts
  // ===========================================================================

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref,
      NodeUIModel node, UspNodeDetailState detail) {
    return Column(
      children: [
        _buildNodeInfoCard(context, node),
        AppGap.lg(),
        _buildNetworkCard(context, ref, node),
        if (!node.isMaster && node.hasBackhaul) ...[
          AppGap.lg(),
          _buildBackhaulCard(context, node, detail.parentNode),
        ],
        AppGap.lg(),
        _buildConnectedDevicesCard(context, detail),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref,
      NodeUIModel node, UspNodeDetailState detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.colWidth(4),
          child: Column(
            children: [
              _buildNodeInfoCard(context, node),
              AppGap.lg(),
              _buildNetworkCard(context, ref, node),
              if (!node.isMaster && node.hasBackhaul) ...[
                AppGap.lg(),
                _buildBackhaulCard(context, node, detail.parentNode),
              ],
            ],
          ),
        ),
        AppGap.gutter(),
        SizedBox(
          width: context.colWidth(8),
          child: _buildConnectedDevicesCard(context, detail),
        ),
      ],
    );
  }

  // ===========================================================================
  // Node Info Card
  // ===========================================================================

  Widget _buildNodeInfoCard(BuildContext context, NodeUIModel node) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — image, name, role badge
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                  child: AppImage.provider(
                    imageProvider: DeviceImageHelper.getRouterImage(
                      routerIconTestByModel(modelNumber: node.model),
                    ),
                    width: 48,
                    height: 48,
                  ),
                ),
                AppGap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.titleLarge(node.displayName),
                      AppGap.xs(),
                      DetailStatusBadge(
                        isActive: true,
                        activeLabel: node.roleLabel,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Hardware Info Block
          DetailInfoBlock(
            children: [
              if (node.deviceId.toUpperCase() != 'GATEWAY')
                DetailCopyableTile(
                  icon: Icons.memory,
                  label: 'MAC Address',
                  value: node.deviceId,
                ),
              if (node.model.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.router,
                  label: 'Model',
                  value: node.model,
                ),
              if (node.manufacturer.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.business,
                  label: 'Manufacturer',
                  value: node.manufacturer,
                ),
              if (node.serialNumber.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.tag,
                  label: 'Serial Number',
                  value: node.serialNumber,
                ),
              if (node.softwareVersion.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.system_update,
                  label: 'Firmware',
                  value: node.softwareVersion,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Network Card
  // ===========================================================================

  Widget _buildNetworkCard(
      BuildContext context, WidgetRef ref, NodeUIModel node) {
    final wanData =
        node.isMaster ? ref.watch(wanDataProvider).valueOrNull?.model : null;
    final wanIp = wanData?.ipAddress;
    final wanIpv6Addresses = wanData?.ipv6Addresses ?? [];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: Icons.lan,
            title: 'Network',
          ),
          AppGap.md(),
          DetailInfoBlock(
            children: [
              // LAN IPv4
              if (node.ipAddress != null && node.ipAddress!.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.language,
                  label: 'LAN IP',
                  value: node.ipAddress!,
                ),
              // LAN IPv6 (from Hosts)
              for (final ipv6 in node.ipv6Addresses)
                DetailCopyableTile(
                  icon: Icons.language,
                  label: 'LAN IPv6',
                  value: ipv6,
                ),
              // WAN IPv4 (master only)
              if (wanIp != null && wanIp.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.public,
                  label: 'WAN IP',
                  value: wanIp,
                ),
              // WAN IPv6 (master only)
              for (final ipv6 in wanIpv6Addresses)
                DetailCopyableTile(
                  icon: Icons.public,
                  label: 'WAN IPv6',
                  value: ipv6,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Backhaul Connection Card (Slave nodes only)
  // ===========================================================================

  Widget _buildBackhaulCard(
      BuildContext context, NodeUIModel node, NodeUIModel? parentNode) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWifiBackhaul = !node.isEthernetBackhaul;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: Icons.sync_alt,
            title: 'Backhaul Connection',
          ),
          AppGap.md(),
          // Connected To Block
          if (parentNode != null) ...[
            LayoutBlock(
              onTap: () => context.pushNamed(
                RouteNamed.uspNodeDetail,
                queryParameters: {'deviceId': parentNode.deviceId},
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.link,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  AppGap.sm(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelSmall('Connected To',
                            color: colorScheme.onSurfaceVariant),
                        AppText.bodyMedium(
                            '${parentNode.roleLabel} (${parentNode.model})'),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 20, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
            AppGap.sm(),
          ],
          // Interface + Signal row (Wi-Fi backhaul)
          if (isWifiBackhaul) ...[
            Row(
              children: [
                Expanded(
                  child: LayoutBlock(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.wifi,
                                size: 16, color: colorScheme.onSurfaceVariant),
                            AppGap.xs(),
                            AppText.labelSmall('Interface',
                                color: colorScheme.onSurfaceVariant),
                          ],
                        ),
                        AppGap.xs(),
                        AppText.bodyMedium(
                            node.backhaulLinkType ?? node.backhaulMediaType),
                      ],
                    ),
                  ),
                ),
                if (node.backhaulSignalStrength != null) ...[
                  AppGap.sm(),
                  Expanded(
                    child: BackhaulSignalIndicator(
                        rssi: node.backhaulSignalStrength!),
                  ),
                ],
              ],
            ),
            AppGap.sm(),
          ] else ...[
            // Ethernet backhaul — just interface block
            LayoutBlock(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_ethernet,
                          size: 16, color: colorScheme.onSurfaceVariant),
                      AppGap.xs(),
                      AppText.labelSmall('Interface',
                          color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  AppGap.xs(),
                  AppText.bodyMedium(
                      node.backhaulLinkType ?? node.backhaulMediaType),
                ],
              ),
            ),
            AppGap.sm(),
          ],
          // Throughput Block
          if (node.backhaulUplinkRate != null ||
              node.backhaulDownlinkRate != null) ...[
            Row(
              children: [
                if (node.backhaulUplinkRate != null)
                  Expanded(
                    child: DetailSpeedCard(
                      icon: Icons.upload,
                      label: 'Upload',
                      speedKbps: node.backhaulUplinkRate!,
                      color: colorScheme.tertiary,
                    ),
                  ),
                if (node.backhaulUplinkRate != null &&
                    node.backhaulDownlinkRate != null)
                  AppGap.sm(),
                if (node.backhaulDownlinkRate != null)
                  Expanded(
                    child: DetailSpeedCard(
                      icon: Icons.download,
                      label: 'Download',
                      speedKbps: node.backhaulDownlinkRate!,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            AppGap.sm(),
          ],
          // PHY Rate + Last Contact row
          if (node.backhaulPhyRate > 0 || node.lastContactTime != null)
            Row(
              children: [
                if (node.backhaulPhyRate > 0)
                  Expanded(
                    child: LayoutBlock(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.speed,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant),
                              AppGap.xs(),
                              AppText.labelSmall('PHY Rate',
                                  color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                          AppGap.xs(),
                          AppText.bodyMedium(NetworkUtils.formatSpeed(
                              node.backhaulPhyRate * 1000)),
                        ],
                      ),
                    ),
                  ),
                if (node.backhaulPhyRate > 0 && node.lastContactTime != null)
                  AppGap.sm(),
                if (node.lastContactTime != null)
                  Expanded(
                    child: LayoutBlock(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant),
                              AppGap.xs(),
                              AppText.labelSmall('Last Contact',
                                  color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                          AppGap.xs(),
                          AppText.bodyMedium(DateFormatUtils.formatRelativeTime(
                              node.lastContactTime)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Connected Devices Card
  // ===========================================================================

  Widget _buildConnectedDevicesCard(
      BuildContext context, UspNodeDetailState detail) {
    final devices = detail.connectedDevices;
    final activeCount = detail.activeDeviceCount;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: Icons.devices,
            title: 'Connected Devices',
            trailing: AppText.labelLarge(
              '$activeCount / ${devices.length}',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppGap.md(),
          if (devices.isEmpty)
            const DetailEmptyBlock(
              message: 'No devices connected to this node',
            )
          else
            Column(
              children: [
                for (var i = 0; i < devices.length; i++) ...[
                  LayoutBlock(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: UspDeviceListTile(
                      device: devices[i],
                      variant: DeviceListTileVariant.flatLast,
                      onTap: () => context.goNamed(
                        RouteNamed.uspDeviceDetail,
                        queryParameters: {'mac': devices[i].mac},
                      ),
                    ),
                  ),
                  if (i < devices.length - 1) AppGap.sm(),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
