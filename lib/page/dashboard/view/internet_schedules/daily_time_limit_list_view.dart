import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/utils.dart';

import '../../../../design/colors.dart';

class DailyTimeLimitListView extends ConsumerWidget {
  const DailyTimeLimitListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return timeListItem(context, ref);
  }

  Widget timeListItem(BuildContext context, WidgetRef ref) {
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
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            leading: BackButton(onPressed: () {
              ref.read(navigationsProvider.notifier).pop();
            }),
            actions: [
              TextButton(
                  onPressed: () {
                    //TODO: There's no longer profileId!!
                    ref.read(navigationsProvider.notifier).push(
                        AddDailyTimeLimitPath()
                          ..args = {'profileId': profile.name});
                  },
                  child: Text(getAppLocalizations(context).add,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: MoabColor.textButtonBlue))),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 19),
              ..._buildTimeLimitItems(context, ref, data),
            ],
          ));
    });
  }

  List<Widget> _buildTimeLimitItems(
      BuildContext context, WidgetRef ref, InternetScheduleData? data) {
    final rules = data?.dateTimeLimitRule ?? [];
    if (rules.isEmpty) {
      return [
        const Center(
          child: Text('No data!'),
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
                    data?.profileId ?? '', item, value);
              },
              onPress: () {
                ref.read(navigationsProvider.notifier).push(
                    AddDailyTimeLimitPath()
                      ..args = {
                        'rule': item.copyWith(),
                        'profileId': data?.profileId
                      });
              }),
          const SizedBox(height: 8)
        }
      ];
      return items;
    }
  }
}

class DailyTimeLimitItem extends ConsumerStatefulWidget {
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
  ConsumerState<DailyTimeLimitItem> createState() => _dailyTimeLimitItemState();
}

class _dailyTimeLimitItemState extends ConsumerState<DailyTimeLimitItem> {
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
