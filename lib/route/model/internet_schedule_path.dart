import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/add_daily_time_limit_view.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/add_schedule_pause_view.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/daily_time_limit_list_view.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/internet_schedule_overview_view.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/schedule_pause_list_view.dart';
import '_model.dart';
import 'package:linksys_moab/route/_route.dart';


class InternetSchedulePath extends DashboardPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case InternetScheduleOverviewPath:
        return InternetScheduleOverviewView(
          args: args,
          next: next,
        );
      case AddDailyTimeLimitPath:
        return AddDailyTimeLimitView(
          args: args,
          next: next,
        );
      case AddSchedulePausePath:
        return AddSchedulePauseView(
          args: args,
          next: next,
        );
      case DailyTimeLimitListPath:
        return const DailyTimeLimitListView();
      case SchedulePauseListPath:
        return const SchedulePauseListView();
      default:
        return Center();
    }
  }
}

class InternetScheduleOverviewPath extends InternetSchedulePath {}

class AddDailyTimeLimitPath extends InternetSchedulePath {}

class AddSchedulePausePath extends InternetSchedulePath {}

class DailyTimeLimitListPath extends InternetSchedulePath {}

class SchedulePauseListPath extends InternetSchedulePath {}