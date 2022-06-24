import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

// TODO nobody use this
class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Reset password',
          description: 'We’ll email you a link to reset your password.',
          spacing: 18,
        ),
        content: Column(
          children: [
            const SizedBox(height: 40,),
            PrimaryButton(
              text: 'Send code',
              onPress: () {},
            )
          ],
        ),
      ),
    );
  }
}
