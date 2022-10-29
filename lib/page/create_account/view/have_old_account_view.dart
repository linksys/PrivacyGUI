import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class HaveOldAccountView extends StatelessWidget {
  const HaveOldAccountView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/images/icon_shining.png'),
            Text(
              'We built a new app to provide major upgrades.\n\nCreate a new Linksys account to use this app.',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(
              height: 31,
            ),
            Text(
              'You can use the same email and password as your previous account.',
              style: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Theme.of(context).colorScheme.surface),
            ),
          ],
        ),
        footer: Column(children: [
          PrimaryButton(text: 'Set up new WiFi', onPress: () {
            NavigationCubit.of(context).push(SetupWelcomeEulaPath());
          },),
        ],),
      ),
    );
  }
}
