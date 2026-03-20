// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/menu_holder.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/util/debug_mixin.dart';
import 'package:privacy_gui/util/app_utils.dart';

class TopBar extends ConsumerStatefulWidget {
  final void Function(int)? onMenuClick;
  const TopBar({
    super.key,
    this.onMenuClick,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopBarState();
}

class _TopBarState extends ConsumerState<TopBar> with DebugObserver {
  @override
  Widget build(BuildContext context) {
    // Watch Theme.of(context) to trigger rebuild when global theme changes
    Theme.of(context);

    // Use dark theme's color scheme for TopBar
    final darkTheme = getIt.get<ThemeData>(instanceName: 'darkThemeData');
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
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.titleLarge(loc(context).appTitle,
                    color: colorScheme.onSurface),
                MenuHolder(type: MenuDisplay.top),
                const Wrap(
                  children: [
                    Padding(
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
}
