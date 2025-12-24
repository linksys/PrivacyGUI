import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

enum MenuDisplay {
  none,
  top,
  bottom,
  ;
}

enum NaviType {
  home,
  menu,
  support,
  ;

  String resloveLabel(BuildContext context) => switch (this) {
        NaviType.home => loc(context).home,
        NaviType.menu => loc(context).menu,
        NaviType.support => loc(context).support,
      };
  IconData resolveIcon() => switch (this) {
        NaviType.home => AppFontIcons.home,
        NaviType.menu => AppFontIcons.menu,
        NaviType.support => AppFontIcons.help,
      };

  String resolvePath() => switch (this) {
        NaviType.home => RouteNamed.dashboardHome,
        NaviType.menu => RouteNamed.dashboardMenu,
        NaviType.support => RouteNamed.dashboardSupport,
      };
}
