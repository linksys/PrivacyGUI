import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../components/base_components/button/primary_button.dart';

class PlugNodeView extends StatelessWidget {
  PlugNodeView({Key? key}) : super(key: key);

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
      child: _plugNodeView(context),
    );
  }

  void _goToNextPage(BuildContext context) {
    //TODO: Go to next page
  }

  Widget _plugNodeView(BuildContext context) {
    return Column(
      children: [
        const BasicHeader(title: 'Plug node into a power source',),
        // const SizedBox(height: 78,),
        Container(
          alignment: Alignment.topRight,
          child: image,
        ),
        PrimaryButton(
          text: 'Next',
          onPress: () => _goToNextPage(context),
        ),
      ],
    );
  }

}