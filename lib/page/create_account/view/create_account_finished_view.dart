import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';


class CreateAccountFinishedView extends StatelessWidget {
  CreateAccountFinishedView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  static const routeName = '/create_account_finished';
  final void Function() onNext;

  //TODO: This svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Create account introduction',
  );

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Account created!',
        ),
        content: Center(
          child: image,
        ),
        footer: PrimaryButton(
          text: 'Next',
          onPress: onNext,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}