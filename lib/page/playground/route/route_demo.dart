import 'package:flutter/material.dart';

import 'setup/setup.dart';

void main() {
  runApp(const NavigatorDemo());
}

class NavigatorDemo extends StatelessWidget {
  const NavigatorDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Setup Router Demo',
      routerDelegate: SetupRouterDelegate()
        ..setInitialRoutePath(SetupRoutePath.setupParent()),
      routeInformationParser: SetupRouteInformationParser(),
    );
  }
}
