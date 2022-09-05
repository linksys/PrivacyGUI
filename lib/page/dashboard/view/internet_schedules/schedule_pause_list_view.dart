import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

import '../../../../design/colors.dart';
import '../../../../route/model/dashboard_path.dart';
import '../../../../route/navigation_cubit.dart';
import '../../../../utils.dart';

class SchedulePauseListView extends StatelessWidget {
  const SchedulePauseListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
      final profile = state.selectedProfile!;
      final data = profile.serviceDetails[PService.internetSchedule]
          as InternetScheduleData?;
      final rules = data?.scheduledPauseRule ?? [];
      return BasePageView.onDashboardSecondary(
        padding: EdgeInsets.zero,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(getAppLocalizations(context).schedule_pauses,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
          actions: [
            TextButton(
                onPressed: () {
                  NavigationCubit.of(context).push(AddSchedulePausePath()
                    ..args = {'profileId': profile.id});
                },
                child: Text(getAppLocalizations(context).add,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MoabColor.textButtonBlue))),
          ],
        ),
        child: rules.isEmpty
            ? Center(
                child: const Text('No data!'),
              )
            : Column(children: [
                for (ScheduledPausedRule item in rules) ...[
                  ScheduledPauseItem(
                      item: item,
                      onStatusChanged: (value) {
                        // item.status = value;
                        context
                            .read<ProfilesCubit>()
                            .updateSchedulePausesEnabled(
                                profile.id, item, value);
                      },
                      onPress: () {
                        NavigationCubit.of(context).push(AddSchedulePausePath()
                          ..args = {
                            'rule': item.copyWith(),
                            'profileId': profile.id
                          });
                      }),
                  const SizedBox(height: 8)
                ]
              ]),
      );
    });
  }
}

typedef ValueChanged<T> = void Function(T value);

class ScheduledPauseItem extends StatefulWidget {
  ScheduledPauseItem(
      {Key? key,
      required this.item,
      required this.onStatusChanged,
      required this.onPress})
      : super(key: key);
  ScheduledPausedRule item;
  ValueChanged onStatusChanged;
  VoidCallback onPress;

  @override
  State<ScheduledPauseItem> createState() => _schedulePauseItemState();
}

class _schedulePauseItemState extends State<ScheduledPauseItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        color: const Color.fromRGBO(217, 217, 217, 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
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
                    widget.onStatusChanged(value);
                  })
            ]),
            const SizedBox(height: 25),
            InkWell(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          widget.item.isAllDay
                              ? 'All day'
                              : Utils.formatTimeInterval(
                                  widget.item.pauseStartTime,
                                  widget.item.pauseEndTime),
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color.fromRGBO(102, 102, 102, 1.0))),
                      Image.asset('assets/images/right_compact_wire.png')
                    ]),
                onTap: () {
                  widget.onPress();
                })
          ],
        ));
  }
}

class SchedulePause {
  SchedulePause(this.days, this.duration, this.status);

  String days;
  String duration;
  bool status;
}
