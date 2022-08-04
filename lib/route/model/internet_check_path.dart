import 'package:flutter/material.dart';
import 'package:linksys_moab/page/internet_check/check_wiring_view.dart';
import 'package:linksys_moab/page/internet_check/enter_isp_settings_view.dart';
import 'package:linksys_moab/page/internet_check/enter_static_ip_view.dart';
import 'package:linksys_moab/page/internet_check/internet_connected_view.dart';
import 'package:linksys_moab/page/internet_check/learn_battery_modem_view.dart';
import 'package:linksys_moab/page/internet_check/linksys_support_region_view.dart';
import 'package:linksys_moab/page/internet_check/no_internet_options_view.dart';
import 'package:linksys_moab/page/internet_check/plug_modem_back_view.dart';
import 'package:linksys_moab/page/internet_check/select_isp_settings_view.dart';
import 'package:linksys_moab/page/internet_check/unplug_modem_view.dart';
import 'package:linksys_moab/page/internet_check/wait_modem_disconnect_view.dart';
import 'package:linksys_moab/page/setup/view/view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

abstract class InternetCheckPath extends BasePath {

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case CheckNodeInternetPath:
        return const CheckNodeInternetView();
      case SelectIspSettingsPath:
        return const SelectIspSettingsView();
      case CheckWiringPath:
        return const CheckWiringView();
      case NoInternetOptionsPath:
        return const NoInternetOptionsView();
      case EnterStaticIpPath:
        return const EnterStaticIpView();
      case EnterIspSettingsPath:
        return const EnterIspSettingsView();
      case LinksysSupportRegionPath:
        return LinksysSupportRegionView();
      case UnplugModemPath:
        return const UnplugModemView();
      case WaitModemDisconnectPath:
        return const WaitModemDisconnectView();
      case PlugModemBackPath:
        return const PlugModemBackView();
      case LearnBatteryModemPath:
        return const LearnBatteryModemView();
      case InternetConnectedPath:
        return InternetConnectedView();
      default:
        return const Center();
    }
  }
}

class CheckNodeInternetPath extends InternetCheckPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}
class SelectIspSettingsPath extends InternetCheckPath {}
class CheckWiringPath extends InternetCheckPath {}
class NoInternetOptionsPath extends InternetCheckPath {}
class EnterIspSettingsPath extends InternetCheckPath {}
class EnterStaticIpPath extends InternetCheckPath {}
class LinksysSupportRegionPath extends InternetCheckPath {}
class UnplugModemPath extends InternetCheckPath {}
class WaitModemDisconnectPath extends InternetCheckPath {}
class PlugModemBackPath extends InternetCheckPath {}
class LearnBatteryModemPath extends InternetCheckPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}
class InternetConnectedPath extends InternetCheckPath {}



