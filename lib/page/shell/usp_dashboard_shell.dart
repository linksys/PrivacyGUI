import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/_shared/helpers/recovery_dialog_helper.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:privacy_gui/components/session/session_exit_sink.dart';
import 'package:privacy_gui/demo/providers/theme_studio_config_provider.dart';
import 'package:privacy_gui/demo/providers/demo_ui_provider.dart';
import 'package:privacy_gui/demo/theme_studio/studio_theme_builder.dart';
import 'package:privacy_gui/demo/theme_studio/theme_studio_panel.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/menu_holder.dart';
import 'package:privacy_gui/config/global_config.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/page/_shared/components/sse_connection_banner.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
import 'package:privacy_gui/page/_shared/providers/usp_bars_visible_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/linksys_mascot_renderer.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_providers.dart'
    show
        HealthDialogProviderArgs,
        mascotControllerProvider,
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

/// Navigates to the target of a health-dialog action button.
///
/// `pushNamed`, not `push`: every dimension supplies a `RouteNamed.*` value, and
/// `push` takes a *location*. go_router normalizes a location without a leading
/// slash by prepending one, so `'uspFirewall'` becomes the root-level
/// `/uspFirewall` — which matches nothing for the four targets registered as
/// nested children (Firewall and DMZ under `/uspAdvancedSettings`, Internet
/// Settings likewise, Unified Diagnostics under `/uspMenu`). The five top-level
/// targets appeared to work only because a top-level route's name and its path
/// happen to be the same string. The named API resolves through the route tree
/// and builds the nested location, which is what the call site always meant
/// (#1435).
///
/// A top-level function rather than a closure inside `build` so the verb is
/// reachable from a test; the guard lives in
/// `test/page/dashboard/mascot/health/health_dialog_navigation_test.dart`.
void pushHealthActionTarget(BuildContext context, String routeName) {
  if (!context.mounted) return;
  context.pushNamed(routeName);
}

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

  /// The two things this shell does with the connection state: open the natural
  /// recovery dialog on the way *into* a wait, and — via
  /// [listenForCoreSessionExit] — end the session when `lib/core/` reports that
  /// one is over.
  ///
  /// ## Why the session ends here and not where it is decided
  ///
  /// `AppConnectionStateNotifier`'s three exits — the manual one, a router that
  /// came back factory-reset, a router that came back with a different serial —
  /// each used to finish with `ref.read(authProvider.notifier).logout()`. That put
  /// three things inside a provider under `lib/core/`: the decision to sign a
  /// person out, the Remote-Assistance teardown-by-cause that
  /// `SessionStrategy.end` owns, and the navigation that follows. #1323 makes the
  /// core report instead — a state plus an [EndCause] — and the page layer acts.
  /// `session_teardown_call_sites_test.dart` is what keeps there being one actor.
  ///
  /// ## Why the shell, and why that is no longer an "always mounted" claim
  ///
  /// This is the widest thing mounted for the whole time a `/usp*` page is up: a
  /// `ShellRoute` builder wrapping all of them, whose `State` survives navigation
  /// between them. It is *not* mounted for the whole time an exit can be decided,
  /// which an earlier version of this comment claimed — two of the three exits are
  /// resolved by a `Timer.periodic` on an app-lifetime notifier, so the trigger
  /// being on a `/usp*` page says nothing about where the app is when the probe
  /// answers. [listenForCoreSessionExit] carries that argument and the catch-up
  /// read that makes a missed report late rather than lost; the app root, which
  /// *is* always mounted, was measured to be the wrong place for a different
  /// reason and the measurement is recorded there.
  @override
  void initState() {
    super.initState();
    listenForCoreSessionExit(ref);
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
    final demoConfig = ref.watch(themeStudioConfigProvider);
    final themeConfig = ref.watch(themeConfigProvider).valueOrNull;
    final userThemeColor =
        ref.watch(appSettingsProvider.select((s) => s.themeColor));

    final darkTheme = buildStudioThemeData(
      brightness: Brightness.dark,
      config: demoConfig,
      themeConfig: themeConfig,
      userThemeColor: userThemeColor,
    );

    final showMascot =
        ref.watch(appSettingsProvider.select((s) => s.showMascot));
    final isDashboardReady = ref.watch(dashboardDomainReadyProvider).hasValue;
    final surface = ref.watch(surfaceStrategyProvider);
    final mascotController = ref.watch(mascotControllerProvider);
    final dialogProvider = ref.watch(mascotHealthDialogProvider(
      HealthDialogProviderArgs(
        widgetRef: ref,
        onNavigate: (routeName) => pushHealthActionTarget(context, routeName),
        onOpenAiAssistant: () => openAiAssistantWithTransition(context),
        getFaqCategoryTitle: (category) => category.displayString(context),
        getFaqItemTitle: (item) => item.displayString(context),
      ),
    ));

    // Activate this surface's ambient coordinators — locally that is the mascot's
    // random-speech timer. Watched for the side effect, values discarded; the
    // shell does the watching so Riverpod registers the dependency against this
    // element, which is why the strategy hands back providers rather than taking
    // a `ref`.
    for (final coordinator in surface.ambientCoordinators()) {
      ref.watch(coordinator);
    }

    final isThemePanelOpen = ref.watch(demoUIProvider).isThemePanelOpen;

    final Widget content = Stack(
      children: [
        Column(
          children: [
            const SseConnectionBanner(),
            // Remote Assistance Banner (for PENDING status after refresh,
            // client-side only). `?? SizedBox.shrink()` rather than a null-check
            // `if`: a surface without this banner renders the same nothing the
            // gate used to, and the shell holds no condition either way.
            surface.assistanceBanner() ?? const SizedBox.shrink(),
            Expanded(
              child: BarsVisibilityScrollListener(child: widget.child),
            ),
          ],
        ),
        // The indicator for the session this build is *inside* (floating,
        // top-right). Local has none — before #1497 the chip was mounted
        // unconditionally here and returned `SizedBox.shrink()` from its own
        // `build`, so the shell said "always" and the widget said "only in
        // remote"; now one of them decides.
        surface.sessionIndicator() ?? const SizedBox.shrink(),
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
        // The mascot is a sibling layer, not a wrapper, and it is deliberately
        // last.
        //
        // Wrapping the shell in it crashed the app every time the Show Mascot
        // switch was flipped. `widget.child` above is the `ShellRoute`'s
        // Navigator, held by the `uspShellNavigatorKey` global key, so
        // inserting or removing anything above it does not rebuild that
        // subtree — the framework deactivates and reactivates it at its new
        // depth. Reactivation re-attaches the Navigator's overlay children,
        // and that `markNeedsLayout` lands inside a `LayoutBuilder`'s
        // `performLayout`, which the framework asserts against: "A
        // _RenderLayoutBuilder was mutated in _RenderLayoutBuilder.performLayout".
        //
        // As a sibling appended at the end, toggling it leaves every earlier
        // child's index untouched, so the Navigator never moves. Staying a
        // sibling is what keeps this fixed: reintroducing a wrapper around
        // page content — mascot or otherwise — brings the crash back.
        //
        // `GlobalConfig.remote.mascotEnabled` excludes remote assistance and
        // E2E mock builds (kept in sync with the General Settings toggle).
        if (showMascot && isDashboardReady && GlobalConfig.remote.mascotEnabled)
          Positioned.fill(
            child: MascotOverlay(
              controller: mascotController,
              dialogProvider: dialogProvider,
              spec: const MascotSpec(
                renderer: LinksysMascotRenderer(),
              ),
              // Nothing to wrap now that the page is a sibling; the overlay
              // still lays its own children out against the full shell.
              //
              // An empty box would not hit-test anyway, but `StackFit.expand`
              // inside the overlay stretches whatever is here across the whole
              // shell — so the pass-through is structural rather than a
              // property of `SizedBox`, and survives someone putting a real
              // widget here later.
              child: const IgnorePointer(child: SizedBox.shrink()),
            ),
          ),
      ],
    );

    return Scaffold(
      // Client-side session recovery: locally this wraps the content in
      // `RemoteAssistanceSessionGuard`, which shows a blocking dialog when an
      // ACTIVE session survived a page refresh. The remote surface returns the
      // content unwrapped — it *is* the session, so there is nothing to guard.
      body: surface.sessionGuard(child: content),
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

/// Hides the top bar and the menu rail while the page scrolls down, and brings
/// them back when it scrolls up — or when it returns to the top by any other
/// means (#1032).
///
/// A widget of its own, mounted by the shell, so both rules can be driven from a
/// test: the shell itself needs a dozen providers before it will build, and the
/// rules are the part that has been wrong.
///
/// ## The two rules, and why the second one exists
///
/// Direction alone was the whole rule, and it is a *latch*: "hidden" persists
/// until something scrolls up. Nothing in it relates to where the page actually
/// is, so any event that returns the page to the top without a scroll gesture
/// leaves the bars hidden over a page that is already at its first row — and
/// there is then no way to scroll up out of it, because
/// `ScrollPositionWithSingleContext.pointerScroll` returns before it updates the
/// direction when the target offset equals the current one. A wheel at the top
/// emits nothing at all, which is why #1032's reporter had to scroll down first
/// and then up.
///
/// Two things reset the offset like that. The edit-mode toggle used to, and is
/// fixed where it happens (`_gridScrollOffset` in
/// `usp_sliver_dashboard_view.dart`); a window
/// resize that crosses a breakpoint still does, deliberately — the dashboard
/// withholds the grid for the frame it is a breakpoint behind, and a frame with
/// no grid has no scroll extent to hold a position in. So the second rule is here
/// rather than at either site: *arriving* at the top shows the bars, whatever
/// moved the page there.
///
/// ## Why arriving, and not merely being there
///
/// The transition is what is watched, not the offset. A drag that starts at the
/// top reports `reverse` before the first pixel moves — the bars hide, and the
/// page is still at 0 for that instant. A rule reading "at the top ⇒ visible"
/// would undo the hide on the next notification and the bars would never hide on
/// a touch drag at all. Only a move from somewhere else *to* the top counts.
class BarsVisibilityScrollListener extends ConsumerStatefulWidget {
  const BarsVisibilityScrollListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BarsVisibilityScrollListener> createState() =>
      _BarsVisibilityScrollListenerState();
}

class _BarsVisibilityScrollListenerState
    extends ConsumerState<BarsVisibilityScrollListener> {
  /// Where the page's own viewport last reported itself, so the arrival at the
  /// top can be told from having been there all along.
  ///
  /// Null until the first notification: a page that opens at the top has not
  /// arrived anywhere, and the bars are visible already.
  ///
  /// Not cleared on a route change, and it does not need to be: the shell keeps
  /// this listener across them, so the first notification from the next page's
  /// viewport reads as an arrival from wherever the last one had got to — which
  /// is the answer the route's own reset already gives (`route_usp_dashboard`),
  /// for every page rather than just the dashboard.
  double? _lastPixels;

  void _setVisible(bool visible) {
    ref.read(uspBarsVisibleProvider.notifier).state = visible;
    ref.read(uspMenuController).setMenuVisible(visible);
  }

  /// Records the page viewport's position, and shows the bars if it just came
  /// back to the top.
  ///
  /// `depth == 0` keeps this to the page's own viewport: a list inside a card
  /// reports its own offset, which is nothing to do with where the page is. The
  /// axis check is the same filter for a horizontal strip at page level.
  void _observePosition(ScrollMetrics metrics, int depth) {
    if (depth != 0 || metrics.axis != Axis.vertical) return;

    final previous = _lastPixels;
    _lastPixels = metrics.pixels;
    final arrivedAtTop = previous != null &&
        previous > metrics.minScrollExtent &&
        metrics.pixels <= metrics.minScrollExtent;
    if (arrivedAtTop) _setVisible(true);
  }

  @override
  Widget build(BuildContext context) {
    // Two listeners because the reset does not always come with a scroll:
    // `ScrollMetricsNotification` is not a `ScrollNotification`, and it is the
    // only thing dispatched when a viewport loses its extent and the position is
    // corrected to the top under it.
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        _observePosition(notification.metrics, notification.depth);
        return false;
      },
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is UserScrollNotification) {
            final direction = notification.direction;
            if (direction == ScrollDirection.reverse) {
              // Scrolling down → hide bars
              _setVisible(false);
            } else if (direction == ScrollDirection.forward) {
              // Scrolling up → show bars
              _setVisible(true);
            }
          }
          _observePosition(notification.metrics, notification.depth);
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
