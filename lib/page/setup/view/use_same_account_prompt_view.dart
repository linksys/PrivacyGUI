import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class UseSameAccountPromptView extends StatelessWidget {
  const UseSameAccountPromptView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(context,
      child: BasicLayout(
        content: Column(
          children: [
            Image.asset('assets/images/icon_shining.png'),
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 30),
              child: Text(
                'We built a new app to provide major upgrades.\n\nCreate a new Linksys account to use this app.',
                style: Theme.of(context)
                    .textTheme
                    .headline1
                    ?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            Text(
              'You can use the same email and password as your previous account.',
              style: Theme.of(context)
                  .textTheme
                  .headline4
                  ?.copyWith(color: Theme.of(context).colorScheme.surface),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}
