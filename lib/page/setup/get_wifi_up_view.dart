import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/positive_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/base_components/text/title_text.dart';

class GetWiFiUpView extends StatelessWidget {
  GetWiFiUpView({Key? key}) : super(key: key);

  static const routeName = '/get_wifi_up';

  final Widget image = SvgPicture.asset(
    'assets/images/get_wifi_up_image.svg',  //TODO: This svg file does not work
    semanticsLabel: 'Get Wifi Up',
  );

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        content: Column(
          children: [
            const TitleText(text: 'Let’s get your WiFi up and running'),
            image,
            const DescriptionText(
              text: 'First things first, by continuing with setup, you agree to our Terms and License Agreement. Take a few minutes to read them.'
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        footer: PositiveButton(
          text: 'I’m ready',
          onPress: () => _goToNext(context),
        ),
      ),
    );
  }

  void _goToNext(BuildContext context) {
    //TODO: Go to StartParentNode page
  }
}