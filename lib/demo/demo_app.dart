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

import 'widgets/demo_theme_settings_fab.dart';

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

    // Watch demo theme config for dynamic updates
    final demoConfig = ref.watch(demoThemeConfigProvider);

    // Use demo seedColor if set, otherwise fall back to appSettings
    final effectiveSeedColor = demoConfig.seedColor ?? appSettings.themeColor;

    // Build dynamic theme from demo config
    final themeData = _buildThemeData(
      brightness: appSettings.themeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
      style: demoConfig.style,
      globalOverlay: demoConfig.globalOverlay,
      visualEffects: demoConfig.visualEffects,
      userThemeColor: effectiveSeedColor,
    );

    final darkTheme = _buildThemeData(
      brightness: Brightness.dark,
      style: demoConfig.style,
      globalOverlay: demoConfig.globalOverlay,
      visualEffects: demoConfig.visualEffects,
      userThemeColor: effectiveSeedColor,
    );

    // Update GetIt with the new dark theme so BottomNavigationMenu (TopBar) picks it up.
    // This is safe because GetIt lookup is synchronous and we update before subtree builds.
    if (getIt.isRegistered<ThemeData>(instanceName: 'darkThemeData')) {
      getIt.unregister<ThemeData>(instanceName: 'darkThemeData');
    }
    getIt.registerSingleton<ThemeData>(darkTheme,
        instanceName: 'darkThemeData');

    return MaterialApp.router(
      onGenerateTitle: (context) => '${loc(context).appTitle} (Demo)',
      theme: themeData,
      darkTheme: darkTheme,
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
              // Theme settings FAB
              const DemoThemeSettingsFab(),
            ],
          ),
        ),
      ),
      routeInformationProvider: router.routeInformationProvider,
      routeInformationParser: router.routeInformationParser,
      routerDelegate: router.routerDelegate,
    );
  }

  /// Build theme data from dynamic configuration.
  ThemeData _buildThemeData({
    required Brightness brightness,
    required String style,
    GlobalOverlayType? globalOverlay,
    int visualEffects = AppThemeConfig.effectAll,
    Color? userThemeColor,
  }) {
    // Get base JSON config
    final themeConfig = getIt<ThemeJsonConfig>();
    final baseJson = brightness == Brightness.dark
        ? themeConfig.darkJson
        : themeConfig.lightJson;

    // Create dynamic config by merging base with overrides
    final dynamicJson = Map<String, dynamic>.from(baseJson);
    dynamicJson['style'] = style;
    if (globalOverlay != null) {
      dynamicJson['globalOverlay'] = globalOverlay.name;
    } else {
      dynamicJson.remove('globalOverlay');
    }
    dynamicJson['visualEffects'] = visualEffects;

    // Override seed color if user set one
    if (userThemeColor != null) {
      dynamicJson['seedColor'] =
          '#${userThemeColor.toARGB32().toRadixString(16).substring(2)}';
    }

    // Build design theme
    final designTheme = CustomDesignTheme.fromJson(dynamicJson);

    // Parse effective seed color
    final seedColorHex = dynamicJson['seedColor'] as String?;
    Color? parsedSeedColor;
    if (seedColorHex != null) {
      try {
        final cleanHex = seedColorHex.replaceAll('#', '');
        if (cleanHex.length == 6) {
          parsedSeedColor = Color(int.parse('FF$cleanHex', radix: 16));
        } else if (cleanHex.length == 8) {
          parsedSeedColor = Color(int.parse(cleanHex, radix: 16));
        }
      } catch (_) {}
    }
    final effectiveSeedColor =
        userThemeColor ?? parsedSeedColor ?? AppPalette.brandPrimary;

    return AppTheme.create(
      brightness: brightness,
      seedColor: effectiveSeedColor,
      designThemeBuilder: (_) => designTheme,
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
