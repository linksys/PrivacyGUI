import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/dashboard/view/_view.dart';
import '_model.dart';


class HealthCheckPath extends DashboardPath {
  @override
  Widget buildPage() {
    switch (runtimeType) {
      case SpeedCheckPath:
        return const SpeedTestView();
      default:
        return const Center();
    }
  }
}

class SpeedCheckPath extends HealthCheckPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}
