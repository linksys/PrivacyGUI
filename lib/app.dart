import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/providers/polling_provider.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/firebase/notification_helper.dart';
import 'package:linksys_app/page/dashboard/view/dashboard_menu_view.dart';
import 'package:linksys_app/provider/auth/auth_provider.dart';
import 'package:linksys_app/provider/connectivity/connectivity_provider.dart';
import 'package:linksys_app/provider/smart_device_provider.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/theme_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LinksysApp extends ConsumerStatefulWidget {
  const LinksysApp({Key? key}) : super(key: key);

  @override
  ConsumerState<LinksysApp> createState() => _LinksysAppState();
}

class _LinksysAppState extends ConsumerState<LinksysApp> with WidgetsBindingObserver {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.read(smartDeviceProvider.notifier).init();
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => getAppLocalizations(context).app_title,
      theme: linksysLightThemeData,
      darkTheme: linksysDarkThemeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Container(
        color: Theme.of(context).colorScheme.shadow,
        child: AppResponsiveTheme(child: _build(child ?? Center())),
      ),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }

  Widget _build(Widget child) {
    return LayoutBuilder(builder: ((context, constraints) {
      final isDone = ref
          .watch(deviceManagerProvider.select((value) => value.deviceList))
          .isNotEmpty;
      if (constraints.maxWidth > 768 && isDone) {
        return Row(
          children: [
            SizedBox(
              width: 320,
              child: const DashboardMenuView(),
            ),
            Expanded(child: Container(child: child)),
          ],
        );
      } else {
        return child;
      }
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.v('didChangeAppLifecycleState: ${state.name}');
    if (state == AppLifecycleState.resumed) {
      ref.read(connectivityProvider.notifier).forceUpdate().then((_) {
        ref.read(pollingProvider.notifier).startPolling();
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

}