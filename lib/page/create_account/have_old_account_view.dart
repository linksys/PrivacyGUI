import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

import '../../route/moab_router.dart';

class HaveOldAccountView extends StatelessWidget {
  const HaveOldAccountView({Key? key}) : super(key: key);

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
      ),
    );
  }
}
