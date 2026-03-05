import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/general_settings_widget/general_settings_widget.dart';
import 'package:privacy_gui/usp_page/shell/usp_nav_tab.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP-specific TopBar — visually matches the JNAP TopBar but without
/// JNAP-specific provider dependencies (deviceManager, remoteClient, etc.).
///
/// Structure: [App Title] — [Navigation Chips (desktop)] — [GeneralSettingsWidget]
class UspTopBar extends StatelessWidget {
  const UspTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Use dark theme's color scheme (same as JNAP TopBar)
    final darkTheme = getIt.get<ThemeData>(instanceName: 'darkThemeData');
    final colorScheme = darkTheme.colorScheme;
    final isDesktop = !context.isMobileLayout;

    // Derive active tab from current route
    final uri = GoRouterState.of(context).uri.toString();
    final activeTab = UspNavTab.fromUri(uri);

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
              // Desktop: show navigation chip group in center
              if (isDesktop)
                _buildNavChips(context, activeTab)
              else
                const Spacer(),
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

  Widget _buildNavChips(BuildContext context, UspNavTab activeTab) {
    final tabs = UspNavTab.values;
    final selectedIndex = tabs.indexOf(activeTab);

    return AppChipGroup(
      chips: tabs
          .map((tab) => ChipItem(
                label: tab.label(context),
                icon: tab.icon,
                enabled: true,
              ))
          .toList(),
      selectedIndices: {selectedIndex},
      selectionMode: ChipSelectionMode.single,
      onSelectionChanged: (selectedIndices) {
        if (selectedIndices.isNotEmpty) {
          final tab = tabs[selectedIndices.first];
          context.goNamed(tab.routeName);
        }
      },
    );
  }
}
