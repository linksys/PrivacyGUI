import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/route/route.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


void main() {
  runApp(const NavigatorDemo());
}

class NavigatorDemo extends StatelessWidget {
  const NavigatorDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.app_title,
      theme: MoabTheme.setupModuleLightModeData,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerDelegate: SetupRouterDelegate(),
      routeInformationParser: SetupRouteInformationParser(),
    );
  }
}
