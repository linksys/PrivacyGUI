import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
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
      identifier: 'node-detail',
      scrollable: true,
      title: loc(context).nodeDetail,
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
                AppText.titleMedium(loc(context).nodeNotFound),
                AppGap.lg(),
                AppButton.text(
                  label: loc(context).backToTopology,
                  identifier: 'node-detail-back',
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
      NodeEntity node, UspNodeDetailState detail) {
    return Column(
      children: [
        _buildNodeInfoCard(context, node),
        AppGap.lg(),
        _buildNetworkCard(context, ref, node),
        if (node is SlaveNode) ...[
          AppGap.lg(),
          _buildBackhaulCard(context, node, detail.parentNode),
        ],
        AppGap.lg(),
        _buildConnectedDevicesCard(context, detail),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref,
      NodeEntity node, UspNodeDetailState detail) {
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
              if (node is SlaveNode) ...[
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

  Widget _buildNodeInfoCard(BuildContext context, NodeEntity node) {
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
                        activeLabel: node.isMaster
                            ? loc(context).master
                            : loc(context).slave,
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
                  label: loc(context).macAddress,
                  value: node.deviceId,
                ),
              if (node.model.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.router,
                  label: loc(context).model,
                  value: node.model,
                ),
              if (node.manufacturer.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.business,
                  label: loc(context).manufacturer,
                  value: node.manufacturer,
                ),
              if (node.serialNumber.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.tag,
                  label: loc(context).serialNumberLabel,
                  value: node.serialNumber,
                ),
              if (node.softwareVersion.isNotEmpty)
                DetailInfoTile(
                  icon: Icons.system_update,
                  label: loc(context).firmware,
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
      BuildContext context, WidgetRef ref, NodeEntity node) {
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
            title: loc(context).network,
          ),
          AppGap.md(),
          DetailInfoBlock(
            children: [
              // LAN IPv4
              if (node.ipAddress != null && node.ipAddress!.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.language,
                  label: loc(context).lanIp,
                  value: node.ipAddress!,
                ),
              // LAN IPv6 (from Hosts) — routable addresses first; a link-local
              // address swaps its leading icon for a scope badge (see
              // #1128/#1129).
              for (final ipv6 in preferGlobalIpv6First(node.ipv6Addresses))
                DetailCopyableTile(
                  icon: Icons.language,
                  label: loc(context).lanIpv6,
                  value: ipv6,
                  leading: isLinkLocalIpv6(ipv6)
                      ? const Ipv6ScopeBadge(size: 16)
                      : null,
                ),
              // WAN IPv4 (master only)
              if (wanIp != null && wanIp.isNotEmpty)
                DetailCopyableTile(
                  icon: Icons.public,
                  label: loc(context).wanIp,
                  value: wanIp,
                ),
              // WAN IPv6 (master only) — routable addresses first; a link-local
              // address swaps its leading icon for a scope badge (see
              // #1128/#1129).
              for (final ipv6 in preferGlobalIpv6First(wanIpv6Addresses))
                DetailCopyableTile(
                  icon: Icons.public,
                  label: loc(context).wanIpv6,
                  value: ipv6,
                  leading: isLinkLocalIpv6(ipv6)
                      ? const Ipv6ScopeBadge(size: 16)
                      : null,
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
      BuildContext context, SlaveNode node, NodeEntity? parentNode) {
    final colorScheme = Theme.of(context).colorScheme;
    final backhaul = node.backhaul;
    final isWifiBackhaul = backhaul.isWifi;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: Icons.sync_alt,
            title: loc(context).backhaulConnection,
          ),
          AppGap.md(),
          // Connected To Block
          if (parentNode != null) ...[
            LayoutBlock(
              identifier: 'node-detail-parent',
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
                        AppText.labelSmall(loc(context).connectedTo,
                            color: colorScheme.onSurfaceVariant),
                        AppText.bodyMedium(
                            '${parentNode.isMaster ? loc(context).master : loc(context).slave} (${parentNode.model})'),
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
                            // The caption takes the space the icon leaves
                            // instead of its natural width: this tile is a
                            // half-width Expanded, leaving the row 99dp, while
                            // `fi` needs 102.6dp for `Käyttöliittymä`. The
                            // interface name is on the line below, so
                            // shortening the caption loses no information
                            // (#1302).
                            Expanded(
                              child: AppText.labelSmall(
                                loc(context).labelInterface,
                                color: colorScheme.onSurfaceVariant,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        AppGap.xs(),
                        AppText.bodyMedium(
                            backhaul.linkType ?? backhaul.mediaType),
                      ],
                    ),
                  ),
                ),
                if (backhaul.signalStrength != null) ...[
                  AppGap.sm(),
                  Expanded(
                    child:
                        BackhaulSignalIndicator(rssi: backhaul.signalStrength!),
                  ),
                ],
              ],
            ),
            AppGap.sm(),
          ] else if (backhaul.isEthernet) ...[
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
                      AppText.labelSmall(loc(context).labelInterface,
                          color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  AppGap.xs(),
                  AppText.bodyMedium(backhaul.linkType ?? backhaul.mediaType),
                ],
              ),
            ),
            AppGap.sm(),
          ],
          // Throughput Block
          if (backhaul.uplinkRate != null || backhaul.downlinkRate != null) ...[
            Row(
              children: [
                if (backhaul.uplinkRate != null)
                  Expanded(
                    child: DetailSpeedCard(
                      icon: Icons.upload,
                      label: loc(context).upload,
                      speedKbps: backhaul.uplinkRate!,
                      color: colorScheme.tertiary,
                    ),
                  ),
                if (backhaul.uplinkRate != null &&
                    backhaul.downlinkRate != null)
                  AppGap.sm(),
                if (backhaul.downlinkRate != null)
                  Expanded(
                    child: DetailSpeedCard(
                      icon: Icons.download,
                      label: loc(context).download,
                      speedKbps: backhaul.downlinkRate!,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            AppGap.sm(),
          ],
          // PHY Rate + Last Contact row
          if (backhaul.phyRate > 0 || backhaul.lastContactTime != null)
            Row(
              children: [
                if (backhaul.phyRate > 0)
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
                              backhaul.phyRate * 1000)),
                        ],
                      ),
                    ),
                  ),
                if (backhaul.phyRate > 0 && backhaul.lastContactTime != null)
                  AppGap.sm(),
                if (backhaul.lastContactTime != null)
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
                              // Same half-width tile, same treatment as the
                              // interface caption above — and this one does not
                              // even fit in English: 21 locales overflow the
                              // 99dp row, `en` by 2.4dp at 1241px and `ru` by
                              // 39dp. It went unreported in #1302 because no
                              // fixture set lastContactTime, so the golden
                              // suite never rendered this row; the
                              // `slave_backhaul_timing` state now does.
                              Expanded(
                                child: AppText.labelSmall(
                                  loc(context).lastContact,
                                  color: colorScheme.onSurfaceVariant,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          AppGap.xs(),
                          AppText.bodyMedium(DateFormatUtils.formatRelativeTime(
                              backhaul.lastContactTime)),
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
    final devices = detail.connectedClients;
    final activeCount = detail.activeClientCount;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailCardHeader(
            icon: Icons.devices,
            title: loc(context).connectedDevices,
            trailing: AppText.labelLarge(
              '$activeCount / ${devices.length}',
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          AppGap.md(),
          if (devices.isEmpty)
            DetailEmptyBlock(
              message: loc(context).noDevicesConnectedToNode,
            )
          else
            Column(
              children: [
                for (var i = 0; i < devices.length; i++) ...[
                  LayoutBlock(
                    identifier:
                        'node-device-open-${ruleIdentifierKey(devices[i].mac, null)}',
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: UspDeviceListTile(
                      device: devices[i],
                      variant: DeviceListTileVariant.flatLast,
                      onTap: () => context.pushNamed(
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
