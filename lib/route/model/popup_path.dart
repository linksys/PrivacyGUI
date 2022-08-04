import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/components/customs/no_network_bottom_modal.dart';
import 'package:linksys_moab/route/route.dart';

import 'base_path.dart';

abstract class PopUpPath extends BasePath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case NoInternetConnectionPath:
        return NoInternetConnectionModal();
      default:
        return Center();
    }
  }
}

class NoInternetConnectionPath extends PopUpPath {
  @override
  PageConfig get pageConfig => super.pageConfig
    ..isFullScreenDialog = true
    ..isOpaque = false;
}
