import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/util/logger.dart';

import '../../../../route/model/dashboard_path.dart';

typedef ValueChanged<T> = void Function(T value);

class InternetScheduleOverviewView extends ArgumentsStatefulView {
  const InternetScheduleOverviewView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<InternetScheduleOverviewView> createState() =>
      _InternetScheduleOverviewViewState();
}

class _InternetScheduleOverviewViewState
    extends State<InternetScheduleOverviewView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
      final profile = state.selectedProfile;
      final data = profile?.serviceDetails?[PService.internetSchedule]
          as InternetScheduleData?;
      return BasePageView.onDashboardSecondary(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(profile?.name ?? '',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            timeLimitSettingsItem(context, (context) {
              NavigationCubit.of(context).push(DailyTimeLimitListPath());
            }, data),
            schedulePauseSettingsItem(context, (context) {
              NavigationCubit.of(context).push(SchedulePauseListPath());
            }, data)
          ],
        ),
      );
    });
  }
}

Widget timeLimitSettingsItem(
    BuildContext context, ValueChanged onTap, InternetScheduleData? data) {
  return InkWell(
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Daily time limit',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  SizedBox(height: 4),
                  Text(
                      data == null
                          ? 'none'
                          : data.dateTimeLimitRule.isEmpty
                              ? 'none'
                              : data.dateTimeLimitRule
                                      .any((element) => element.isEnabled)
                                  ? 'ON'
                                  : 'OFF',
                      style: TextStyle(
                          color: Color.fromRGBO(102, 102, 102, 1.0),
                          fontSize: 13,
                          fontWeight: FontWeight.w500))
                ]),
            Expanded(child: Container()),
            Image.asset('assets/images/right_compact_wire.png')
          ],
        ),
      ),
      onTap: () => onTap(context));
}

Widget schedulePauseSettingsItem(
    BuildContext context, ValueChanged onTap, InternetScheduleData? data) {
  return Container(
      height: 64,
      width: double.infinity,
      child: InkWell(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Scheduled pauses',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text(
                        data == null
                            ? 'none'
                            : data.scheduledPauseRule.isEmpty
                                ? 'none'
                                : data.scheduledPauseRule
                                        .any((element) => element.isEnabled)
                                    ? 'ON'
                                    : 'OFF',
                        style: TextStyle(
                            color: Color.fromRGBO(102, 102, 102, 1.0),
                            fontSize: 13,
                            fontWeight: FontWeight.w500))
                  ]),
              Image.asset('assets/images/right_compact_wire.png')
            ],
          ),
          onTap: () => onTap(context)));
}
