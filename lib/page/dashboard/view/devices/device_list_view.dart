import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../../../route/_route.dart';
import '../../../../route/model/devices_path.dart';
import '../../../components/styled/styled_tab_page_view.dart';

class DeviceListView extends ArgumentsStatefulView {
  const DeviceListView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends State<DeviceListView> {
  Map<DeviceListInfoScope, String> _intervalList = {};

  @override
  initState() {
    super.initState();

    context.read<DeviceCubit>().fetchDeviceList();
  }

  _initIntervalListWithLocalizedString() {
    if (_intervalList.isEmpty) {
      _intervalList = {
        DeviceListInfoScope.today: getAppLocalizations(context).today,
        DeviceListInfoScope.week: getAppLocalizations(context).this_week,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    _initIntervalListWithLocalizedString();
    return BlocBuilder<DeviceCubit, DeviceState>(
      builder: (context, state) => state.isLoading
          ? const LinksysFullScreenSpinner()
          : StyledLinksysTabPageView(
              title: 'Devices',
              tabs: [
                LinksysTab(
                  title: 'Main',
                  icon: LinksysText.screenName(
                    '${state.mainDeviceList.length}',
                  ),
                ),
                LinksysTab(
                  title: 'Guest',
                  icon: LinksysText.screenName(
                    '${state.guestDeviceList.length}',
                  ),
                ),
              ],
              tabContentViews: [
                _buildDeviceListView(state.displayedDeviceList),
                _buildDeviceListView(state.guestDeviceList),
              ],
            ),
    );
  }

  Widget _buildDeviceListView(List<DeviceDetailInfo> deviceList) {
    return ListView.builder(
      itemCount: deviceList.length,
      itemBuilder: (context, index) {
        final device = deviceList[index];
        return _buildDeviceCell(device);
      },
    );
  }

  Widget _buildDeviceCell(DeviceDetailInfo device) {
    return AppPadding(
        padding:
            const LinksysEdgeInsets.symmetric(horizontal: AppGapSize.regular),
        child: AppDevicePanel.normal(
          title: device.name,
          place: device.place,
          frequency: device.connection,
          deviceImage:
              AppTheme.of(context).images.devices.getByName(device.icon),
          rssi: device.signal,
          onTap: () {
            context.read<DeviceCubit>().updateSelectedDeviceInfo(device);
            NavigationCubit.of(context).push(DeviceDetailPath());
          },
        ));
  }
}
