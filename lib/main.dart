import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/route/route.dart';



void main() {
  runApp(const NavigatorDemo());
}

class NavigatorDemo extends StatelessWidget {
  const NavigatorDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Setup Router Demo',
      theme: MoabTheme.setupModuleLightModeData,
      routerDelegate: SetupRouterDelegate(),
      routeInformationParser: SetupRouteInformationParser(),
    );
  }
}
