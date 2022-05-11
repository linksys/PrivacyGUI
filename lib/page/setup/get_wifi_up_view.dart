import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/base_components/text/title_text.dart';
import 'package:moab_poc/page/setup/start_parent_node_view.dart';

class GetWiFiUpView extends StatelessWidget {
  GetWiFiUpView({Key? key}) : super(key: key);

  static const routeName = '/get_wifi_up';

  //TODO: This svg file does not work
  // final Widget image = SvgPicture.asset(
  //   'assets/images/get_wifi_up_image.svg',
  //   semanticsLabel: 'Get Wifi Up',
  // );

  // Remove this if the upper svg image is fixed
  final Widget image = Image.asset('assets/images/get_wifi_up_image.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(title: 'Let’s get your WiFi up and running',),
        content: _content(context),
        footer: PrimaryButton(
          text: 'I’m ready',
          onPress: () => _goToNextPage(context),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 38,),
        image,
        const SizedBox(height: 39,),
        const DescriptionText(
          // TODO: Use rich text here
            text: 'First things first, by continuing with setup, you agree to our Terms and License Agreement. Take a few minutes to read them.'
        ),
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  void _goToNextPage(BuildContext context) {
    Navigator.pushNamed(context, StartParentNodeView.routeName);
  }
}