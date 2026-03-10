import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp_page/dashboard/views/components/usp_status_dot.dart';
import 'package:privacy_gui/usp_page/devices/views/components/usp_device_list_tile.dart';
import 'package:privacy_gui/usp_page/shell/usp_top_bar.dart';
import 'package:privacy_gui/usp_page/topology/models/node_ui_model.dart';
import 'package:privacy_gui/usp_page/topology/providers/node_detail_provider.dart';
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
      appBarStyle: UiKitAppBarStyle.none,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backState: UiKitBackState.none,
      padding:
          const EdgeInsets.only(top: AppSpacing.xxl, bottom: AppSpacing.md),
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
                  onTap: () => context.canPop()
                      ? context.pop()
                      : context.goNamed(RouteNamed.uspTopology),
                ),
              ],
            ),
          );
        }

        final node = detail.node!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            AppGap.xl(),
            AppResponsiveLayout(
              mobile: (_) =>
                  _buildSingleColumn(context, node, detail),
              desktop: (_) =>
                  _buildTwoColumn(context, node, detail),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        AppIconButton(
          icon: AppIcon.font(Icons.arrow_back),
          onTap: () => context.canPop()
              ? context.pop()
              : context.goNamed(RouteNamed.uspTopology),
        ),
        AppGap.md(),
        AppText.headlineSmall('Node Detail'),
      ],
    );
  }

  Widget _buildSingleColumn(
      BuildContext context, NodeUIModel node, UspNodeDetailState detail) {
    return Column(
      children: [
        _buildNodeInfoCard(context, node),
        AppGap.xl(),
        _buildConnectedDevicesCard(context, detail),
      ],
    );
  }

  Widget _buildTwoColumn(
      BuildContext context, NodeUIModel node, UspNodeDetailState detail) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildNodeInfoCard(context, node)),
        AppGap.gutter(),
        Expanded(child: _buildConnectedDevicesCard(context, detail)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Node Info Card
  // ---------------------------------------------------------------------------

  Widget _buildNodeInfoCard(BuildContext context, NodeUIModel node) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText.titleLarge(node.displayName),
              ),
              UspStatusDot(isActive: true, size: 12),
              AppGap.sm(),
              AppText.labelLarge(node.roleLabel),
            ],
          ),
          AppGap.lg(),
          Center(
            child: Image(
              image: DeviceImageHelper.getRouterImage(
                routerIconTestByModel(modelNumber: node.model),
              ),
              width: 100,
              height: 100,
            ),
          ),
          AppGap.lg(),
          _infoRow(context, 'Device ID', node.deviceId),
          _infoRow(context, 'Model', node.model),
          if (node.manufacturer.isNotEmpty)
            _infoRow(context, 'Manufacturer', node.manufacturer),
          if (node.serialNumber.isNotEmpty)
            _infoRow(context, 'Serial Number', node.serialNumber),
          if (node.softwareVersion.isNotEmpty)
            _infoRow(context, 'Firmware', node.softwareVersion),
          _infoRow(context, 'Connected Devices',
              '${node.connectedDeviceCount}'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Connected Devices Card
  // ---------------------------------------------------------------------------

  Widget _buildConnectedDevicesCard(
      BuildContext context, UspNodeDetailState detail) {
    final devices = detail.connectedDevices;
    final activeCount = detail.activeDeviceCount;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText.titleMedium('Connected Devices'),
              AppText.labelLarge('$activeCount / ${devices.length}'),
            ],
          ),
          AppGap.xl(),
          if (devices.isEmpty)
            AppText.bodyMedium('No devices connected to this node')
          else
            ...devices.map((device) => UspDeviceListTile(
                  device: device,
                  onTap: () => context.goNamed(
                    RouteNamed.uspDeviceDetail,
                    queryParameters: {'mac': device.mac},
                  ),
                )),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: AppText.labelLarge(label),
          ),
          Expanded(
            child: AppText.bodyMedium(value),
          ),
        ],
      ),
    );
  }
}
