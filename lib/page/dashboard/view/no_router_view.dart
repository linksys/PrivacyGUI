import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/auth/auth_provider.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/button/simple_text_button.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';



class NoRouterView extends ConsumerWidget {
  const NoRouterView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePageView(
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).no_router_title,
        ),
        content: Column(
          children: [
            const SizedBox(
              height: 82,
            ),
            PrimaryButton(
              text: getAppLocalizations(context).setup_wifi,
              onPress: () {
                // ref
                //     .read(navigationsProvider.notifier)
                //     .push(SetupWelcomeEulaPath());
              },
            ),
            const SizedBox(
              height: 26,
            ),
            SimpleTextButton(
                text: getAppLocalizations(context).logout,
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                }),
          ],
        ),
      ),
    );
  }
}
