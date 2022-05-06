import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/dashboard/view.dart';
import 'package:moab_poc/page/landing_page/view.dart';
import 'package:moab_poc/page/login/view.dart';
import 'package:moab_poc/page/mesh/view.dart';
import 'package:moab_poc/page/setup/home_view.dart';
import 'package:moab_poc/page/setup/get_wifi_up_view.dart';

void main() {
  runApp(const MoabApp());
}

class MoabApp extends StatelessWidget {
  const MoabApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeView(),
      // initialRoute: HomeView.routeName,
      routes: {
        // LandingPage.routeName: (context) => const LandingPage(),
        // LoginPage.routeName: (context) => const LoginPage(),
        // DashboardPage.routeName: (context) => const DashboardPage(),
        // MeshPage.routeName: (context) => const MeshPage(),
        GetWiFiUpView.routeName: (context) => GetWiFiUpView(),
      },
      theme: MoabTheme.setupModuleLightModeData,
      darkTheme: MoabTheme.setupModuleDarkModeData,
    );
  }
}
