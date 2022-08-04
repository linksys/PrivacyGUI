import 'dart:async';

import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/customs/network_check_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class ForgotEmailView extends StatefulWidget {
  const ForgotEmailView({Key? key}) : super(key: key);

  @override
  State<ForgotEmailView> createState() => _ForgotEmailViewState();
}

class _ForgotEmailViewState extends State<ForgotEmailView> {
  bool _isBehindRouter = false;


  @override
  void initState() {
    super.initState();
    // TODO check is behind router
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).forgot_email,
        ),
        content: _isBehindRouter
            ? _contentViewBehindRouter('{a***********ng@b*******m}')
            : NetworkCheckView(
                description:
                    getAppLocalizations(context).cloud_forgot_email_connect_to_your_router,
                button: PrimaryButton(
                  text: getAppLocalizations(context).am_connected,
                  onPress: () {
                    // TODO router API
                    setState(() {
                      _isBehindRouter = !_isBehindRouter;
                    });
                  },
                )),
      ),
    );
  }

  Widget _contentViewBehindRouter(String maskedMail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getAppLocalizations(context).cloud_forgot_email_router_connected_to,
          style: Theme.of(context)
              .textTheme
              .headline3
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(
          height: 32,
        ),
        Text(
          maskedMail,
          style: Theme.of(context)
              .textTheme
              .headline3
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }
}
