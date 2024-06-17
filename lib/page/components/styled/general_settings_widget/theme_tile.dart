import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class ThemeTile extends ConsumerStatefulWidget {
  const ThemeTile({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ThemeTileState();
}

class _ThemeTileState extends ConsumerState<ThemeTile> {
  Widget _displayTheme(ThemeMode theme) {
    final icon = switch (theme) {
      ThemeMode.system => LinksysIcons.autoAwesomeMosaic,
      ThemeMode.light => LinksysIcons.lightMode,
      ThemeMode.dark => LinksysIcons.darkMode,
    };
    final themeText = switch (theme) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const AppGap.medium(),
        AppText.labelMedium(themeText),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        ref.watch(appSettingsProvider.select((value) => value.themeMode));
    return InkWell(
      onTap: () {
        final appSettings = ref.read(appSettingsProvider);
        final nextThemeMode = appSettings.themeMode == ThemeMode.system
            ? ThemeMode.dark
            : appSettings.themeMode == ThemeMode.dark
                ? ThemeMode.light
                : ThemeMode.system;
        ref.read(appSettingsProvider.notifier).state =
            appSettings.copyWith(themeMode: nextThemeMode);
      },
      child: _displayTheme(theme),
    );
  }
}
