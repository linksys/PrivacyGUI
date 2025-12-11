import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/layouts/root_container.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/util/debug_mixin.dart';
import 'package:privacy_gui/util/languages.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/theme/custom_responsive.dart';
import 'package:privacygui_widgets/theme/material/color_schemes.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The root widget of the Linksys application.
///
/// This is a [ConsumerStatefulWidget], which serves as the entry point for the
/// UI and integrates with the Riverpod state management system. It sets up the
/// `MaterialApp.router` and configures theme, localization, and routing for the
/// entire app.
class LinksysApp extends ConsumerStatefulWidget {
  /// Creates an instance of the [LinksysApp].
  const LinksysApp({Key? key}) : super(key: key);

  @override
  ConsumerState<LinksysApp> createState() => _LinksysAppState();
}

/// The state for the [LinksysApp] widget.
///
/// This class manages the lifecycle of the application. It initializes key services
/// like connectivity checking and authentication, observes app lifecycle events
/// (e.g., resumed, paused), and builds the main [MaterialApp.router]. It also
/// handles dynamic theme updates, localization, and listens for route changes
/// to update the UI accordingly.
class _LinksysAppState extends ConsumerState<LinksysApp>
    with DebugObserver, WidgetsBindingObserver {
  LinksysRoute? _currentRoute;
  late ConnectivityNotifier _connectivityNotifier;
  late GoRouterDelegate _routerDelegate;

  /// Initializes the state of the widget.
  ///
  /// This method is called when the widget is first inserted into the widget tree.
  /// It sets up an observer for app lifecycle events, starts the connectivity
  /// notifier, initializes the authentication service, and loads app settings.
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    _connectivityNotifier = ref.read(connectivityProvider.notifier);
    _connectivityNotifier.start();
    _connectivityNotifier.forceUpdate().then((value) => _initAuth());
    _routerDelegate = ref.read(routerProvider).routerDelegate;
    ref.read(appSettingsProvider.notifier).load();
    getVersion();
  }

  /// Cleans up resources when the widget is removed from the widget tree.
  ///
  /// This method removes the app lifecycle observer, stops the connectivity
  /// notifier, and removes the listener for route changes to prevent memory leaks.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityNotifier.stop();
    _routerDelegate.removeListener(_onReceiveRouteChanged);
    super.dispose();
  }

  /// Builds the main widget tree for the application.
  ///
  /// This method constructs the `MaterialApp.router`, which is the root of the
  /// application's UI. It configures the following:
  /// - **Theming:** Dynamically sets the light and dark themes based on the
  ///   user's selected theme color and mode from [appSettingsProvider].
  /// - **Localization:** Sets the application's locale based on user settings,
  ///   falling back to the system locale. It also provides the necessary
  ///   localization delegates and supported locales.
  /// - **Routing:** Integrates with `go_router` by providing its delegate,
  ///   parser, and information provider.
  /// - **Global UI:** Uses the `builder` property to wrap the entire app in
  ///   a `Material` widget, a `Shortcuts` and `Actions` setup for global hotkeys,
  ///   and a responsive layout container.
  @override
  Widget build(BuildContext context) {
    logger.d('App:: build: $_currentRoute');

    final appSettings = ref.watch(appSettingsProvider);
    final systemLocaleStr = Intl.getCurrentLocale();
    final systemLocale = Locale(getLanguageData(systemLocaleStr)['value']);
    final router = ref.watch(routerProvider);
    router.routerDelegate.removeListener(_onReceiveRouteChanged);
    router.routerDelegate.addListener(_onReceiveRouteChanged);

    final themeColor = appSettings.themeColor ?? AppPalette.brandPrimary;
    final appLightTheme = AppTheme.create(
      brightness: Brightness.light,
      seedColor: themeColor,
      designThemeBuilder: (scheme) => PixelDesignTheme.light(scheme),
    );
    final appDarkTheme = AppTheme.create(
      brightness: Brightness.dark,
      seedColor: themeColor,
      designThemeBuilder: (scheme) => PixelDesignTheme.dark(scheme),
    );
    return MaterialApp.router(
      onGenerateTitle: (context) => loc(context).appTitle,
      theme: appLightTheme.copyWith(extensions: [
        ...appLightTheme.extensions.values,
        lightColorSchemeExt
      ]),
      darkTheme: appDarkTheme.copyWith(
          extensions: [...appDarkTheme.extensions.values, darkColorSchemeExt]),
      themeMode: appSettings.themeMode,
      locale: appSettings.locale ?? systemLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Material(
        child: Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
                ToggleDisplayColumnOverlayIntent(),
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
                LogicalKeyboardKey.keyL): ToggleDownloadLogIntent()
          },
          child: Actions(
            dispatcher: AppGlobalActionDispatcher(),
            actions: {
              ToggleDisplayColumnOverlayIntent: CallbackAction(
                  onInvoke: (intent) => showColumnOverlayNotifier.value =
                      !showColumnOverlayNotifier.value),
              ToggleDownloadLogIntent: CallbackAction(onInvoke: (intent) {
                if (!increase()) return null;
                // context.pushNamed(RouteNamed.debug);
                Utils.exportLogFile(context);
                return null;
              }),
            },
            child: CustomResponsive(
              child: DesignSystem.init(
                context,
                AppRootContainer(
                  route: _currentRoute,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }

  /// Called when the system puts the app in the background or returns it to the foreground.
  ///
  /// This method is part of the [WidgetsBindingObserver] mixin. It logs the
  /// current lifecycle state. The commented-out code suggests it was intended
  /// to handle tasks like refreshing connectivity and polling when the app is
  /// resumed, and stopping polling when it is paused.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.i('didChangeAppLifecycleState: ${state.name}');
    // if (state == AppLifecycleState.resumed) {
    //   ref
    //       .read(connectivityProvider.notifier)
    //       .forceUpdate()
    //       .then((_) => SharedPreferences.getInstance())
    //       .then((prefs) {
    //     final currentSN = prefs.getString(pCurrentSN);
    //     if (currentSN != null &&
    //         ref.read(dashboardManagerProvider).deviceInfo?.serialNumber !=
    //             currentSN) {
    //       // if (mounted) {
    //       //   showRouterNotFoundAlert(context, ref);
    //       // }
    //     } else if (ref.read(authProvider).value?.loginType != LoginType.none &&
    //         currentSN?.isNotEmpty == true) {
    //       ref.read(pollingProvider.notifier).startPolling();
    //     }
    //   });
    // } else if (state == AppLifecycleState.paused) {
    //   ref.read(pollingProvider.notifier).stopPolling();
    // }
  }

  /// Initializes the authentication state.
  ///
  /// This method is called after the initial connectivity check. It triggers the
  /// `init` method of the [authProvider] and, upon completion, removes the
  /// native splash screen, revealing the app's UI.
  _initAuth() {
    ref.read(authProvider.notifier).init().then((_) {
      logger.d('init auth finish');
      FlutterNativeSplash.remove();
    });
  }

  /// A callback that is triggered whenever the route changes.
  ///
  /// This method listens to the `GoRouterDelegate` and updates the [_currentRoute]
  /// state variable whenever the user navigates to a new page. This allows
  /// other parts of the UI, like the [AppRootContainer], to adapt to the current route.
  void _onReceiveRouteChanged() {
    Future.delayed(Duration.zero).then((_) {
      if (!mounted) return;
      final router = ref.read(routerProvider);

      final GoRoute? page = router
              .routerDelegate.currentConfiguration.isNotEmpty
          ? router.routerDelegate.currentConfiguration.last.route as GoRoute?
          : null;
      logger.d('[$routeLogTag]:<${page?.name}>');
      if (page is LinksysRoute) {
        setState(() {
          _currentRoute = page;
        });
      } else if (_currentRoute != null) {
        // setState(() {
        //   _currentRoute = null;
        // });
        _currentRoute = null;
      }
    });
  }

  /// Provides a custom [PageTransitionsTheme] for the web platform.
  ///
  /// When the app is running on the web, this getter returns a theme that uses
  /// a simple fade transition for all page navigation, disabling the default
  /// platform-specific animations. For mobile, it returns `null`, allowing the
  /// default transitions to be used.
  PageTransitionsTheme? get pageTransitionsTheme => kIsWeb
      ? PageTransitionsTheme(
          builders: {
            // No animations for every OS if the app running on the web
            for (final platform in TargetPlatform.values)
              platform: const FadePageTransitionsBuilder(),
          },
        )
      : null;
}

/// A [PageTransitionsBuilder] that creates a simple fade-in transition.
///
/// This is used to provide a consistent, non-native transition animation,
/// particularly for the web platform.
class FadePageTransitionsBuilder extends PageTransitionsBuilder {
  /// Constructs a page transition animation that slides the page up.
  const FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double>? secondaryAnimation,
    Widget child,
  ) {
    return _FadePageTransition(routeAnimation: animation, child: child);
  }
}

/// A private widget that applies a fade transition to its child.
///
/// It wraps the child in a `FadeTransition` widget, driven by the provided
/// route animation. For mobile web, it also wraps the child in an
/// `InteractiveViewer` to allow for pinch-to-zoom.
class _FadePageTransition extends StatelessWidget {
  _FadePageTransition({
    required Animation<double>
        routeAnimation, // The route's linear 0.0 - 1.0 animation.
    required this.child,
  }) : _opacityAnimation = routeAnimation.drive(_easeInTween);

  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);

  final Animation<double> _opacityAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWebMobile = kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);

    return FadeTransition(
      opacity: _opacityAnimation,
      child: isWebMobile ? InteractiveViewer(child: child) : child,
    );
  }
}

/// A [PageTransitionsBuilder] that applies no transition animation.
///
/// This builder simply returns the child widget directly, resulting in an
/// instantaneous page change.
class NoTransitionsBuilder extends PageTransitionsBuilder {
  /// Creates an instance of [NoTransitionsBuilder].
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget? child,
  ) {
    // only return the child without warping it with animations
    return child!;
  }
}

/// An [Intent] used to signal the toggling of a display column overlay.
///
/// This is typically mapped to a keyboard shortcut for debugging UI layouts.
class ToggleDisplayColumnOverlayIntent extends Intent {}

/// An [Intent] used to signal the action of downloading a log file.
///
/// This is mapped to a keyboard shortcut for debugging and support purposes.
class ToggleDownloadLogIntent extends Intent {}

/// A custom [ActionDispatcher] for handling global actions.
///
/// This class can be extended to intercept and handle actions invoked via
/// shortcuts or other means at a global application level. Currently, it
// simply forwards the actions to the default dispatcher.
class AppGlobalActionDispatcher extends ActionDispatcher {
  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    super.invokeAction(action, intent, context);

    return null;
  }
}
