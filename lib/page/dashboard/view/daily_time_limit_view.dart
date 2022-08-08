import 'package:flutter/cupertino.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';

class DailyTimeLimitView extends StatelessWidget {
  const DailyTimeLimitView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget img = Image.asset('assets/images/alarm_clock.png');
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        img,
        const SizedBox(height: 21),
        const Text('There are no time limits for Timmy yet'),
        const SizedBox(height: 39),
        PrimaryButton(text: 'Add', onPress: () {})
      ],
    );
  }
}
