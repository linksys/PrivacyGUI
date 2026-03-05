import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/usp_page/shell/usp_nav_tab.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// USP Dashboard shell — wraps USP child routes with a shared Scaffold.
///
/// Parallel to the JNAP [DashboardShell] but independent of JNAP providers.
/// Shows a bottom navigation bar on mobile; desktop uses chip navigation
/// in [UspTopBar] instead.
class UspDashboardShell extends StatelessWidget {
  final Widget child;

  const UspDashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobileLayout;
    final uri = GoRouterState.of(context).uri.toString();
    final activeTab = UspNavTab.fromUri(uri);

    return Scaffold(
      body: child,
      bottomNavigationBar:
          isMobile ? _buildBottomNav(context, activeTab) : null,
    );
  }

  Widget _buildBottomNav(BuildContext context, UspNavTab activeTab) {
    // Force dark theme for bottom nav (same as JNAP)
    final darkTheme = getIt.get<ThemeData>(instanceName: 'darkThemeData');
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
