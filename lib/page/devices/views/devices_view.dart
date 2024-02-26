import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/devices/views/devices_filter_widget.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/device_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';

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
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    // final filteredChips =
    //     ref.watch(filteredDeviceListProvider.select((value) => value.$3));
    final count = filteredDeviceList.$2.length;
    return StyledAppPageView(
      padding: const EdgeInsets.only(),
      title: 'Devices',
      menuWidget: const DevicesFilterWidget(),
      child: AppBasicLayout(
        header: Padding(
            padding: const EdgeInsets.only(
                left: Spacing.semiSmall, bottom: Spacing.regular),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge('$count Devices'),
                // const AppGap.regular(),
                // Wrap(
                //   spacing: 16,
                //   children: filteredChips
                //       .map((e) => FilterChip(
                //             label: AppText.bodySmall(e ?? ''),
                //             selected: true,
                //             onSelected: (bool value) {},
                //           ))
                //       .toList(),
                // ),
              ],
            )),
        content: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: count,
          itemBuilder: (context, index) {
            return _buildCell(index, filteredDeviceList.$2);
          },
        ),
      ),
    );
  }

  Widget _buildCell(int index, List<DeviceListItem> deviceList) {
    if (index == deviceList.length) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 24),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.zero),
      child: Opacity(
        opacity: item.isOnline ? 1 : 0.3,
        child: AppDeviceListCard(
          title: '${item.name} [${item.signalStrength}]',
          description:
              ResponsiveLayout.isMobile(context) ? null : item.upstreamDevice,
          band: ResponsiveLayout.isMobile(context) ? null : item.band,
          leading: Icons.device_unknown,
          trailing: item.isOnline
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
