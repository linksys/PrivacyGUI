import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Navigation tabs for the USP dashboard shell.
///
/// Parallel to JNAP's [NaviType] but resolves to USP route names instead.
enum UspNavTab {
  home,
  menu,
  support;

  String get routeName => switch (this) {
        UspNavTab.home => RouteNamed.uspDashboard,
        UspNavTab.menu => RouteNamed.uspMenu,
        UspNavTab.support => RouteNamed.uspSupport,
      };

  String get routePath => switch (this) {
        UspNavTab.home => RoutePath.uspDashboard,
        UspNavTab.menu => RoutePath.uspMenu,
        UspNavTab.support => RoutePath.uspSupport,
      };

  String label(BuildContext context) => switch (this) {
        UspNavTab.home => loc(context).home,
        UspNavTab.menu => loc(context).menu,
        UspNavTab.support => loc(context).support,
      };

  IconData get icon => switch (this) {
        UspNavTab.home => AppFontIcons.home,
        UspNavTab.menu => AppFontIcons.menu,
        UspNavTab.support => AppFontIcons.help,
      };

  /// Derive the active tab from the current route URI.
  static UspNavTab fromUri(String uri) {
    if (uri.startsWith(RoutePath.uspMenu)) return UspNavTab.menu;
    if (uri.startsWith(RoutePath.uspSupport)) return UspNavTab.support;
    return UspNavTab.home;
  }
}
