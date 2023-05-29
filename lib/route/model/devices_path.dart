import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/dashboard/view/devices/_devices.dart';
import '_model.dart';

class DevicesPath extends DashboardPath {
  @override
  Widget buildPage() {
    switch (runtimeType) {
      case DeviceListPath:
        return const DeviceListView();
      case DeviceDetailPath:
        return const DeviceDetailView();
      case EditDeviceNamePath:
        return const EditDeviceNameView();
      case OfflineDeviceListPath:
        return const OfflineDeviceListView();
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

class OfflineDeviceListPath extends DevicesPath {}

class EditDeviceIconPath extends DevicesPath with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}
