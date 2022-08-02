import 'package:flutter/widgets.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/wifi_settings/share_wifi_view.dart';
import 'package:moab_poc/route/model/model.dart';
import 'package:moab_poc/route/route.dart';

import '../../page/dashboard/view/view.dart';
import 'base_path.dart';

abstract class DashboardPath extends BasePath {

  @override
  PageConfig get pageConfig => super.pageConfig..themeData = MoabTheme.dashboardLightModeData;

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
      default:
        return const Center();
    }
  }
}

class DashboardMainPath extends DashboardPath {}

class NoRouterPath extends DashboardPath {}

class PrepareDashboardPath extends DashboardPath {}

class ShareWifiPath extends DashboardPath {}