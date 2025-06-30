import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

class ThemeColorTile extends ConsumerStatefulWidget {
  const ThemeColorTile({
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ThemeColorTileState();
}

class _ThemeColorTileState extends ConsumerState<ThemeColorTile> {
  Widget _colorRect(Color color, bool selected) {
    return InkWell(
      onTap: () {
        final appSettings = ref.read(appSettingsProvider);
        ref
            .read(appSettingsProvider.notifier)
            .update(appSettings.copyWith(themeColor: () => color));
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? Theme.of(context).colorScheme.outline : color,
              width: 2.0),
          color: color,
        ),
        width: 24,
        height: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultThemeColor = Color(primaryTonal.get(40));
    final selectedThemeColor =
        ref.watch(appSettingsProvider.select((value) => value.themeColor));
    final customThemeColor = Utils.hexToColor(BuildConfig.customThemeColor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelMedium('Theme Color'),
        const AppGap.medium(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (customThemeColor != null)
              _colorRect(
                  customThemeColor, selectedThemeColor == customThemeColor)
            else
              _colorRect(
                  defaultThemeColor, selectedThemeColor == defaultThemeColor),
            _colorRect(Colors.amber, selectedThemeColor == Colors.amber),
            _colorRect(
                Colors.deepPurple, selectedThemeColor == Colors.deepPurple),
            _colorRect(
                Colors.tealAccent, selectedThemeColor == Colors.tealAccent),
            _colorRect(Colors.pink, selectedThemeColor == Colors.pink),
          ],
        ),
      ],
    );
  }
}
