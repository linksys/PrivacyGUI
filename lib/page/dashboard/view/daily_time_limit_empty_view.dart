import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';

import '../../../design/colors.dart';
import '../../../route/navigation_cubit.dart';

class DailyTimeLimitEmptyView extends StatelessWidget {
  const DailyTimeLimitEmptyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget img = Image.asset('assets/images/alarm_clock.png');
    return BasePageView.onDashboardSecondary(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Daily time limit', style: TextStyle(fontSize: 15)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
          actions: [
            TextButton(
                onPressed: () {},
                child: const Text('Add',
                    style:
                        TextStyle(fontSize: 13, color: MoabColor.primaryBlue))),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            img,
            const SizedBox(height: 21),
            const Text('There are no time limits for Timmy yet'),
            const SizedBox(height: 39),
            PrimaryButton(text: 'Add', onPress: () {})
          ],
        ));
  }
}
