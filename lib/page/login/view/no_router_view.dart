import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class NoRouterView extends StatelessWidget {
  const NoRouterView({Key? key, required this.onNext, required this.onLogout})
      : super(key: key);

  final void Function() onNext;
  final void Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(title: 'It’s lonely in here... no Linksys routers are setup with this account',),
        content: Column(
          children: [
            const SizedBox(height: 82,),
            PrimaryButton(text: 'Setup WiFi', onPress: onNext,),
            const SizedBox(height: 26,),
            SimpleTextButton(text: 'Log out', onPressed: onLogout),
          ],
        ),
      ),
    );
  }
}
