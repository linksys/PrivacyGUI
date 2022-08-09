import 'package:flutter/widgets.dart';
import 'package:linksys_moab/design/themes.dart';
import 'package:linksys_moab/page/wifi_settings/share_wifi_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

import '../../page/dashboard/view/view.dart';
import 'base_path.dart';

abstract class DashboardPath extends BasePath {

  @override
  PageConfig get pageConfig => super.pageConfig..themeData = MoabTheme.dashboardLightModeData;

  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case DashboardMainPath:
        return DashboardView();
      case NoRouterPath:
        return const NoRouterView();
      case PrepareDashboardPath:
        return PrepareDashboardView();
      case ShareWifiPath:
        return const ShareWifiView();
      default:
        return const Center();
    }
  }
}

class DashboardMainPath extends DashboardPath {}

class NoRouterPath extends DashboardPath {}

class PrepareDashboardPath extends DashboardPath {}

class ShareWifiPath extends DashboardPath {}