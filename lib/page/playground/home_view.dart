import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/negative_button.dart';
import 'package:moab_poc/page/components/base_components/button/positive_button.dart';
import 'package:moab_poc/page/components/layouts/base_layout.dart';
import 'package:moab_poc/page/playground/welcome_view.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BaseLayout(
        content: const Icon(
          Icons.lock,
          size: 200,
        ),//TODO: Add logo,
        footer: _footer(context),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Column(
      children: [
        const PositiveButton(text: 'Log in',),
        const SizedBox(height: 24,),
        NegativeButton(text: 'Set up new WiFi', onPress: () => _goToSetUpWifi(context),),
      ],
    );
  }

  void _goToSetUpWifi(BuildContext context) {
    Navigator.pushNamed(context, WelcomeView.routeName);
  }
}