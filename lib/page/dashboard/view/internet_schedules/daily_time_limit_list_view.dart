import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/utils.dart';

import '../../../../design/colors.dart';
import '../../../../route/navigation_cubit.dart';

class DailyTimeLimitListView extends StatelessWidget {
  const DailyTimeLimitListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return timeListItem(context);
  }

  Widget timeListItem(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
      final profile = state.selectedProfile!;
      final data = profile.serviceDetails[PService.internetSchedule]
          as InternetScheduleData?;
      return BasePageView.onDashboardSecondary(
          padding: EdgeInsets.zero,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(getAppLocalizations(context).daily_time_limit,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            leading: BackButton(onPressed: () {
              NavigationCubit.of(context).pop();
            }),
            actions: [
              TextButton(
                  onPressed: () {
                    NavigationCubit.of(context).push(AddDailyTimeLimitPath()..args = {'profileId': profile.id});
                  },
                  child: Text(getAppLocalizations(context).add,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MoabColor.textButtonBlue))),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 19),
              ..._buildTimeLimitItems(context, data),
            ],
          ));
    });
  }

  List<Widget> _buildTimeLimitItems(
      BuildContext context, InternetScheduleData? data) {
    final rules = data?.dateTimeLimitRule ?? [];
    if (rules.isEmpty) {
      return [
        Center(
          child: const Text('No data!'),
        )
      ];
    } else {
      List<Widget> items = [
        for (DateTimeLimitRule item in rules) ...{
          DailyTimeLimitItem(
              item: item,
              onStatusChanged: (value) {
                // item.isEnabled = value;
                context.read<ProfilesCubit>().updateDailyTimeLimitEnabled(
                    data?.profileId ?? '',
                    item, value);
              },
              onPress: () {
                NavigationCubit.of(context).push(AddDailyTimeLimitPath()..args = {'rule': item.copyWith(), 'profileId': data?.profileId});
              }),
          const SizedBox(height: 8)
        }
      ];
      return items;
    }
  }
}

class DailyTimeLimitItem extends StatefulWidget {
  DailyTimeLimitItem({
    Key? key,
    required this.item,
    required this.onStatusChanged,
    required this.onPress,
  }) : super(key: key);
  DateTimeLimitRule item;
  ValueChanged onStatusChanged;
  VoidCallback onPress;

  @override
  State<DailyTimeLimitItem> createState() => _dailyTimeLimitItemState();
}

class _dailyTimeLimitItemState extends State<DailyTimeLimitItem> {
  bool isOn = false;

  @override
  void initState() {
    super.initState();
    isOn = widget.item.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        color: const Color.fromRGBO(217, 217, 217, 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(
                  Utils.toWeeklyStringList(context, widget.item.weeklySet)
                      .join(' ,'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black)),
              Switch.adaptive(
                  value: widget.item.isEnabled,
                  onChanged: (value) {
                    setState(() {
                      isOn = value;
                    });
                    widget.onStatusChanged(value);
                  })
            ]),
            const SizedBox(height: 25),
            InkWell(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Utils.formatTimeHM(widget.item.timeInSeconds),
                          style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w500,
                              color: Color.fromRGBO(0, 0, 0, 0.5))),
                      Image.asset('assets/images/right_compact_wire.png')
                    ]),
                onTap: () {
                  widget.onPress();
                })
          ],
        ));
  }
}

class TimeLimit {
  TimeLimit(this.days, this.duration, this.status);

  String days;
  String duration;
  bool status;
}
