import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../components/base_components/button/primary_button.dart';

class PlugNodeView extends StatelessWidget {
  PlugNodeView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final VoidCallback onNext;

  static const routeName = '/plug_node';

  //TODO: This svg file does not work
  // final Widget image = SvgPicture.asset(
  //   'assets/images/plug_node.svg',
  // );

  // Remove this if the upper svg image is fixed
  final Widget image = Image.asset('assets/images/plug_node.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Plug the parent node into a power source',
        ),
        content: _content(),
        footer: PrimaryButton(
          text: 'Next',
          onPress: onNext,
        ),
      ),
    );
  }

  Widget _content() {
    return Stack(
      children: [
        Container(
          alignment: Alignment.bottomRight,
          child: image,
        ),
        Column(
          children: [
            const Spacer(),
            // TODO: Add on press method
            SimpleTextButton(text: 'What is a parent node?', onPressed: () {}),
            const SizedBox(
              height: 79,
            ),
          ],
        ),
      ],
    );
  }
}
