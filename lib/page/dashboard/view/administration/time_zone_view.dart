import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';

class TimeZoneView extends ArgumentsStatefulView {
  const TimeZoneView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<TimeZoneView> createState() => _TimeZoneViewState();
}

class _TimeZoneViewState extends State<TimeZoneView> {
  bool daylightSavingTimes = false;
  List<TimeZone> _timezoneList = [];
  TimeZone selectedTimezone = const TimeZone(name: '', gmtTimezone: '');

  @override
  void initState() {
    super.initState();

    // TODO: Get from cubit
    daylightSavingTimes = false;
  }

  @override
  Widget build(BuildContext context) {
    _initTimezoneList();
    return BasePageView(
      scrollable: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // iconTheme:
        // IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
        title: Text(
          getAppLocalizations(context).timezone,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          SimpleTextButton(
            text: getAppLocalizations(context).save,
            onPressed: () {},
          ),
        ],
      ),
      child: BasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box24(),
            SettingTile(
              title: Text(
                getAppLocalizations(context).automatic_firmware_update,
                style: const TextStyle(fontSize: 15),
              ),
              value: CupertinoSwitch(
                value: daylightSavingTimes,
                onChanged: (value) {
                  // TODO: Update status
                  setState(() {
                    daylightSavingTimes = value;
                  });
                },
              ),
            ),
            box36(),
            SizedBox(
              height: (38.0 + 26.0) * _timezoneList.length,
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timezoneList.length,
                itemBuilder: (context, index) => InkWell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _timezoneList[index].name,
                              style: const TextStyle(fontSize: 15),
                            ),
                            box4(),
                            Text(
                              _timezoneList[index].gmtTimezone,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromRGBO(102, 102, 102, 1.0),
                              ),
                            ),
                          ],
                        ),
                        if (_timezoneList[index] == selectedTimezone)
                          const Spacer(),
                        if (_timezoneList[index] == selectedTimezone)
                          Image.asset('assets/images/icon_check_black.png'),
                      ],
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      selectedTimezone = _timezoneList[index];
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _initTimezoneList() {
    if (_timezoneList.isEmpty) {
      _timezoneList = [
        TimeZone(
          name: getAppLocalizations(context).kwajalein,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '12'),
        ),
        TimeZone(
          name: getAppLocalizations(context).midway_island_samoa,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '11'),
        ),
        TimeZone(
          name: getAppLocalizations(context).hawaii,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '10'),
        ),
        TimeZone(
          name: getAppLocalizations(context).alaska,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '9'),
        ),
        TimeZone(
          name: getAppLocalizations(context).pacific_time_usa_canada,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '8'),
        ),
        TimeZone(
          name: getAppLocalizations(context).arizona,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '7'),
        ),
        TimeZone(
          name: getAppLocalizations(context).mountain_time_usa_canada,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '7'),
        ),
        TimeZone(
          name: getAppLocalizations(context).central_time_usa_canada,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '6'),
        ),
        TimeZone(
          name: getAppLocalizations(context).mexico,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '6'),
        ),
        TimeZone(
          name: getAppLocalizations(context).indiana_east_colombia_panama,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '5'),
        ),
        TimeZone(
          name: getAppLocalizations(context).eastern_time_usa_canada,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '5'),
        ),
        TimeZone(
          name: getAppLocalizations(context).bolivia_venezuela,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '4'),
        ),
        TimeZone(
          name: getAppLocalizations(context).chile_time_chile_antarctica,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '4'),
        ),
        TimeZone(
          name: getAppLocalizations(context)
              .atlantic_time_canada_greenland_atlantic_islands,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '4'),
        ),
        TimeZone(
          name: getAppLocalizations(context).newfoundland,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '3', min: '30'),
        ),
        TimeZone(
          name: getAppLocalizations(context).brazil_east_greenland,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '3'),
        ),
        TimeZone(
          name: getAppLocalizations(context).guyana,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '3'),
        ),
        TimeZone(
          name: getAppLocalizations(context).mid_atlantic,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '2'),
        ),
        TimeZone(
          name: getAppLocalizations(context).azores,
          gmtTimezone: TimeZone.timezoneString(mark: '-', hour: '1'),
        ),
        TimeZone(
          name: getAppLocalizations(context).gambia_liberia_morocco,
          gmtTimezone: TimeZone.timezoneString(mark: '', hour: ''),
        ),
        TimeZone(
          name: getAppLocalizations(context).england,
          gmtTimezone: TimeZone.timezoneString(mark: '', hour: ''),
        ),
        TimeZone(
          name: getAppLocalizations(context).tunisia,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '1'),
        ),
        TimeZone(
          name: getAppLocalizations(context).france_germany_italy,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '1'),
        ),
        TimeZone(
          name: getAppLocalizations(context).south_africa,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '2'),
        ),
        TimeZone(
          name: getAppLocalizations(context).greece_ukraine_romania,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '2'),
        ),
        TimeZone(
          name: getAppLocalizations(context).turkey_iraq_jordan_kuwait,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '3'),
        ),
        TimeZone(
          name: getAppLocalizations(context).armenia,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '4'),
        ),
        TimeZone(
          name: getAppLocalizations(context).pakistan_russia,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '5'),
        ),
        TimeZone(
          name: getAppLocalizations(context).mumbai_kolkata_chennai_new_delhi,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '5', min: '30'),
        ),
        TimeZone(
          name: getAppLocalizations(context).bangladesh_russia,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '6'),
        ),
        TimeZone(
          name: getAppLocalizations(context).thailand_russia,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '7'),
        ),
        TimeZone(
          name: getAppLocalizations(context).china_hong_kong_australia_western,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '8'),
        ),
        TimeZone(
          name: getAppLocalizations(context).singapore_taiwan_russia,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '8'),
        ),
        TimeZone(
          name: getAppLocalizations(context).japan_korea,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '9'),
        ),
        TimeZone(
          name: getAppLocalizations(context).australia,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '10'),
        ),
        TimeZone(
          name: getAppLocalizations(context).guam_russia,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '10'),
        ),
        TimeZone(
          name: getAppLocalizations(context).solomon_islands,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '11'),
        ),
        TimeZone(
          name: getAppLocalizations(context).fiji,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '12'),
        ),
        TimeZone(
          name: getAppLocalizations(context).new_zealand,
          gmtTimezone: TimeZone.timezoneString(mark: '+', hour: '12'),
        ),
      ];
    }
  }
}

class TimeZone extends Equatable {
  final String name;
  final String gmtTimezone;

  const TimeZone({
    required this.name,
    required this.gmtTimezone,
  });

  TimeZone copyWith({
    String? name,
    String? gmtTimezone,
  }) {
    return TimeZone(
      name: name ?? this.name,
      gmtTimezone: gmtTimezone ?? this.gmtTimezone,
    );
  }

  @override
  List<Object?> get props => [
        name,
        gmtTimezone,
      ];

  static String timezoneString({
    required String mark,
    required String hour,
    String min = '00',
  }) {
    return 'GMT $mark$hour:$min';
  }
}
