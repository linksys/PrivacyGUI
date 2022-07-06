import 'package:flutter/widgets.dart';
import 'package:moab_poc/page/components/customs/no_network_bottom_modal.dart';
import 'package:moab_poc/route/route.dart';

import 'base_path.dart';

abstract class PopUpPath<P> extends BasePath<P> {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (P) {
      case NoInternetConnectionPath:
        return NoInternetConnectionModal();
      default:
        return Center();
    }
  }
}
class NoInternetConnectionPath extends PopUpPath<NoInternetConnectionPath> {
  @override
  PageConfig get pageConfig =>
      super.pageConfig..isFullScreenDialog = true..isOpaque = false;
}