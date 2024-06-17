import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/firebase/notification_helper.dart';
import 'package:privacy_gui/page/components/layouts/root_container.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/smart_device_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/util/languages.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LinksysApp extends ConsumerStatefulWidget {
  const LinksysApp({Key? key}) : super(key: key);

  @override
  ConsumerState<LinksysApp> createState() => _LinksysAppState();
}

class _LinksysAppState extends ConsumerState<LinksysApp>
    with WidgetsBindingObserver {
  LinksysRoute? _currentRoute;
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();

    final connectivity = ref.read(connectivityProvider.notifier);
    connectivity.start();
    connectivity.forceUpdate().then((value) => _initAuth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(connectivityProvider.notifier).stop();
    apnsStreamSubscription?.cancel();
    ref
        .read(routerProvider)
        .routerDelegate
        .removeListener(_onReceiveRouteChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    logger.d('App:: build: $_currentRoute');

    final appSettings = ref.watch(appSettingsProvider);
    final systemLocaleStr = Intl.getCurrentLocale();
    final systemLocale = Locale(getLanguageData(systemLocaleStr)['value']);
    ref.read(smartDeviceProvider.notifier).init();
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
        child: CustomResponsive(
          child: AppRootContainer(
            routeConfig: _currentRoute?.config ?? const LinksysRouteConfig(),
            child: child,
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
    logger.v('didChangeAppLifecycleState: ${state.name}');
    if (state == AppLifecycleState.resumed) {
      ref
          .read(connectivityProvider.notifier)
          .forceUpdate()
          .then((_) => SharedPreferences.getInstance())
          .then((prefs) {
        final currentSN = prefs.getString(pCurrentSN);
        if (ref.read(authProvider).value?.loginType != LoginType.none &&
            currentSN?.isNotEmpty == true) {
          ref.read(pollingProvider.notifier).startPolling();
        }
      });
    } else if (state == AppLifecycleState.paused) {
      ref.read(pollingProvider.notifier).stopPolling();
    }
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
      logger.d('Router Delegate Changed! ${page?.name},');
      if (page is LinksysRoute) {
        setState(() {
          _currentRoute = page;
        });
        logger.d('Router Delegate Changed! $_currentRoute');
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
              platform: const NoTransitionsBuilder(),
          },
        )
      : null;
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
