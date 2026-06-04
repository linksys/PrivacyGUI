import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';
import 'package:privacy_gui/demo/theme_studio/demo_theme_builder.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_panel.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/page/_shared/components/sse_connection_banner.dart';
import 'package:privacy_gui/page/_shared/providers/usp_bars_visible_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/linksys_mascot_renderer.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_providers.dart'
    show
        mascotControllerProvider,
        mascotDialogProvider,
        mascotRandomSpeechProvider;
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

    final showMascot =
        ref.watch(appSettingsProvider.select((s) => s.showMascot));
    final isDashboardReady = ref.watch(dashboardDomainReadyProvider).hasValue;
    final mascotController = ref.watch(mascotControllerProvider);
    final dialogProvider = ref.watch(mascotDialogProvider(context));

    // Watch the random speech provider to keep it alive
    ref.watch(mascotRandomSpeechProvider);

    // Start/stop random speech based on mascot visibility
    ref.listen<bool>(
      appSettingsProvider.select((s) => s.showMascot),
      (_, show) {
        if (show && ref.read(dashboardDomainReadyProvider).hasValue) {
          ref.read(mascotRandomSpeechProvider.notifier).start(mascotController);
        } else {
          ref.read(mascotRandomSpeechProvider.notifier).stop();
        }
      },
    );

    ref.listen<AsyncValue<void>>(
      dashboardDomainReadyProvider,
      (_, ready) {
        if (ready.hasValue && ref.read(appSettingsProvider).showMascot) {
          ref.read(mascotRandomSpeechProvider.notifier).start(mascotController);
        }
      },
    );

    // Initial start (listen doesn't fire on first build)
    if (showMascot && isDashboardReady) {
      Future.microtask(() {
        ref.read(mascotRandomSpeechProvider.notifier).start(mascotController);
      });
    }

    final isThemePanelOpen = ref.watch(demoUIProvider).isThemePanelOpen;

    Widget content = Stack(
      children: [
        Column(
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
        // Theme Studio Panel (shell-level so it works on all pages)
        if (BuildConfig.enableThemeStudio)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            top: 0,
            bottom: 0,
            right: isThemePanelOpen ? 0 : -500,
            width: 500,
            child: const Material(
              elevation: 16,
              child: ThemeStudioPanel(),
            ),
          ),
      ],
    );

    // Wrap with MascotOverlay only if mascot is enabled and dashboard is ready
    if (showMascot && isDashboardReady) {
      content = MascotOverlay(
        controller: mascotController,
        dialogProvider: dialogProvider,
        spec: const MascotSpec(
          renderer: LinksysMascotRenderer(),
        ),
        child: content,
      );
    }

    return Scaffold(
      body: content,
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
