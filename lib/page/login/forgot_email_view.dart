import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../../route/moab_router.dart';

class ForgotEmailView extends StatelessWidget {
  const ForgotEmailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => MoabRouter.pop(context),
          )
        ],
      ),
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Forgot email',
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No problem, we’ll give you a hint. But first, connect to your router’s WiFi',
              style: Theme.of(context)
                  .textTheme
                  .headline3
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(
              height: 8,
            ),
            Image.asset('assets/images/icon_wifi.png'),
            const SizedBox(
              height: 12,
            ),
            Text(
              '{MyHomeWifi}',
              style: Theme.of(context)
                  .textTheme
                  .headline3
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(
              height: 43,
            ),
            PrimaryButton(
              text: 'I’m connected',
              onPress: () {},
            ),
          ],
        ),
      ),
    );
  }
}
