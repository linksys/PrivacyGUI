import 'package:flutter/cupertino.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/setup/view/show_me_how_view.dart';

import '../../components/base_components/button/primary_button.dart';
import '../../components/base_components/button/simple_text_button.dart';

class ConnectToModemView extends StatelessWidget {
  ConnectToModemView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final VoidCallback onNext;

  static const routeName = '/connect_to_modem';

  //TODO: This svg file does not work
  // final Widget image = SvgPicture.asset(
  //   'assets/images/connect_to_modem.svg',
  // );

  // Remove this if the upper svg image is fixed
  final Widget image = Image.asset('assets/images/connect_to_modem.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Connect node to modem',
          description:
              'Use the ethernet cable to connect the parent node to your modem or source of internet',
        ),
        content: _content(context),
        footer: PrimaryButton(
          text: 'Next',
          onPress: onNext,
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        image,
        const SizedBox(
          height: 104,
        ),
        SimpleTextButton(
          text: 'Show me how',
          onPressed: () => _goToShowMeHowPage(context),
        ),
      ],
    );
  }

  void _goToShowMeHowPage(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return const ShowMeHowView();
        });
  }
}
