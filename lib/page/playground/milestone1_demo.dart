import 'package:flutter/material.dart';
import 'package:moab_poc/design/themes.dart';
import 'package:moab_poc/page/create_account/view/view.dart';
import 'package:moab_poc/page/landing/view/view.dart';


void main() {
  runApp(const MoabApp());
}

class MoabApp extends StatelessWidget {
  const MoabApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        // LandingPage.routeName: (context) => const LandingPage(),
        // LoginPage.routeName: (context) => const LoginPage(),
        // DashboardPage.routeName: (context) => const DashboardPage(),
        // MeshPage.routeName: (context) => const MeshPage(),
        '/' : (context) => HomeView(),
        // GetWiFiUpView.routeName: (context) => GetWiFiUpView(onNext: () => _goToStartParentNode(context),),
        // StartParentNodeView.routeName: (context) => StartParentNodeView(onNext: () => _goToPlugNodeView(context),),
        // PlugNodeView.routeName: (context) => PlugNodeView(onNext: () => _goToConnectToModemView(context),),
        // ConnectToModemView.routeName: (context) => ConnectToModemView(onNext: () {}),
        // ShowMeHowView.routeName: (context) => const ShowMeHowView(),
      },
      theme: MoabTheme.setupModuleLightModeData,
      darkTheme: MoabTheme.setupModuleDarkModeData,
    );
  }

  // void _goToGetWifiUp(BuildContext context) {
  //   Navigator.pushNamed(context, GetWiFiUpView.routeName);
  // }
  //
  // void _goToStartParentNode(BuildContext context) {
  //   Navigator.pushNamed(context, StartParentNodeView.routeName);
  // }
  //
  // void _goToPlugNodeView(BuildContext context) {
  //   Navigator.pushNamed(context, PlugNodeView.routeName);
  // }
  //
  // void _goToConnectToModemView(BuildContext context) {
  //   Navigator.pushNamed(context, ConnectToModemView.routeName);
  // }
}
