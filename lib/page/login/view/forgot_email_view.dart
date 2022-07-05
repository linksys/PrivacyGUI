import 'dart:async';

import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/customs/network_check_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/route/navigation_cubit.dart';

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
        header: const BasicHeader(
          title: 'Forgot email',
        ),
        content: _isBehindRouter
            ? _contentViewBehindRouter('{a***********ng@b*******m}')
            : NetworkCheckView(
                description:
                    'No problem, we’ll give you a hint. But first, connect to your router’s WiFi',
                button: PrimaryButton(
                  text: 'I’m connected',
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
          'The router you\'re connected to is associate with',
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
