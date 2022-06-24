import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/route.dart';

import '../../components/base_components/button/primary_button.dart';

class PlaceNodeView extends StatelessWidget {
  PlaceNodeView({
    Key? key,
  }) : super(key: key);

  // Replace this to svg if the svg image is fixed
  final Widget image = Image.asset('assets/images/place_node.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: _header(context),
        content: image,
        footer: PrimaryButton(
          text: 'Got it',
          onPress: () => NavigationCubit.of(context).push(SetupParentPermissionPath()),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIP',
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(color: const Color.fromRGBO(255, 255, 255, 0.3)),
        ),
        const SizedBox(
          height: 6,
        ),
        Text(
          'Place nodes out in the open, not inside or behind furniture, and away from large appliances',
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }
}
