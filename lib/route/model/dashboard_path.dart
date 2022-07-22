import 'package:flutter/widgets.dart';
import 'package:moab_poc/route/route.dart';

import '../../page/dashboard/view/view.dart';
import 'base_path.dart';

abstract class DashboardPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
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

class DashboardMainPath extends DashboardPath<DashboardMainPath> {}

class NoRouterPath extends DashboardPath<NoRouterPath> {}

class PrepareDashboardPath extends DashboardPath<PrepareDashboardPath> {}