import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import 'package:privacy_gui/demo/theme_studio/demo_theme_builder.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP-specific TopBar — visually matches the JNAP TopBar but without
/// JNAP-specific provider dependencies (deviceManager, remoteClient, etc.).
///
/// Structure: [App Title] — [MenuHolder top (desktop)] — [GeneralSettingsWidget]
class UspTopBar extends ConsumerWidget {
  const UspTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build dark theme reactively from current design style
    final darkTheme = _buildCurrentDarkTheme(ref);
    final colorScheme = darkTheme.colorScheme;

    return SafeArea(
      bottom: false,
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
              MenuHolder(
                type: MenuDisplay.top,
                controllerProvider: uspMenuController,
              ),
              const Padding(
                padding: EdgeInsets.all(4.0),
                child: GeneralSettingsWidget(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildCurrentDarkTheme(WidgetRef ref) {
    final demoConfig = ref.watch(demoThemeConfigProvider);
    final themeConfig = ref.watch(themeConfigProvider).valueOrNull;
    final userThemeColor =
        ref.watch(appSettingsProvider.select((s) => s.themeColor));

    return buildDemoThemeData(
      brightness: Brightness.dark,
      config: demoConfig,
      themeConfig: themeConfig,
      userThemeColor: userThemeColor,
    );
  }
}
