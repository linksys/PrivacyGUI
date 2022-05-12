import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class PlaceNodeTipView extends StatelessWidget {
  PlaceNodeTipView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  static const routeName = '/place_node_tip';
  final void Function() onNext;

  //TODO: This svg file does not work
  final Widget image = SvgPicture.asset(
    'assets/images/place_node_tip.svg',
    semanticsLabel: 'Place node tip',
  );

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        content: Column(
          children: [
            Text(
              'TIP',
              style: Theme.of(context).textTheme.headline4?.copyWith(
                color: const Color.fromRGBO(255, 255, 255, 0.3)
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 67),
              child: Text(
                'Place nodes 1 to 2 rooms apart, with no more than 1 floor between them',
                style: Theme.of(context).textTheme.headline2?.copyWith(
                  color: Theme.of(context).colorScheme.primary
                ),
              ),
            ),
            image,
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        footer: PrimaryButton(
          text: 'Next',
          onPress: onNext,
        ),
      ),
    );
  }
}