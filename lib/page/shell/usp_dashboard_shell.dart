import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';
import 'package:privacy_gui/demo/theme_studio/demo_theme_builder.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_panel.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/page/_shared/components/remote_session_chip.dart';
import 'package:privacy_gui/page/_shared/components/sse_connection_banner.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_banner.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_session_guard.dart';
import 'package:privacy_gui/page/_shared/providers/usp_bars_visible_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/linksys_mascot_renderer.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_providers.dart'
    show
        HealthDialogProviderArgs,
        mascotControllerProvider,
        mascotCoordinatorProvider,
        mascotHealthDialogProvider,
        openAiAssistantWithTransition;
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
class UspDashboardShell extends ConsumerStatefulWidget {
  final Widget child;

  const UspDashboardShell({super.key, required this.child});

  @override
  ConsumerState<UspDashboardShell> createState() => _UspDashboardShellState();
}

class _UspDashboardShellState extends ConsumerState<UspDashboardShell> {
  bool _recoveryDialogShowing = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(appConnectionStateProvider, (prev, next) {
      if (next == AppConnectionState.waitingForRecovery &&
          prev != AppConnectionState.waitingForRecovery &&
          !_recoveryDialogShowing) {
        final notifier = ref.read(appConnectionStateProvider.notifier);
        final isNatural =
            notifier.recoveryContext?.trigger == RecoveryTrigger.natural;
        if (isNatural) {
          _showNaturalRecoveryDialog();
        }
      }
    });
  }

  Future<void> _showNaturalRecoveryDialog() async {
    if (ref.read(appConnectionStateProvider) !=
        AppConnectionState.waitingForRecovery) {
      return;
    }
    _recoveryDialogShowing = true;
    try {
      await showRecoveryDialog(
        context,
        ref,
        trigger: RecoveryTrigger.natural,
        cooldown: Duration.zero,
        skipEnterWaiting: true,
        title: loc(context).connectionLost,
        message:
            'Lost connection to the router. Attempting to reconnect automatically...',
        successMessage: loc(context).reconnectedToRouter,
      );
    } finally {
      _recoveryDialogShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final isRemoteMode = GlobalConfig.remote.isActive;
    final mascotController = ref.watch(mascotControllerProvider);
    final dialogProvider = ref.watch(mascotHealthDialogProvider(
      HealthDialogProviderArgs(
        widgetRef: ref,
        onNavigate: (routeName) {
          if (context.mounted) context.push(routeName);
        },
        onOpenAiAssistant: () => openAiAssistantWithTransition(context),
        getFaqCategoryTitle: (category) => category.displayString(context),
        getFaqItemTitle: (item) => item.displayString(context),
      ),
    ));

    // Activate mascot coordinator (manages random speech timer internally)
    // Skip in remote mode to avoid unnecessary processing
    if (!isRemoteMode) {
      ref.watch(mascotCoordinatorProvider);
    }

    final isThemePanelOpen = ref.watch(demoUIProvider).isThemePanelOpen;

    Widget content = Stack(
      children: [
        Column(
          children: [
            const SseConnectionBanner(),
            // Remote Assistance Banner (for PENDING status after refresh, client-side only)
            if (!isRemoteMode) const RemoteAssistanceBanner(),
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
                child: widget.child,
              ),
            ),
          ],
        ),
        // Remote session chip (floating, top-right)
        const RemoteSessionChip(),
        // Theme Studio Panel (shell-level so it works on all pages)
        if (GlobalConfig.feature.enableThemeStudio)
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

    // Wrap with MascotOverlay only if mascot is enabled, dashboard is ready,
    // and NOT in remote mode (mascot hidden in remote assistance)
    if (showMascot && isDashboardReady && !isRemoteMode) {
      content = MascotOverlay(
        controller: mascotController,
        dialogProvider: dialogProvider,
        spec: const MascotSpec(
          renderer: LinksysMascotRenderer(),
        ),
        child: content,
      );
    }

    // Wrap with RemoteAssistanceSessionGuard for client-side session recovery
    // (shows blocking dialog if ACTIVE session exists after page refresh)
    if (!isRemoteMode) {
      content = RemoteAssistanceSessionGuard(child: content);
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
