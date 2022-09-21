import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/button/secondary_button.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/route/model/_model.dart';

class AddChildFinishedView extends StatelessWidget {
  AddChildFinishedView({
    Key? key,
  }) : super(key: key);

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Do you want to set up another node?',
        ),
        content: Center(
          child: image,
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: 'Yes, let’s do it',
              onPress: () => NavigationCubit.of(context).push(SetupNthChildQrCodePath()),
            ),
            const SizedBox(
              height: 20,
            ),
            SecondaryButton(
              text: 'No, I’m done',
              onPress: () => NavigationCubit.of(context).push(SetupNodesDonePath()),
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}