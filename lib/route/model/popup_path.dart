import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/components/customs/_customs.dart';
import 'package:linksys_moab/route/_route.dart';

import 'base_path.dart';

abstract class PopUpPath extends BasePath {
  @override
  Widget buildPage() {
    switch (runtimeType) {
      case NoInternetConnectionPath:
        return const NoInternetConnectionModal();
      case ClearOfflineDevicesPath:
        return const ClearDevicesModal();
      default:
        return const Center();
    }
  }
}

class NoInternetConnectionPath extends PopUpPath {
  @override
  PageConfig get pageConfig => super.pageConfig
    ..isFullScreenDialog = true
    ..isOpaque = false;
}

class ClearOfflineDevicesPath extends PopUpPath {
  @override
  PageConfig get pageConfig => super.pageConfig
    ..isFullScreenDialog = true
    ..isOpaque = false;
}
