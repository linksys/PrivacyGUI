import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_widgets/theme/responsive_theme.dart';
import 'package:linksys_widgets/theme/theme_data.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Assign a globalKey in order to retrieve current Build Context
GlobalKey<NavigatorState> globalKey = GlobalKey();

Widget testableWidget(
        {required Widget child, List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        navigatorKey: globalKey,
        theme: linksysLightThemeData,
        darkTheme: linksysDarkThemeData,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AppResponsiveTheme(
            child: child,
          ),
        ),
      ),
    );
