import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/consts.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/styled/styled_tab_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../../../route/model/devices_path.dart';

class DashboardDevices extends ArgumentsConsumerStatefulView {
  const DashboardDevices({Key? key, super.args, super.next}) : super(key: key);

  @override
  ConsumerState<DashboardDevices> createState() => _DashboardDevicesState();
}

class _DashboardDevicesState extends ConsumerState<DashboardDevices> {

  @override
  initState() {
    super.initState();
    context.read<DeviceCubit>().fetchDeviceList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceCubit, DeviceState>(
      builder: (context, state) => state.isLoading
          ? const AppFullScreenSpinner()
          : StyledAppPageView(
              title: 'Devices',
              backState: StyledBackState.none,
              child: _buildDeviceListView(state.displayedDeviceList),
            ),
    );
  }

  Widget _buildDeviceListView(List<DeviceDetailInfo> deviceList) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: deviceList.length,
      itemBuilder: (context, index) {
        final device = deviceList[index];
        return _buildDeviceCell(device);
      },
    );
  }

  Widget _wrapDeviceCell(DeviceDetailInfo device) {
    bool isOnline = device.isOnline;
    final child = _buildDeviceCell(device);
    return isOnline
        ? child
        : AppSlideActionContainer(
            rightMenuItems: [
              AppMenuItem(
                icon: getCharactersIcons(context).crossRound,
                label: 'delete',
                background: ConstantColors.tertiaryRed,
              )
            ],
            child: child,
          );
  }

  Widget _buildDeviceCell(DeviceDetailInfo device) {
    return AppPadding(
        padding: const AppEdgeInsets.symmetric(horizontal: AppGapSize.regular),
        child: AppDevicePanel.normal(
          title: device.name,
          place: device.parentInfo?.place ?? '',
          frequency: device.connection,
          deviceImage:
              AppTheme.of(context).images.devices.getByName(device.icon),
          rssi: device.signal,
          onTap: () {
            context.read<DeviceCubit>().updateSelectedDeviceInfo(device);
            ref.read(navigationsProvider.notifier).push(DeviceDetailPath());
          },
        ));
  }
}
