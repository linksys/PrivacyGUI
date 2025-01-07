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
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/util/debug_mixin.dart';
import 'package:privacy_gui/util/languages.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/theme/_theme.dart';

class LinksysApp extends ConsumerStatefulWidget {
  const LinksysApp({Key? key}) : super(key: key);

  @override
  ConsumerState<LinksysApp> createState() => _LinksysAppState();
}

class _LinksysAppState extends ConsumerState<LinksysApp>
    with DebugObserver, WidgetsBindingObserver {
  LinksysRoute? _currentRoute;
  late ConnectivityNotifier _connectivityNotifier;
  late GoRouterDelegate _routerDelegate;

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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityNotifier.stop();
    _routerDelegate.removeListener(_onReceiveRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('App:: build: $_currentRoute');

    final appSettings = ref.watch(appSettingsProvider);
    final systemLocaleStr = Intl.getCurrentLocale();
    final systemLocale = Locale(getLanguageData(systemLocaleStr)['value']);
    final router = ref.watch(routerProvider);
    router.routerDelegate.removeListener(_onReceiveRouteChanged);
    router.routerDelegate.addListener(_onReceiveRouteChanged);

    return MaterialApp.router(
      onGenerateTitle: (context) => loc(context).appTitle,
      theme: linksysLightThemeData.copyWith(
          pageTransitionsTheme: pageTransitionsTheme),
      darkTheme: linksysDarkThemeData.copyWith(
          pageTransitionsTheme: pageTransitionsTheme),
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
                if (increase()) {
                  // context.pushNamed(RouteNamed.debug);
                  Utils.exportLogFile(context);
                  return;
                }
              }),
            },
            child: CustomResponsive(
              child: AppRootContainer(
                routeConfig:
                    _currentRoute?.config ?? const LinksysRouteConfig(),
                child: child,
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
    //       // TODO
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

  _initAuth() {
    ref.read(authProvider.notifier).init().then((_) {
      logger.d('init auth finish');
      FlutterNativeSplash.remove();
    });
  }

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
    final isWebMobile = kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

    return FadeTransition(
      opacity: _opacityAnimation,
      child: isWebMobile ? InteractiveViewer(child: child) : child,
    );
  }
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
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

class ToggleDisplayColumnOverlayIntent extends Intent {}

class ToggleDownloadLogIntent extends Intent {}

class AppGlobalActionDispatcher extends ActionDispatcher {
  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    logger.d('Action invoked: $action($intent) from $context');
    super.invokeAction(action, intent, context);

    return null;
  }

  @override
  (bool, Object?) invokeActionIfEnabled(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    logger.d('Action invoked: $action($intent) from $context');
    return super.invokeActionIfEnabled(action, intent, context);
  }
}
