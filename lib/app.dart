import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/firebase/notification_helper.dart';
import 'package:linksys_app/page/components/layouts/root_container.dart';
import 'package:linksys_app/providers/app_settings/app_settings_provider.dart';
import 'package:linksys_app/providers/auth/auth_provider.dart';
import 'package:linksys_app/providers/connectivity/connectivity_provider.dart';
import 'package:linksys_app/page/dashboard/providers/smart_device_provider.dart';
import 'package:linksys_app/route/route_model.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

    ref.read(smartDeviceProvider.notifier).init();
    final router = ref.watch(routerProvider);
    router.routerDelegate.removeListener(_onReceiveRouteChanged);
    router.routerDelegate.addListener(_onReceiveRouteChanged);

    return MaterialApp.router(
      onGenerateTitle: (context) => loc(context).app_title,
      theme: linksysLightThemeData,
      darkTheme: linksysDarkThemeData,
      themeMode: appSettings.themeMode,
      locale: appSettings.locale ?? Locale(Intl.getCurrentLocale()),
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
      ref.read(connectivityProvider.notifier).forceUpdate().then((_) {
        if (ref.read(authProvider).value?.loginType != LoginType.none) {
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
}
