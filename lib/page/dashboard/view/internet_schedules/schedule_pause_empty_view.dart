import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class SchedulePauseEmptyView extends ConsumerWidget {
  const SchedulePauseEmptyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppGap.extraBig(),
        Image.asset('assets/images/schedule_pause_empty.png'),
        const AppGap.semiBig(),
        const AppText.descriptionMain(
          'There are no schedules for Timmy yet',
        ),
        const AppGap.extraBig(),
        AppPrimaryButton(
          'Add a schedule',
          onTap: () {},
        ),
      ],
    );
  }
}
