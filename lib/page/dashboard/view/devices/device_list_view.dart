import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/device/device.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/customs/customs.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

class DeviceListView extends ArgumentsStatefulView {
  const DeviceListView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends State<DeviceListView> {
  static const String keyToday = 'today';
  static const String keyWeek = 'week';
  Map<String, String> _intervalList = {};
  String _selectedInterval = 'today';
  DeviceListInfoType _selectedSegment = DeviceListInfoType.main;

  @override
  initState() {
    super.initState();

    context.read<DeviceCubit>().fetchTodayDevicesList();
  }

  _initIntervalListWithLocalizedString() {
    if (_intervalList.isEmpty) {
      _intervalList = {
        keyToday: getAppLocalizations(context).today,
        keyWeek: getAppLocalizations(context).this_week,
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
      children: [
        box24(),
        _infoSelector(),
        box48(),
        // Bandwidth chart
        box36(),
        _subTitle(),
        SizedBox(height: _showTodayInfo() ? 16 : 8),
        _deviceListWidget(state),
      ],
    );
  }

  _infoSelector() {
    return Row(
      children: [
        for (var interval in _intervalList.keys)
          GestureDetector(
            child: Container(
              height: 32,
              margin: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                  color: interval == _selectedInterval
                      ? const Color.fromRGBO(144, 144, 144, 1.0)
                      : const Color.fromRGBO(203, 203, 203, 1.0),
                  border: interval == _selectedInterval
                      ? Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.6),
                          width: 1)
                      : null),
              child: Text(
                _intervalList[interval] ?? '',
                style: TextStyle(
                  color: interval == _selectedInterval
                      ? Colors.white
                      : Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              setState(() {
                _selectedInterval = interval;
                switch (_selectedInterval) {
                  case keyToday:
                    context.read<DeviceCubit>().fetchTodayDevicesList();
                    break;
                  case keyWeek:
                    context.read<DeviceCubit>().fetchWeekDevicesList();
                    break;
                }
                // TODO: handle device list, such as sorting list
              });
            },
          )
      ],
    );
  }

  _subTitle() {
    return Row(
      children: [
        Text(
          _showTodayInfo()
              ? getAppLocalizations(context).num_online('28')
              : getAppLocalizations(context).top_devices_this_week,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: Image.asset('assets/images/icon_control.png'),
        ),
      ],
    );
  }

  _deviceListWidget(DeviceState state) {
    return _showTodayInfo()
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
                groupValue: _selectedSegment,
                onValueChanged: (DeviceListInfoType? value) {
                  if (value != null) {
                    setState(() {
                      _selectedSegment = value;
                      switch (value) {
                        case DeviceListInfoType.main:
                          context.read<DeviceCubit>().showMainDevices();
                          break;
                        case DeviceListInfoType.guest:
                          context.read<DeviceCubit>().showGuestDevices();
                          break;
                        case DeviceListInfoType.iot:
                          context.read<DeviceCubit>().showIotDevices();
                          break;
                      }
                    });
                  }
                },
                children: {
                  DeviceListInfoType.main: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(getAppLocalizations(context).main),
                  ),
                  DeviceListInfoType.guest: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(getAppLocalizations(context).guest),
                  ),
                  DeviceListInfoType.iot: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(getAppLocalizations(context).iot),
                  ),
                },
              ),
            )
          ],
        ),
        box24(),
        SizedBox(
          height: state.deviceDetailInfoMap.length * 87,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.deviceDetailInfoMap.length,
            itemBuilder: (context, index) => InkWell(
              child: _todayDeviceInfoCell(
                  state.deviceDetailInfoMap.values.elementAt(index)),
              onTap: () {
                context.read<DeviceCubit>().setSelectedDeviceInfo(
                    state.deviceDetailInfoMap.values.elementAt(index));
                NavigationCubit.of(context).push(DeviceDetailPath());
              },
            ),
          ),
        ),
      ],
    );
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
    // TODO: Modify here if connection is not wifi
    Widget _connectionIcon = deviceInfo.connection == 'wifi'
        ? Image.asset('assets/images/wifi_signal_3.png')
        : Image.asset('assets/images/wifi_signal_3.png');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _deviceIcon,
          _connectionIcon,
          box8(),
          Column(
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
                deviceInfo.frequency,
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Row(
                children: [
                  Image.asset('assets/images/icon_down.png'),
                  box4(),
                  Text(
                    deviceInfo.downloadData,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  box12(),
                  Image.asset('assets/images/icon_up.png'),
                  box4(),
                  Text(
                    deviceInfo.uploadData,
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
      height: state.deviceDetailInfoMap.length * 87,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.deviceDetailInfoMap.length,
        itemBuilder: (context, index) => InkWell(
          child: _weeklyDeviceInfoCell(
              state.deviceDetailInfoMap.values.elementAt(index),
              state.deviceDetailInfoMap.values.first),
          onTap: () {
            context.read<DeviceCubit>().setSelectedDeviceInfo(
                state.deviceDetailInfoMap.values.elementAt(index));
            NavigationCubit.of(context).push(DeviceDetailPath());
          },
        ),
      ),
    );
  }

  _weeklyDeviceInfoCell(
      DeviceDetailInfo deviceInfo, DeviceDetailInfo firstDeviceInfo) {
    double biggestData = double.parse(firstDeviceInfo.weeklyData);
    double selfData = double.parse(deviceInfo.weeklyData);
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
              Text(
                deviceInfo.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                deviceInfo.weeklyData + ' MB',
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
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

  bool _showTodayInfo() {
    return _selectedInterval == keyToday;
  }
}
