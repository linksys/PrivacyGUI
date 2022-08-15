import 'package:flutter/widgets.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/page/wifi_settings/share_wifi_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

import '../../page/dashboard/view/add_daily_time_limit_view.dart';
import '../../page/dashboard/view/add_schedule_pause_view.dart';
import '../../page/dashboard/view/daily_time_limit_list_view.dart';
import '../../page/dashboard/view/internet_schedule_view.dart';
import '../../page/dashboard/view/profile_settings_view.dart';
import '../../page/dashboard/view/schedule_pause_list_view.dart';
import '../../page/dashboard/view/view.dart';
import 'base_path.dart';

abstract class DashboardPath extends BasePath {

  // @override
  // PageConfig get pageConfig => super.pageConfig..themeData = MoabTheme.dashboardLightModeData;

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case DashboardMainPath:
        return const DashboardView();
      case NoRouterPath:
        return const NoRouterView();
      case PrepareDashboardPath:
        return const PrepareDashboardView();
      case ShareWifiPath:
        return const ShareWifiView();
      case InternetSchedulePath:
        return const InternetScheduleView();
      case ProfileSettingsPath:
        return const ProfileSettingsView();
      case AddDailyTimeLimitPath:
        return const AddDailyTimeLimitView();
      case AddSchedulePausePath:
        return const AddSchedulePauseView();
      case DailyTimeLimitListPath:
        return const DailyTimeLimitListView();
      case SchedulePauseListPath:
        return const SchedulePauseListView();
      default:
        return const Center();
    }
  }
}

class DashboardMainPath extends DashboardPath {}

class NoRouterPath extends DashboardPath {}

class PrepareDashboardPath extends DashboardPath {}

class ShareWifiPath extends DashboardPath {}

class InternetSchedulePath extends DashboardPath{}

class ProfileSettingsPath extends DashboardPath{}

class AddDailyTimeLimitPath extends DashboardPath{}

class AddSchedulePausePath extends DashboardPath{}

class DailyTimeLimitListPath extends DashboardPath{}

class SchedulePauseListPath extends DashboardPath{}