import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

class SchedulePauseEmptyView extends ConsumerWidget {
  const SchedulePauseEmptyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 114),
        Image.asset('assets/images/schedule_pause_empty.png'),
        const SizedBox(height: 23),
        const Text('There are no schedules for Timmy yet',
            style: TextStyle(fontSize: 15)),
        const SizedBox(height: 75),
        PrimaryButton(text: 'Add a schedule', onPress: () {})
      ],
    );
  }
}
