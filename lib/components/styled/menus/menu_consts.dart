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

/// Narrowest screen width at which the top nav chips still carry text labels.
///
/// Below this the chips go icon-only (#1328). The labels are the entire cause of
/// the bug: the top bar's root row overflowed from 601px — the width where
/// `MenuHolder` first shows the top nav — up to the width the labels need, which
/// is locale-dependent (`en` cleared at 640px, `pl` needed 768px, a 167px-wide
/// failure band that an `en`-only measurement would have reported as a 39px edge
/// case). Dropping the labels removes the band and removes the locale
/// sensitivity with it, while all three destinations stay visible with distinct
/// icons.
///
/// Neither existing `AppLayoutConfig` breakpoint fits: below
/// `breakpointMobile` (600) the nav is already at the bottom of the screen, and
/// `breakpointTablet` (905) would strip labels across 768–905 where they
/// measurably fit. (ui_kit's `isTabletWidth` is 601–1240, wider still.) So this
/// is a measured constant rather than a reused breakpoint.
///
/// It tunes the presentation only — it is not what makes the row safe. The
/// bounded, scrollable nav in `TopNavigationMenu` is: an unmeasured locale that
/// wants more than this degrades to a scroll instead of overflowing.
const double kTopNavLabelMinWidth = 768.0;

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

  String resolveUspPath() => switch (this) {
        NaviType.home => RouteNamed.uspDashboard,
        NaviType.menu => RouteNamed.uspMenu,
        NaviType.support => RouteNamed.uspSupport,
      };
}
