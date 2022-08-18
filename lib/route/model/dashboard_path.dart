import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_health_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_home_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_security_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_settings_view.dart';
import 'package:linksys_moab/page/wifi_settings/share_wifi_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_main.dart';
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
  @override
  PageConfig get pageConfig =>
      super.pageConfig..themeData = MoabTheme.dashboardLightModeData;

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case DashboardHomePath:
        return const DashboardHomeView();
      case DashboardSettingsPath:
        return const DashboardSettingsView();
      case DashboardSecurityPath:
        return const DashboardSecurityView();
      case DashboardHealthPath:
        return const DashboardHealthView();
      case NoRouterPath:
        return const NoRouterView();
      case PrepareDashboardPath:
        return PrepareDashboardView();
      case WifiPath:
        return WiFiView();
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
      case CreateProfileNamePath:
        return CreateProfileNameView(
          args: args,
          next: next,
        );
      case CreateProfileDevicesSelectedPath:
        return CreateProfileDevicesSelectedView(
          args: args,
          next: next,
        );
      case CreateProfileAvatarPath:
        return CreateProfileAvatarView(
          args: args,
          next: next,
        );
      case ProfileOverviewPath:
        return ProfileOverviewView(
          args: args,
          next: next,
        );
      default:
        return const Center();
    }
  }
}

class DashboardHomePath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class DashboardSettingsPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class DashboardSecurityPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class DashboardHealthPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class NoRouterPath extends DashboardPath {}

class PrepareDashboardPath extends DashboardPath {}

class ShareWifiPath extends DashboardPath {}

class InternetSchedulePath extends DashboardPath{}

class ProfileSettingsPath extends DashboardPath{}

class AddDailyTimeLimitPath extends DashboardPath{}

class AddSchedulePausePath extends DashboardPath{}

class DailyTimeLimitListPath extends DashboardPath{}

class SchedulePauseListPath extends DashboardPath{}

class WifiPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class CreateProfileNamePath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class CreateProfileDevicesSelectedPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class CreateProfileAvatarPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class ProfileOverviewPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}