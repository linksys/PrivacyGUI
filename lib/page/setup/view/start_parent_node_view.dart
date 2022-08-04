import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/setup/view/plug_node_view.dart';

import '../../components/base_components/text/description_text.dart';

// TODO nobody use this
class StartParentNodeView extends StatelessWidget {
  StartParentNodeView({
    Key? key,
  }) : super(key: key);

  //TODO: This svg file does not work
  // final Widget image = SvgPicture.asset(
  //   'assets/images/start_parent_node.svg',
  // );

  // Remove this if the upper svg image is fixed
  final Widget image = Image.asset('assets/images/start_parent_node.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Start with the parent node',
          description:
              'If your bundle came with multiple nodes, grab the parent node. ',
        ),
        content: _content(context),
        footer: PrimaryButton(
          text: 'I have the parent node',
          onPress: () {},
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 29,
        ),
        image,
        const SizedBox(
          height: 45,
        ),
        const DescriptionText(
          // TODO: Use rich text here
          text:
              'The parent is your main router and connects to the internet. Child nodes are satellites, expanding WiFi coverage throughout your home. How to tell them apart',
        ),
      ],
    );
  }
}
