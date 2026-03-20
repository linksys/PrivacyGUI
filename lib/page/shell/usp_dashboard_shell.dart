import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import 'package:privacy_gui/demo/theme_studio/demo_theme_builder.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/page/_shared/components/sse_connection_banner.dart';
import 'package:privacy_gui/page/_shared/providers/usp_bars_visible_provider.dart';

/// Riverpod provider for the USP-specific [MenuController].
///
/// Uses [uspShellNavigatorKey] and [NaviType.resolveUspPath] so that tab
/// selection navigates to USP routes instead of JNAP routes.
final uspMenuController = Provider((ref) => MenuController(
      navigatorKey: uspShellNavigatorKey,
      pathResolver: (type) => type.resolveUspPath(),
    ));

/// USP Dashboard shell — wraps USP child routes with a shared Scaffold.
///
/// Uses the shared [MenuHolder] widget (same as JNAP) with the USP-specific
/// [uspMenuController] so that tab selection targets USP routes.
///
/// Scroll detection is at the shell level so top/bottom bar hide-on-scroll
/// applies to ALL child pages, not just the dashboard.
class UspDashboardShell extends ConsumerWidget {
  final Widget child;

  const UspDashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger SSE bootstrap — connects SSE + registers core subscriptions.
    // FutureProvider is lazy; watching it ensures the connection starts
    // as soon as the shell is rendered (i.e., after successful login).
    ref.watch(sseBootstrapProvider);

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

    return Scaffold(
      body: Column(
        children: [
          const SseConnectionBanner(),
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                final direction = notification.direction;
                if (direction == ScrollDirection.reverse) {
                  // Scrolling down → hide bars
                  ref.read(uspBarsVisibleProvider.notifier).state = false;
                  ref.read(uspMenuController).setMenuVisible(false);
                } else if (direction == ScrollDirection.forward) {
                  // Scrolling up → show bars
                  ref.read(uspBarsVisibleProvider.notifier).state = true;
                  ref.read(uspMenuController).setMenuVisible(true);
                }
                return false;
              },
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: darkTheme,
        child: MenuHolder(
          type: MenuDisplay.bottom,
          controllerProvider: uspMenuController,
        ),
      ),
    );
  }
}
