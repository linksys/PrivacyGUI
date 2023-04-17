import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/button/simple_text_button.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/route/model/_model.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import '../../../bloc/auth/event.dart';

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
                  context.read<AuthBloc>().add(Logout());
                }),
          ],
        ),
      ),
    );
  }
}
