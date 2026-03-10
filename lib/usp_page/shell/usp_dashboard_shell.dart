import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import 'package:privacy_gui/demo/theme_studio/demo_theme_builder.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/usp_page/shell/usp_nav_tab.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Dashboard shell — wraps USP child routes with a shared Scaffold.
///
/// Parallel to the JNAP [DashboardShell] but independent of JNAP providers.
/// Shows a bottom navigation bar on mobile; desktop uses chip navigation
/// in [UspTopBar] instead.
class UspDashboardShell extends ConsumerWidget {
  final Widget child;

  const UspDashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = context.isMobileLayout;
    final uri = GoRouterState.of(context).uri.toString();
    final activeTab = UspNavTab.fromUri(uri);

    return Scaffold(
      body: child,
      bottomNavigationBar:
          isMobile ? _buildBottomNav(context, ref, activeTab) : null,
    );
  }

  Widget _buildBottomNav(
      BuildContext context, WidgetRef ref, UspNavTab activeTab) {
    // Build dark theme reactively from current design style
    final demoConfig = ref.watch(demoThemeConfigProvider);
    final themeConfig = ref.watch(themeConfigProvider).valueOrNull;
    final userThemeColor =
        ref.watch(appSettingsProvider.select((s) => s.themeColor));

    final darkTheme = buildDemoThemeData(
      brightness: Brightness.dark,
      config: demoConfig,
      themeConfig: themeConfig,
      userThemeColor: userThemeColor,
    );

    const tabs = UspNavTab.values;

    return Theme(
      data: darkTheme,
      child: AppNavigationBar(
        currentIndex: tabs.indexOf(activeTab),
        items: tabs
            .map((tab) => AppNavigationItem(
                  icon: Icon(tab.icon),
                  label: tab.label(context),
                ))
            .toList(),
        onTap: (index) {
          context.goNamed(tabs[index].routeName);
        },
      ),
    );
  }
}
