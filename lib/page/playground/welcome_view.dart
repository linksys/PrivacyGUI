import 'package:flutter/cupertino.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/positive_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/base_components/text/title_text.dart';
import 'package:moab_poc/page/components/layouts/base_layout.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({Key? key}) : super(key: key);

  static const routeName = '/welcome';

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BaseLayout(
        header: const TitleText(text: 'Let’s get your WiFi up and running'),
        content: _contentView(context),
        footer: const PositiveButton(text: 'I’m ready',),
      ),
    );
  }

  Widget _contentView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 38),
      child: Column(
        children: const [
          // TODO: Add image,
          DescriptionText(text: 'First things first, by continuing with setup, you agree to our Terms and License Agreement. Take a few minutes to read them.')
        ],
      ),
    );
  }
}