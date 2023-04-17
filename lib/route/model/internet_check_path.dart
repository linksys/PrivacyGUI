import 'package:flutter/material.dart';
import 'package:linksys_moab/page/internet_check/view/_view.dart';
import '_model.dart';

abstract class InternetCheckPath extends BasePath {
  @override
  PageConfig get pageConfig =>
      super.pageConfig..ignoreConnectivityChanged = true;

  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  Widget buildPage() {
    switch (runtimeType) {
      // case CheckNodeInternetPath:
      //   return CheckNodeInternetView(
      //     next: next,
      //     args: args,
      //   );
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
      // case InternetConnectedPath:
      //   return InternetConnectedView();
      case NoInternetOptionsAfterPlugModemPath:
        return NoInternetOptionsView(
          next: next,
          args: args,
        );
      default:
        return const Center();
    }
  }
}

class CheckNodeInternetPath extends InternetCheckPath {
  @override
  PageConfig get pageConfig => super.pageConfig
    ..navType = PageNavigationType.none
    ..isBackAvailable = false;
}

class SelectIspSettingsPath extends InternetCheckPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = false;
}

class CheckWiringPath extends InternetCheckPath {}

class NoInternetOptionsPath extends InternetCheckPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = false;
}

class NoInternetOptionsAfterPlugModemPath extends InternetCheckPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = false;
}

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

class InternetConnectedPath extends InternetCheckPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;

  @override
  PageConfig get pageConfig =>
      super.pageConfig..navType = PageNavigationType.none;
}
