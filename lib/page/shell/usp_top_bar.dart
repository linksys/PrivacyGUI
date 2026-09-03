import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/demo/providers/theme_studio_config_provider.dart';
import 'package:privacy_gui/demo/theme_studio/studio_theme_builder.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/page/apps/providers/apps_capability_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:privacy_gui/util/debug_mixin.dart';
import 'package:privacy_gui/util/app_utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Unified TopBar for the app.
///
/// Structure: [App Title] — [MenuHolder top (desktop)] — [Apps button (if logged in)] — [GeneralSettingsWidget]
///
/// Supports:
/// - Optional [controllerProvider] for custom menu controller (defaults to uspMenuController)
/// - Download log via rapid taps on the title area (DebugObserver)
/// - Apps button visibility based on login state and capability
class UspTopBar extends ConsumerStatefulWidget {
  final Provider<MenuController>? controllerProvider;

  const UspTopBar({super.key, this.controllerProvider});

  @override
  ConsumerState<UspTopBar> createState() => _UspTopBarState();
}

class _UspTopBarState extends ConsumerState<UspTopBar> with DebugObserver {
  @override
  Widget build(BuildContext context) {
    // Build dark theme reactively from current design style
    final darkTheme = _buildCurrentDarkTheme();
    final colorScheme = darkTheme.colorScheme;

    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onTap: () {
          if (increase()) {
            Utils.exportLogFile(context);
          }
        },
        child: Theme(
          data: darkTheme,
          child: AppSurface(
            height: 64,
            padding: const EdgeInsets.only(left: 24.0, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.titleLarge(
                  loc(context).appTitle,
                  color: colorScheme.onSurface,
                ),
                // The one child of this row that can yield (#1328). All three
                // used to be inflexible, so the row simply overflowed once the
                // nav chips appeared at 601px. The nav is the right one to bound:
                // the title is "Linksys Now" in all 26 locales and the trailing
                // icons are fixed-size, so the nav is both the widest and the
                // only child with a narrower form to fall back on.
                //
                // `Flexible` alone would not be enough — `AppChipGroup` wraps by
                // default, and a wrap inside this fixed 64px surface is a
                // vertical overflow. `TopNavigationMenu` passes `wrap: false` for
                // exactly this reason; the two changes only work together.
                Flexible(
                  child: MenuHolder(
                    type: MenuDisplay.top,
                    controllerProvider:
                        widget.controllerProvider ?? uspMenuController,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ref.watch(authProvider
                            .select((v) => v.value?.isLoggedIn ?? false)) &&
                        (ref.watch(appsCapabilityProvider).valueOrNull ??
                            false))
                      Tooltip(
                        message: loc(context).apps,
                        child: AppIconButton(
                          icon: AppIcon.font(Icons.apps,
                              color: colorScheme.onSurface),
                          identifier: 'topbar-apps',
                          // Pushing, not going: this button lives in the global
                          // top bar, so it is pressed from whichever page the
                          // user is on. `go` replaced the location and dropped
                          // that page, leaving Apps' back arrow to fall through
                          // to its `backFallback: uspMenu` — so back from Apps
                          // landed on the Menu no matter where you came from
                          // (#1434, the shape of #1421).
                          //
                          // And guarded, because the Apps page hosts this same
                          // top bar: a plain push onto the page already on top
                          // changes nothing on screen while costing one more
                          // back per tap.
                          onTap: () =>
                              context.pushNamedIfNotCurrent(RouteNamed.uspApps),
                        ),
                      ),
                    const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: GeneralSettingsWidget(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ThemeData _buildCurrentDarkTheme() {
    final demoConfig = ref.watch(themeStudioConfigProvider);
    final themeConfig =
        ref.watch(themeConfigProvider.select((v) => v.valueOrNull));
    final userThemeColor =
        ref.watch(appSettingsProvider.select((s) => s.themeColor));

    return buildStudioThemeData(
      brightness: Brightness.dark,
      config: demoConfig,
      themeConfig: themeConfig,
      userThemeColor: userThemeColor,
    );
  }
}
