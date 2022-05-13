import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class AddChildFinishedView extends StatelessWidget {
  AddChildFinishedView({
    Key? key,
    required this.onAddMore,
    required this.onAddDone,
  }) : super(key: key);

  final void Function() onAddMore;
  final void Function() onAddDone;

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
              onPress: onAddDone,
            ),
            const SizedBox(
              height: 20,
            ),
            SecondaryButton(
              text: 'No, I’m done',
              onPress: onAddDone,
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}