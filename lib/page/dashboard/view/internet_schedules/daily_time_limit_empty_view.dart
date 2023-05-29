import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class DailyTimeLimitEmptyView extends ConsumerWidget {
  const DailyTimeLimitEmptyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget img = Image.asset('assets/images/alarm_clock.png');
    return StyledAppPageView(
        title: 'Daily time limit',
        actions: [
          AppTertiaryButton(
            'Add',
            onTap: () {},
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            img,
            const AppGap.semiBig(),
            const AppText.descriptionMain(
                'There are no time limits for Timmy yet'),
            const AppGap.big(),
            AppPrimaryButton(
              'Add',
              onTap: () {},
            ),
          ],
        ));
  }
}
