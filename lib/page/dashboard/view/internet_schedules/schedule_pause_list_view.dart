import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import '../../../../design/colors.dart';
import '../../../../utils.dart';

class SchedulePauseListView extends ConsumerWidget {
  const SchedulePauseListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            ref.read(navigationsProvider.notifier).pop();
          }),
          actions: [
            TextButton(
                onPressed: () {
                  //TODO: There's no longer profileId!!
                  ref.read(navigationsProvider.notifier).push(
                      AddSchedulePausePath()
                        ..args = {'profileId': profile.name});
                },
                child: Text(getAppLocalizations(context).add,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MoabColor.textButtonBlue))),
          ],
        ),
        child: rules.isEmpty
            ? const Center(
                child: Text('No data!'),
              )
            : Column(children: [
                for (ScheduledPausedRule item in rules) ...[
                  ScheduledPauseItem(
                      item: item,
                      onStatusChanged: (value) {
                        // item.status = value;
                        //TODO: There's no longer profileId!!
                        context
                            .read<ProfilesCubit>()
                            .updateSchedulePausesEnabled(
                                profile.name, item, value);
                      },
                      onPress: () {
                        //TODO: There's no longer profileId!!
                        ref.read(navigationsProvider.notifier).push(
                            AddSchedulePausePath()
                              ..args = {
                                'rule': item.copyWith(),
                                'profileId': profile.name
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

class ScheduledPauseItem extends ConsumerStatefulWidget {
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
  ConsumerState<ScheduledPauseItem> createState() => _schedulePauseItemState();
}

class _schedulePauseItemState extends ConsumerState<ScheduledPauseItem> {
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
