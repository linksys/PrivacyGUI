import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class ThemeModeTile extends ConsumerStatefulWidget {
  final void Function(ThemeMode mode)? onSelected;
  final void Function()? onTap;

  const ThemeModeTile({
    super.key,
    this.onSelected,
    this.onTap,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ThemeModeTileState();
}

class _ThemeModeTileState extends ConsumerState<ThemeModeTile> {
  static const _themeModes = [
    ThemeMode.system,
    ThemeMode.light,
    ThemeMode.dark,
  ];

  IconData _iconForTheme(ThemeMode theme) {
    return switch (theme) {
      ThemeMode.system => AppFontIcons.autoAwesomeMosaic,
      ThemeMode.light => AppFontIcons.lightMode,
      ThemeMode.dark => AppFontIcons.darkMode,
    };
  }

  String _textForTheme(ThemeMode theme) {
    return switch (theme) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light Mode',
      ThemeMode.dark => 'Dark Mode',
    };
  }

  Widget _displayTheme(ThemeMode theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_iconForTheme(theme)),
        AppGap.lg(),
        AppText.labelMedium(_textForTheme(theme)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme =
        ref.watch(appSettingsProvider.select((value) => value.themeMode));
    return InkWell(
      onTap: () {
        showSimpleAppDialog(
          context,
          content: _themeList(theme),
        ).then((selectedMode) {
          if (selectedMode == null) {
            return;
          }
          widget.onSelected?.call(selectedMode);
        });
        widget.onTap?.call();
      },
      child: _displayTheme(theme),
    );
  }

  Widget _themeList(ThemeMode currentTheme) {
    final listHeight = (_themeModes.length * 56.0).clamp(100.0, 400.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Semantics(
        identifier: 'now-theme-mode-list',
        label: 'theme mode list',
        explicitChildNodes: true,
        child: SizedBox(
          height: listHeight,
          child: ListView.builder(
            itemCount: _themeModes.length,
            itemBuilder: (context, index) {
              final mode = _themeModes[index];
              final isSelected = currentTheme == mode;
              return AppListTile(
                key: Key('theme_mode_item_${mode.name}'),
                selected: isSelected,
                leading: AppIcon.font(_iconForTheme(mode)),
                title: Semantics(
                  identifier: 'now-theme-mode-item-${mode.name}',
                  child: AppText.labelLarge(_textForTheme(mode)),
                ),
                trailing: isSelected
                    ? Semantics(
                        identifier: 'now-theme-mode-item-checked',
                        label: 'checked',
                        child: const AppIcon.font(AppFontIcons.check),
                      )
                    : null,
                onTap: () {
                  context.pop(mode);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
