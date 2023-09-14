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

class OfflineDevicesView extends ArgumentsConsumerStatefulView {
  const OfflineDevicesView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<OfflineDevicesView> createState() => _OfflineDevicesViewState();
}

class _OfflineDevicesViewState extends ConsumerState<OfflineDevicesView> {
  @override
  Widget build(BuildContext context) {
    final offlineDeviceList = ref.watch(offlineDeviceListProvider);
    return StyledAppPageView(
      padding: const AppEdgeInsets.zero(),
      child: AppBasicLayout(
        header: AppPadding.regular(child: AppText.headlineMedium('Offline')),
        content: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: offlineDeviceList.length,
          itemBuilder: (context, index) {
            return _buildDeviceCell(offlineDeviceList[index]);
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

  Widget _buildDeviceCell(DeviceListItem item) {
    return AppPadding(
      padding: const AppEdgeInsets.symmetric(horizontal: AppGapSize.regular),
      child: AppDevicePanel.normal(
        title: item.name,
        place: '',
        band: '',
        deviceImage: AppTheme.of(context).images.devices.getByName(item.icon),
        rssiIcon: null,
        onTap: !item.isOnline
            ? null
            : () {
                ref.read(deviceDetailIdProvider.notifier).state = item.deviceId;
                context.pushNamed(RouteNamed.deviceDetails);
              },
      ),
    );
  }
}
