import 'package:flutter/widgets.dart';
import 'package:moab_poc/page/dashboard/view/dashboard_view.dart';
import 'package:moab_poc/route/route.dart';

import 'base_path.dart';

abstract class DashboardPath extends BasePath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case DashboardMainPath:
        return const DashboardView();
      default:
        return const Center();
    }
  }
}

class DashboardMainPath extends DashboardPath {}
