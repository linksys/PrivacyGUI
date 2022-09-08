import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/page/dashboard/view/Profile/profile_list_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/content_filtering_age_presets_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/content_filtering_category_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/content_filtering_overview_view.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/filtered_content_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_health_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_home_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_security_view.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_settings_view.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/internet_schedule_overview_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_connected_devices_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_detail_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_name_edit_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_offline_check.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/signal_strength_view.dart';
import 'package:linksys_moab/page/dashboard/view/profile/profile_edit_name_avatar_view.dart';
import 'package:linksys_moab/page/dashboard/view/profile/profile_edit_view.dart';
import 'package:linksys_moab/page/dashboard/view/profile/profile_select_avatar_view.dart';
import 'package:linksys_moab/page/dashboard/view/security/security_cyber_threat_view.dart';
import 'package:linksys_moab/page/dashboard/view/security/security_marketing_view.dart';
import 'package:linksys_moab/page/dashboard/view/security/security_protection_status_view.dart';
import 'package:linksys_moab/page/dashboard/view/security/security_subscribe_view.dart';
import 'package:linksys_moab/page/dashboard/view/security/vulnerability_introduction_view.dart';
import 'package:linksys_moab/page/wifi_settings/edit_wifi_mode_view.dart';
import 'package:linksys_moab/page/wifi_settings/edit_wifi_name_password_view.dart';
import 'package:linksys_moab/page/wifi_settings/edit_wifi_security_view.dart';
import 'package:linksys_moab/page/wifi_settings/share_wifi_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_list_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_review_view.dart';
import 'package:linksys_moab/page/wifi_settings/wifi_settings_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/add_daily_time_limit_view.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/add_schedule_pause_view.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/daily_time_limit_list_view.dart';
import 'package:linksys_moab/page/dashboard/view/internet_schedules/schedule_pause_list_view.dart';
import 'package:linksys_moab/page/dashboard/view/view.dart';
import '../../page/dashboard/view/profile/profile_select_devices_view.dart';
import '../../page/dashboard/view/topology/topology_view.dart';
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
      case WifiSettingsPath:
        return const WifiSettingsView();
      case WifiSettingsReviewPath:
        return WifiSettingsReviewView(
          args: args,
        );
      case EditWifiNamePasswordPath:
        return EditWifiNamePasswordView(
          args: args,
        );
      case EditWifiSecurityPath:
        return EditWifiSecurityView(
          args: args,
        );
      case EditWifiModePath:
        return EditWifiModeView(
          args: args,
        );
      case WifiListPath:
        return const WifiListView();
      case ShareWifiPath:
        return ShareWifiView(
          args: args,
        );
      case CreateProfileNamePath:
        return CreateProfileNameView(
          args: args,
          next: next,
        );
      case CreateProfileDevicesSelectedPath:
        return ProfileSelectDevicesView(
          args: args,
          next: next,
        );
      case CreateProfileAvatarPath:
        return ProfileSelectAvatarView(
          args: args,
          next: next,
        );
      case ProfileOverviewPath:
        return ProfileOverviewView(
          args: args,
          next: next,
        );
      case ProfileEditPath:
        return ProfileEditView(
          args: args,
          next: next,
        );
      case ProfileEditNameAvatarPath:
        return ProfileEditNameAvatarView(
          args: args,
          next: next,
        );
      case TopologyPath:
        return TopologyView(
          args: args,
          next: next,
        );
      case NodeDetailPath:
        return NodeDetailView(
          args: args,
          next: next,
        );
      case NodeNameEditPath:
        return NodeNameEditView(
          args: args,
          next: next,
        );
      case NodeConnectedDevicesPath:
        return NodeConnectedDevicesView(
          args: args,
          next: next,
        );
      case SignalStrengthInfoPath:
        return SignalStrengthView(
          args: args,
          next: next,
        );
      case NodeOfflineCheckPath:
        return NodeOfflineCheckView(
          args: args,
          next: next,
        );
      case ContentFilteringOverviewPath:
        return ContentFilteringOverviewView(
          args: args,
          next: next,
        );
      case CFPresetsPath:
        return ContentFilteringPresetsView(
          args: args,
          next: next,
        );
      case CFFilterCategoryPath:
        return ContentFilteringCategoryView(
          args: args,
          next: next,
        );
      case ProfileListPath:
        return ProfileListView(
          args: args,
          next: next,
        );
      case DeviceListPath:
        return DeviceListView();
      case DeviceDetailPath:
        return DeviceDetailView();
      case EditDeviceNamePath:
        return EditDeviceNameView();
      case CFFilteredContentPath:
        return const FilteredContentView();
      case SecurityProtectionStatusPath:
        return const SecurityProtectionStatusView();
      case SecurityCyberThreatPath:
        return const SecurityCyberThreatView();
      case VulnerabilityIntroductionPath:
        return const VulnerabilityIntroductionView();
      case SecurityMarketingPath:
        return const SecurityMarketingView();
      case SecuritySubscribePath:
        return const SecuritySubscribeView();
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

class TopologyPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class NoRouterPath extends DashboardPath {}

class PrepareDashboardPath extends DashboardPath {}

class WifiSettingsPath extends DashboardPath {}

class WifiSettingsReviewPath extends DashboardPath {}

class EditWifiNamePasswordPath extends DashboardPath {}

class EditWifiSecurityPath extends DashboardPath {}

class InternetSchedulePath extends DashboardPath {}

class InternetScheduleOverviewPath extends DashboardPath {}

class AddDailyTimeLimitPath extends DashboardPath {}

class AddSchedulePausePath extends DashboardPath {}

class DailyTimeLimitListPath extends DashboardPath {}

class SchedulePauseListPath extends DashboardPath {}

class EditWifiModePath extends DashboardPath {}

class WifiListPath extends DashboardPath {}

class ShareWifiPath extends DashboardPath {}

class CreateProfileNamePath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class CreateProfileDevicesSelectedPath extends DashboardPath with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class CreateProfileAvatarPath extends DashboardPath with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class ProfileOverviewPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class ProfileEditPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class ProfileEditNameAvatarPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class ProfileListPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class NodeDetailPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}
class NodeNameEditPath extends DashboardPath{}
class NodeConnectedDevicesPath extends DashboardPath{}
class SignalStrengthInfoPath extends DashboardPath{}
class NodeOfflineCheckPath extends DashboardPath{
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class ContentFilteringPath extends DashboardPath {}

class ContentFilteringOverviewPath extends DashboardPath {}

class CFPresetsPath extends DashboardPath {}
class CFFilterCategoryPath extends DashboardPath with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}
class CFFilteredContentPath extends DashboardPath {}

class DeviceListPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class DeviceDetailPath extends DashboardPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class EditDeviceNamePath extends DashboardPath {}

class SecurityProtectionStatusPath extends DashboardPath {}

class SecurityCyberThreatPath extends DashboardPath {}

class VulnerabilityIntroductionPath extends DashboardPath {}

class SecurityMarketingPath extends DashboardPath {}

class SecuritySubscribePath extends DashboardPath {}
