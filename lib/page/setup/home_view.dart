import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class HomeView extends StatelessWidget {
  HomeView({
    Key? key,
    required this.onLogin,
    required this.onSetup,
  }) : super(key: key);

  final VoidCallback onLogin;
  final VoidCallback onSetup;

  final Widget logoImage = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Linksys Logo',
    height: 180,
  );

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        content: _content(context),
        footer: _footer(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Container(
      alignment: Alignment.topRight,
      child: logoImage,
    );
  }

  Widget _footer(BuildContext context) {
    return Column(
      children: [
        PrimaryButton(
          text: 'Log in',
          onPress: onLogin,
        ),
        const SizedBox(
          height: 24,
        ),
        SecondaryButton(
          text: 'Set up new WiFi',
          onPress: onSetup,
        ),
      ],
    );
  }
}