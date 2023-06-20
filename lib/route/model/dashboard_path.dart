import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/linkup/view/linkup_view.dart';
import '_model.dart';

import 'package:linksys_moab/page/dashboard/view/_view.dart';
import 'base_path.dart';

abstract class DashboardPath extends BasePath {

  @override
  Widget buildPage() {
    switch (runtimeType) {
      case DashboardHomePath:
        return const DashboardHomeView();
      case DashboardSettingsPath:
        return const DashboardSettingsView();
      case PrepareDashboardPath:
        return const PrepareDashboardView();
      case SelectNetworkPath:
        return const SelectNetworkView();
      case LinkupPath:
        return const LinkupView();
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

class PrepareDashboardPath extends DashboardPath {}

class SelectNetworkPath extends DashboardPath {}

class LinkupPath extends DashboardPath {}
