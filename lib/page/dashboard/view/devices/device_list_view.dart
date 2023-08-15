import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/consts.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../../../../route/model/devices_path.dart';
import '../../../components/styled/styled_tab_page_view.dart';

class DeviceListView extends ArgumentsConsumerStatefulView {
  const DeviceListView({Key? key, super.args, super.next}) : super(key: key);

  @override
  ConsumerState<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends ConsumerState<DeviceListView> {
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
          ? const AppFullScreenSpinner()
          : StyledAppTabPageView(
              title: 'Devices',
              backState: StyledBackState.none,
              tabs: [
                AppTab(
                  title: 'Main',
                  icon: AppText.screenName(
                    '${state.mainDeviceList.length}',
                  ),
                ),
                AppTab(
                  title: 'Guest',
                  icon: AppText.screenName(
                    '${state.guestDeviceList.length}',
                  ),
                ),
                AppTab(
                  title: 'Offline',
                  icon: AppText.screenName(
                    '${state.offlineDeviceList.length}',
                  ),
                ),
              ],
              tabContentViews: [
                _buildDeviceListView(state.displayedDeviceList),
                _buildDeviceListView(state.guestDeviceList),
                _buildDeviceListView(state.offlineDeviceList),
              ],
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
