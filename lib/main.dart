import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/playground/entry_page.dart';
import 'package:moab_poc/page/playground/setup_page_1.dart';
import 'package:moab_poc/page/playground/setup_page_2.dart';
import 'package:moab_poc/page/dashboard/view.dart';
import 'package:moab_poc/page/landing_page/view.dart';
import 'package:moab_poc/page/login/view.dart';
import 'package:moab_poc/page/mesh/view.dart';

void main() {
  runApp(const MoabApp());
}

class MoabApp extends StatelessWidget {
  const MoabApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: EntryPage.routeName,
      routes: {
        EntryPage.routeName: (context) => const EntryPage(),
        SetupPage1.routeName: (context) => const SetupPage1(),
        SetupPage2.routeName: (context) => const SetupPage2(),
        // LandingPage.routeName: (context) => const LandingPage(),
        // LoginPage.routeName: (context) => const LoginPage(),
        // DashboardPage.routeName: (context) => const DashboardPage(),
        // MeshPage.routeName: (context) => const MeshPage(),
      },
      theme: MoabTheme.mainLightModeData,
      darkTheme: MoabTheme.mainDarkModeData,
    );
  }
}
