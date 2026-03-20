import 'package:privacy_gui/components/styled/menus/menu_consts.dart';

class NavigationExtra {
  final NaviType? naviType;
  final String? backDestination;
  final Map<String, dynamic>? data;

  const NavigationExtra({this.naviType, this.backDestination, this.data});
}
