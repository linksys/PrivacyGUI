
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/dashboard/view/devices/_devices.dart';
import '_model.dart';
import 'package:linksys_moab/route/_route.dart';


class DevicesPath extends DashboardPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case DeviceListPath:
        return DeviceListView();
      case DeviceDetailPath:
        return DeviceDetailView();
      case EditDeviceNamePath:
        return EditDeviceNameView();
      default:
        return const Center();
    }
  }
}

class DeviceListPath extends DevicesPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class DeviceDetailPath extends DevicesPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class EditDeviceNamePath extends DevicesPath {}