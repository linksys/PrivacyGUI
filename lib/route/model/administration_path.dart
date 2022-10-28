import 'package:flutter/material.dart';
import 'package:linksys_moab/page/dashboard/view/administration/_administration.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';

class AdministrationPath extends DashboardPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case AdministrationViewPath:
        return const AdministrationView();
      case RouterPasswordViewPath:
        return const RouterPasswordView();
      case FirmwareUpdateViewPath:
        return const FirmwareUpdateView();
      case TimeZoneViewPath:
        return const TimezoneView();
      case IpDetailsViewPath:
        return const IpDetailsView();
      case WebUiAccessViewPath:
        return const WebUiAccessView();
      // case CloudPasswordValidationPath:
      //   return CloudPasswordValidationView(
      //     args: args,
      //     next: next,
      //   );
      default:
        return const Center();
    }
  }
}

class AdministrationViewPath extends AdministrationPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class RouterPasswordViewPath extends AdministrationPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class FirmwareUpdateViewPath extends AdministrationPath {}

class TimeZoneViewPath extends AdministrationPath {}

class IpDetailsViewPath extends AdministrationPath {}

class WebUiAccessViewPath extends AdministrationPath {}