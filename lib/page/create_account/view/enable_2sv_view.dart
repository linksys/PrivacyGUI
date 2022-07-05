import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/route.dart';

class EnableTwoSVView extends StatelessWidget {
  const EnableTwoSVView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Enable two-step verification?',
        ),
        content: Text(
          'Authorize each log in with a confirmation code sent to your email or phone.\n\nWe recommend enabling this for maximum security.',
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(color: Theme.of(context).colorScheme.surface),
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: 'Yes',
              onPress: () {
                NavigationCubit.of(context).push(CreateAccountOtpPath()
                  ..args = {
                    'username': 'test@linksys.com',
                    'isSettingLoginType': true
                  });
              },
            ),
            SimpleTextButton(
                text: 'No, use password only',
                onPressed: () {
                  NavigationCubit.of(context).push(SaveCloudSettingsPath());
                }),
          ],
        ),
      ),
    );
  }
}
