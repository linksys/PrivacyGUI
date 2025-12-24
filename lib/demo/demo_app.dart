import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/layouts/root_container.dart';
import 'package:privacy_gui/providers/app_settings/app_settings_provider.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/util/languages.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Demo version of the Linksys application.
///
/// This app uses mock providers instead of real network services,
/// making it suitable for:
/// - UI demonstrations
/// - Design reviews
/// - Sales presentations
/// - Training purposes
class DemoLinksysApp extends ConsumerStatefulWidget {
  const DemoLinksysApp({super.key});

  @override
  ConsumerState<DemoLinksysApp> createState() => _DemoLinksysAppState();
}

class _DemoLinksysAppState extends ConsumerState<DemoLinksysApp> {
  LinksysRoute? _currentRoute;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Use the main app's routerProvider for routing
    final router = ref.watch(routerProvider);

    // Add listener for route changes
    router.routerDelegate.addListener(_onReceiveRouteChanged);

    final appSettings = ref.watch(appSettingsProvider);
    final systemLocaleStr = Intl.getCurrentLocale();
    final systemLocale = Locale(getLanguageData(systemLocaleStr)['value']);

    final themeColor = appSettings.themeColor ?? AppPalette.brandPrimary;
    final themeConfig = getIt<ThemeJsonConfig>();
    final appLightTheme = themeConfig.createLightTheme(themeColor);
    final appDarkTheme = themeConfig.createDarkTheme(themeColor);

    return MaterialApp.router(
      onGenerateTitle: (context) => '${loc(context).appTitle} (Demo)',
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: appSettings.themeMode,
      locale: appSettings.locale ?? systemLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => Material(
        child: DesignSystem.init(
          context,
          Stack(
            children: [
              AppRootContainer(
                route: _currentRoute,
                child: child,
              ),
              // Demo mode banner
              const Positioned(
                top: 0,
                right: 0,
                child: _DemoModeBanner(),
              ),
            ],
          ),
        ),
      ),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }

  void _onReceiveRouteChanged() {
    final router = ref.read(routerProvider);
    Future.delayed(Duration.zero).then((_) {
      if (!mounted) return;
      final GoRoute? page = router
              .routerDelegate.currentConfiguration.isNotEmpty
          ? router.routerDelegate.currentConfiguration.last.route as GoRoute?
          : null;
      if (page is LinksysRoute) {
        setState(() {
          _currentRoute = page;
        });
      } else if (_currentRoute != null) {
        _currentRoute = null;
      }
    });
  }
}

/// A banner indicating that the app is running in demo mode.
class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade700,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'DEMO',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
