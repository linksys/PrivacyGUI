import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/customs/customs.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/space/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_home_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

class DeviceListView extends ArgumentsStatefulView {
  const DeviceListView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<DeviceListView> createState() => _DeviceListViewState();
}

class _DeviceListViewState extends State<DeviceListView> {
  final String keyToday = 'today';
  final String keyWeek = 'week';
  Map<String, String> _intervalList = {};
  String _selectedInterval = 'today';
  DeviceListInfoType _selectedSegment = DeviceListInfoType.main;
  late List<DeviceDetailInfo> _deviceList;

  @override
  initState() {
    super.initState();

    _deviceList = [
      DeviceDetailInfo(
        name: 'iPhone XR',
        place: 'Living Room node',
        frequency: '5 GHz',
        uploadData: '0.4',
        downloadData: '12',
        connection: 'wifi',
        weeklyData: '345',
        belongToProfile: const Profile(
          name: 'Profile name',
          icon: 'assets/images/img_profile_icon_1.png',
        ),
      ),
      DeviceDetailInfo.dummy().copyWith(weeklyUsage: '128'),
      DeviceDetailInfo.dummy().copyWith(weeklyUsage: '35'),
      DeviceDetailInfo.dummy().copyWith(weeklyUsage: '24'),
      DeviceDetailInfo.dummy().copyWith(weeklyUsage: '19'),
      DeviceDetailInfo.dummy().copyWith(weeklyUsage: '5'),
      DeviceDetailInfo.dummy().copyWith(weeklyUsage: '4'),
      DeviceDetailInfo.dummy().copyWith(weeklyUsage: '4'),
      DeviceDetailInfo.dummy().copyWith(weeklyUsage: '4'),
    ];
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
    return BasePageView(
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
        content: _content(),
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

  _content() {
    return Column(
      children: [
        box24(),
        _infoSelector(),
        box48(),
        // Bandwidth chart
        box36(),
        _subTitle(),
        SizedBox(height: _showTodayInfo() ? 16 : 8),
        _deviceListWidget(),
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

  _deviceListWidget() {
    return _showTodayInfo() ? _todayInfoSection() : _weekInfoSection();
  }

  _todayInfoSection() {
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
          height: _deviceList.length * 87,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _deviceList.length,
            itemBuilder: (context, index) => InkWell(
              child: _todayDeviceInfoCell(_deviceList[index]),
              onTap: () {
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
      badgePath: deviceInfo.belongToProfile != null
          ? deviceInfo.belongToProfile!.icon
          : null,
      imageSize: 48,
      badgeSize: 19,
      offset: deviceInfo.belongToProfile != null ? 5 : 0,
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

  _weekInfoSection() {
    return SizedBox(
      height: _deviceList.length * 87,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _deviceList.length,
        itemBuilder: (context, index) => InkWell(
          child: _weeklyDeviceInfoCell(_deviceList[index]),
          onTap: () {
            NavigationCubit.of(context).push(DeviceDetailPath());
          },
        ),
      ),
    );
  }

  _weeklyDeviceInfoCell(DeviceDetailInfo deviceInfo) {
    double biggestData = double.parse(_deviceList.first.weeklyData);
    double selfData = double.parse(deviceInfo.weeklyData);
    Widget _deviceIcon = ImageWithBadge(
      imagePath: deviceInfo.icon,
      badgePath: deviceInfo.belongToProfile != null
          ? deviceInfo.belongToProfile!.icon
          : null,
      imageSize: 48,
      badgeSize: 19,
      offset: deviceInfo.belongToProfile != null ? 5 : 0,
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

enum DeviceListInfoType { main, guest, iot }

class DeviceDetailInfo {
  String name;
  String place;
  String frequency;
  String uploadData;
  String downloadData;
  String connection;
  String weeklyData;
  String icon;
  String connectedTo;
  String ipAddress;
  String macAddress;
  String manufacturer;
  String model;
  String os;
  Profile? belongToProfile;

  DeviceDetailInfo({
    this.name = '',
    this.place = '',
    this.frequency = '',
    this.uploadData = '',
    this.downloadData = '',
    this.connection = '',
    this.weeklyData = '',
    this.icon = 'assets/images/icon_device.png',
    this.connectedTo = '',
    this.ipAddress = '',
    this.macAddress = '',
    this.manufacturer = '',
    this.model = '',
    this.os = '',
    this.belongToProfile,
  });

  factory DeviceDetailInfo.dummy() {
    return DeviceDetailInfo(
      name: 'Device name',
      place: 'Living Room node',
      frequency: '5 GHz',
      uploadData: '0.4',
      downloadData: '12',
      connection: 'wifi',
    );
  }

  DeviceDetailInfo copyWith({
    String? name,
    String? place,
    String? frequency,
    String? uploadUsage,
    String? downloadUsage,
    String? connection,
    String? weeklyUsage,
    String? icon,
    String? connectedTo,
    String? ipAddress,
    String? macAddress,
    String? manufacturer,
    String? model,
    String? os,
    Profile? belongToProfile,
  }) {
    return DeviceDetailInfo(
      name: name ?? this.name,
      place: place ?? this.place,
      frequency: frequency ?? this.frequency,
      uploadData: uploadUsage ?? this.uploadData,
      downloadData: downloadUsage ?? this.downloadData,
      connection: connection ?? this.connection,
      weeklyData: weeklyUsage ?? this.weeklyData,
      icon: icon ?? this.icon,
      connectedTo: connectedTo ?? this.connectedTo,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      os: os ?? this.os,
      belongToProfile: belongToProfile ?? this.belongToProfile,
    );
  }
}
