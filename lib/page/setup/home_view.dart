import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/setup/get_wifi_up_view.dart';

class HomeView extends StatelessWidget {
  HomeView({Key? key}) : super(key: key);

  // static const routeName = '/home';

  final Widget logoImage = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Linksys Logo',
    height: 180,
  );

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        content: logoImage,
        footer: _footer(context),
        alignment: CrossAxisAlignment.end,
      ),
    );
  }

  Widget _footer(BuildContext context) {
    return Column(
      children: [
        const PrimaryButton(text: 'Log in',),
        const SizedBox(height: 24,),
        SecondaryButton(text: 'Set up new WiFi', onPress: () => _goToSetUpWifi(context),),
      ],
    );
  }

  void _goToSetUpWifi(BuildContext context) {
    Navigator.pushNamed(context, GetWiFiUpView.routeName);
  }
}