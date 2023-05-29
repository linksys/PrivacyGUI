import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/bloc/profiles/state.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/internet_schedule_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class InternetScheduleOverviewView extends ArgumentsConsumerStatefulView {
  const InternetScheduleOverviewView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<InternetScheduleOverviewView> createState() =>
      _InternetScheduleOverviewViewState();
}

class _InternetScheduleOverviewViewState
    extends ConsumerState<InternetScheduleOverviewView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfilesCubit, ProfilesState>(builder: (context, state) {
      final profile = state.selectedProfile;
      final data = profile?.serviceDetails[PService.internetSchedule]
          as InternetScheduleData?;
      return StyledAppPageView(
        title: profile?.name ?? '',
        child: Column(
          children: [
            const AppGap.regular(),
            timeLimitSettingsItem(context, (context) {
              ref
                  .read(navigationsProvider.notifier)
                  .push(DailyTimeLimitListPath());
            }, data),
            schedulePauseSettingsItem(context, (context) {
              ref
                  .read(navigationsProvider.notifier)
                  .push(SchedulePauseListPath());
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
                const AppText.descriptionMain(
                  'Daily time limit',
                ),
                const AppGap.small(),
                AppText.descriptionSub(
                  data == null
                      ? 'none'
                      : data.dateTimeLimitRule.isEmpty
                          ? 'none'
                          : data.dateTimeLimitRule
                                  .any((element) => element.isEnabled)
                              ? 'ON'
                              : 'OFF',
                  color: const Color.fromRGBO(102, 102, 102, 1.0),
                ),
              ],
            ),
            const Spacer(),
            Image.asset('assets/images/right_compact_wire.png'),
          ],
        ),
      ),
      onTap: () => onTap(context));
}

Widget schedulePauseSettingsItem(
    BuildContext context, ValueChanged onTap, InternetScheduleData? data) {
  return SizedBox(
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
                const AppText.descriptionMain(
                  'Scheduled pauses',
                ),
                const AppGap.small(),
                AppText.descriptionSub(
                  data == null
                      ? 'none'
                      : data.scheduledPauseRule.isEmpty
                          ? 'none'
                          : data.scheduledPauseRule
                                  .any((element) => element.isEnabled)
                              ? 'ON'
                              : 'OFF',
                  color: const Color.fromRGBO(102, 102, 102, 1.0),
                ),
              ]),
          Image.asset('assets/images/right_compact_wire.png')
        ],
      ),
      onTap: () => onTap(context),
    ),
  );
}
