import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/route/model/model.dart';

class NoRouterView extends StatelessWidget {
  const NoRouterView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title:
              'It’s lonely in here... no Linksys routers are setup with this account',
        ),
        content: Column(
          children: [
            const SizedBox(
              height: 82,
            ),
            PrimaryButton(
              text: 'Setup WiFi',
              onPress: () {
                NavigationCubit.of(context).push(SetupWelcomeEulaPath());
              },
            ),
            const SizedBox(
              height: 26,
            ),
            SimpleTextButton(text: 'Log out', onPressed: () {
              // TODO
              NavigationCubit.of(context).clearAndPush(HomePath());
            }),
          ],
        ),
      ),
    );
  }
}
