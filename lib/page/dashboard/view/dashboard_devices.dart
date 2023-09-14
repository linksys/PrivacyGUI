import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/devices/device_detail_id_provider.dart';
import 'package:linksys_app/provider/devices/device_list_provider.dart';
import 'package:linksys_app/provider/devices/device_list_state.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class DashboardDevices extends ArgumentsConsumerStatefulView {
  const DashboardDevices({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<DashboardDevices> createState() => _DashboardDevicesState();
}

class _DashboardDevicesState extends ConsumerState<DashboardDevices> {
  @override
  Widget build(BuildContext context) {
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    return StyledAppPageView(
      padding: AppEdgeInsets.zero(),
      child: AppBasicLayout(
        header: AppPadding.regular(child: AppText.headlineMedium('Devices')),
        content: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: filteredDeviceList.length + 1,
          itemBuilder: (context, index) {
            return _buildCell(index, filteredDeviceList);
          },
          separatorBuilder: (BuildContext context, int index) {
            return const Divider(
              height: 8,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCell(int index, List<DeviceListItem> deviceList) {
    if (index == deviceList.length) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: AppSimplePanel(
          title: 'Offline (${ref.read(offlineDeviceListProvider).length})',
          onTap: () {
            context.pushNamed(RouteNamed.offlineDevices);
          },
        ),
      );
    } else {
      return _buildDeviceCell(deviceList[index]);
    }
  }

  Widget _buildDeviceCell(DeviceListItem item) {
    return AppPadding(
      padding: const AppEdgeInsets.symmetric(horizontal: AppGapSize.regular),
      child: Opacity(
        opacity: item.isOnline ? 1 : 0.3,
        child: AppDevicePanel.normal(
          title: item.name,
          place: item.upstreamDevice,
          band: item.band,
          deviceImage: AppTheme.of(context).images.devices.getByName(item.icon),
          rssiIcon: item.isOnline
              ? getWifiSignalIconData(
                  context, item.isWired ? null : item.signalStrength)
              : null,
          onTap: !item.isOnline
              ? null
              : () {
                  ref.read(deviceDetailIdProvider.notifier).state =
                      item.deviceId;
                  context.pushNamed(RouteNamed.deviceDetails);
                },
        ),
      ),
    );
  }
}
