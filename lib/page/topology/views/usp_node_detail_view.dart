import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
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
          mobile: (_) => _buildMobileLayout(context, node, detail),
          tablet: (_) => _buildMobileLayout(context, node, detail),
          desktop: (_) => _buildDesktopLayout(context, node, detail),
        );
      },
    );
  }

  // ===========================================================================
  // Layouts
  // ===========================================================================

  Widget _buildMobileLayout(
      BuildContext context, NodeUIModel node, UspNodeDetailState detail) {
    return Column(
      children: [
        _buildNodeInfoCard(context, node),
        AppGap.lg(),
        _buildConnectedDevicesCard(context, detail),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context, NodeUIModel node, UspNodeDetailState detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: context.colWidth(4),
          child: _buildNodeInfoCard(context, node),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with image, name, and role badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Image(
                  image: DeviceImageHelper.getRouterImage(
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
          AppGap.xl(),
          // MAC Address (only if real MAC, not synthetic 'gateway')
          if (node.deviceId.toUpperCase() != 'GATEWAY') ...[
            DetailCopyableTile(
              icon: Icons.memory,
              label: 'MAC Address',
              value: node.deviceId,
            ),
            AppGap.md(),
          ],
          // Model
          DetailInfoTile(
            icon: Icons.router,
            label: 'Model',
            value: node.model,
          ),
          // Manufacturer
          if (node.manufacturer.isNotEmpty) ...[
            AppGap.md(),
            DetailInfoTile(
              icon: Icons.business,
              label: 'Manufacturer',
              value: node.manufacturer,
            ),
          ],
          // Serial Number
          if (node.serialNumber.isNotEmpty) ...[
            AppGap.md(),
            DetailCopyableTile(
              icon: Icons.tag,
              label: 'Serial Number',
              value: node.serialNumber,
            ),
          ],
          // Firmware
          if (node.softwareVersion.isNotEmpty) ...[
            AppGap.md(),
            DetailInfoTile(
              icon: Icons.system_update,
              label: 'Firmware',
              value: node.softwareVersion,
            ),
          ],
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
          AppGap.xl(),
          if (devices.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: AppText.bodyMedium(
                  'No devices connected to this node',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            for (var i = 0; i < devices.length; i++)
              UspDeviceListTile(
                device: devices[i],
                variant: i == devices.length - 1
                    ? DeviceListTileVariant.flatLast
                    : DeviceListTileVariant.flat,
                onTap: () => context.goNamed(
                  RouteNamed.uspDeviceDetail,
                  queryParameters: {'mac': devices[i].mac},
                ),
              ),
        ],
      ),
    );
  }
}
