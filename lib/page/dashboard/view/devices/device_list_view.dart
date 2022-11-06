import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/_device.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/chart/BarChartSample2.dart';
import 'package:linksys_moab/page/components/customs/_customs.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/devices_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/utils.dart';

class DeviceListView extends ArgumentsStatefulView {
  const DeviceListView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends State<DeviceListView> {
  Map<DeviceListInfoInterval, String> _intervalList = {};

  @override
  initState() {
    super.initState();

    context.read<DeviceCubit>().fetchDeviceList();
  }

  _initIntervalListWithLocalizedString() {
    if (_intervalList.isEmpty) {
      _intervalList = {
        DeviceListInfoInterval.today: getAppLocalizations(context).today,
        DeviceListInfoInterval.week: getAppLocalizations(context).this_week,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    _initIntervalListWithLocalizedString();
    return BlocBuilder<DeviceCubit, DeviceState>(
      builder: (context, state) => BasePageView(
        scrollable: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
        ),
        child: BasicLayout(
          alignment: CrossAxisAlignment.start,
          header: _header(),
          content: _content(state),
        ),
      ),
    );
  }

  _header() {
    return Row(
      children: [
        box4(),
        Text(
          getAppLocalizations(context).devices,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: Image.asset('assets/images/icon_more.png'),
        ),
        box8(),
      ],
    );
  }

  _content(DeviceState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        box24(),
        _infoSelector(state),
        box(_showTodayInfo(state) ? 48 : 26),
        // TODO: create weekly chart title
        Text(
          getAppLocalizations(context).total_bandwidth_usage,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        box16(),
        const BarChartSample2(),
        box36(),
        _subTitle(state),
        SizedBox(height: _showTodayInfo(state) ? 16 : 27),
        _deviceListWidget(state),
        if (_showTodayInfo(state))
          InkWell(
            onTap: state.offlineDeviceList.isEmpty
                ? null
                : () {
                    print('XXXX');
                  },
            child: Container(
              // color: const Color.fromRGBO(217, 217, 217, 1.0),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${state.offlineDeviceList.length} offline',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  box4(),
                  Image.asset('assets/images/icon_chevron.png'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  _infoSelector(DeviceState state) {
    return Row(
      children: [
        for (var interval in _intervalList.keys)
          GestureDetector(
            child: Container(
              height: 32,
              margin: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                  color: interval == state.selectedInterval
                      ? const Color.fromRGBO(144, 144, 144, 1.0)
                      : const Color.fromRGBO(203, 203, 203, 1.0),
                  border: interval == state.selectedInterval
                      ? Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.6),
                          width: 1)
                      : null),
              child: Text(
                _intervalList[interval] ?? '',
                style: TextStyle(
                  color: interval == state.selectedInterval
                      ? Colors.white
                      : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              context.read<DeviceCubit>().updateSelectedInterval(interval);
            },
          ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: Image.asset('assets/images/icon_refresh.png'),
        ),
      ],
    );
  }

  _subTitle(DeviceState state) {
    final count = state.mainDeviceList.length +
        state.guestDeviceList.length +
        state.iotDeviceList.length;
    return Row(
      children: [
        Text(
          _showTodayInfo(state)
              ? getAppLocalizations(context).num_online('$count')
              : getAppLocalizations(context).top_devices_this_week,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  _deviceListWidget(DeviceState state) {
    return _showTodayInfo(state)
        ? _todayInfoSection(state)
        : _weekInfoSection(state);
  }

  _todayInfoSection(DeviceState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoSlidingSegmentedControl<DeviceListInfoType>(
                backgroundColor: const Color.fromRGBO(211, 211, 211, 1.0),
                thumbColor: const Color.fromRGBO(248, 248, 248, 1.0),
                groupValue: state.selectedSegment,
                onValueChanged: (DeviceListInfoType? value) {
                  if (value != null) {
                    context.read<DeviceCubit>().updateSelectedSegment(value);
                  }
                },
                children: {
                  DeviceListInfoType.main: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(getAppLocalizations(context).main +
                        '(${state.mainDeviceList.length})'),
                  ),
                  DeviceListInfoType.guest: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(getAppLocalizations(context).guest +
                        '(${state.guestDeviceList.length})'),
                  ),
                  DeviceListInfoType.iot: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(getAppLocalizations(context).iot +
                        '(${state.iotDeviceList.length})'),
                  ),
                },
              ),
            )
          ],
        ),
        box24(),
        _todayDeviceList(state),
      ],
    );
  }

  _todayDeviceList(DeviceState state) {
    if (state.displayedDeviceList.isNotEmpty) {
      return SizedBox(
        height: state.displayedDeviceList.length * 87,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.displayedDeviceList.length,
          itemBuilder: (context, index) => InkWell(
            child: _todayDeviceInfoCell(
                state.displayedDeviceList.elementAt(index)),
            onTap: () {
              context.read<DeviceCubit>().updateSelectedDeviceInfo(
                  state.displayedDeviceList.elementAt(index));
              NavigationCubit.of(context).push(DeviceDetailPath());
            },
          ),
        ),
      );
    } else {
      switch (state.selectedSegment) {
        case DeviceListInfoType.main:
          return Text(getAppLocalizations(context).no_device_connection_main);
        case DeviceListInfoType.guest:
          // TODO: Check if guest wifi open or not
          bool isGuestWifiOpen = false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isGuestWifiOpen
                    ? getAppLocalizations(context).no_devices
                    : getAppLocalizations(context).guest_wifi_is_off,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              box(13),
              Text(
                isGuestWifiOpen
                    ? getAppLocalizations(context).no_device_connection_guest
                    : getAppLocalizations(context)
                        .no_device_connection_guest_wifi_off,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          );
        case DeviceListInfoType.iot:
          // TODO: Check if iot wifi open or not
          bool isIotWifiOpen = false;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isIotWifiOpen
                    ? getAppLocalizations(context).no_devices
                    : getAppLocalizations(context).iot_wifi_is_off,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              box(13),
              Text(
                isIotWifiOpen
                    ? getAppLocalizations(context).no_device_connection_iot
                    : getAppLocalizations(context)
                        .no_device_connection_iot_wifi_off,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          );
      }
    }
  }

  _todayDeviceInfoCell(DeviceDetailInfo deviceInfo) {
    Widget _deviceIcon = ImageWithBadge(
      imagePath: deviceInfo.icon,
      badgePath: deviceInfo.profileId != null
          ? context
              .read<ProfilesCubit>()
              .state
              .profiles[deviceInfo.profileId!]
              ?.icon
          : null,
      imageSize: 48,
      badgeSize: 19,
      offset: deviceInfo.profileId != null ? 5 : 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _deviceIcon,
          Image.asset(
            'assets/images/${Utils.getDeviceSignalImageString(deviceInfo)}.png',
            width: 16,
            height: 16,
          ),
          box8(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceInfo.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  deviceInfo.place,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
                box4(),
                Text(
                  deviceInfo.connection,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          box4(),
          Column(
            children: [
              Row(
                children: [
                  Image.asset('assets/images/icon_down.png'),
                  box4(),
                  Text(
                    Utils.formatBytes(deviceInfo.downloadData),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  box12(),
                  Image.asset('assets/images/icon_up.png'),
                  box4(),
                  Text(
                    Utils.formatBytes(deviceInfo.uploadData),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 39),
            ],
          ),
        ],
      ),
    );
  }

  _weekInfoSection(DeviceState state) {
    return SizedBox(
      height: state.displayedDeviceList.length * 87,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.displayedDeviceList.length,
        itemBuilder: (context, index) => InkWell(
          child: _weeklyDeviceInfoCell(
              state.displayedDeviceList.elementAt(index),
              state.displayedDeviceList.first),
          onTap: () {
            context.read<DeviceCubit>().updateSelectedDeviceInfo(
                state.displayedDeviceList.elementAt(index));
            NavigationCubit.of(context).push(DeviceDetailPath());
          },
        ),
      ),
    );
  }

  _weeklyDeviceInfoCell(
      DeviceDetailInfo deviceInfo, DeviceDetailInfo firstDeviceInfo) {
    double biggestData = firstDeviceInfo.weeklyData.toDouble();
    double selfData = deviceInfo.weeklyData.toDouble();
    Widget _deviceIcon = ImageWithBadge(
      imagePath: deviceInfo.icon,
      badgePath: deviceInfo.profileId != null
          ? context
              .read<ProfilesCubit>()
              .state
              .profiles[deviceInfo.profileId!]
              ?.icon
          : null,
      imageSize: 48,
      badgeSize: 19,
      offset: deviceInfo.profileId != null ? 5 : 0,
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Row(
            children: [
              _deviceIcon,
              box16(),
              Expanded(
                child: Text(
                  deviceInfo.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              box4(),
              Text(
                Utils.formatBytes(deviceInfo.weeklyData),
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (biggestData != 0.0)
            Column(
              children: [
                Container(
                  width: 150 * (selfData / biggestData),
                  height: 1,
                  color: const Color.fromRGBO(8, 112, 234, 1.0),
                ),
                box8(),
              ],
            ),
        ],
      ),
    );
  }

  bool _showTodayInfo(DeviceState state) {
    return state.selectedInterval == DeviceListInfoInterval.today;
  }
}
