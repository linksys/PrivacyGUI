import 'package:flutter/widgets.dart';
import 'package:moab_poc/route/route.dart';

import '../../page/dashboard/view/view.dart';
import 'base_path.dart';

abstract class DashboardPath extends BasePath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case DashboardMainPath:
        return const DashboardView();
      case NoRouterPath:
        return const NoRouterView();
      case PrepareDashboardPath:
        return const PrepareDashboardView();
      default:
        return const Center();
    }
  }
}

class DashboardMainPath extends DashboardPath {}

class NoRouterPath extends DashboardPath {}

class PrepareDashboardPath extends DashboardPath {}