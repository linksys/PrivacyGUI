import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../localization/localization_hook.dart';

class InternetScheduleView extends StatefulWidget {
  const InternetScheduleView({Key? key}) : super(key: key);

  @override
  State<InternetScheduleView> createState() => _InternetScheduleViewState();
}

class _InternetScheduleViewState extends State<InternetScheduleView> {
  final Widget firstAvatar = Image.asset('assets/images/sparker.png');
  final Widget secondAvatar = Image.asset('assets/images/hat.png');
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Text(getAppLocalizations(context).internet_schedule_view_description),
        const SizedBox(height: 24),
        scheduleCard(firstAvatar, const Text('Timmy')),
        const SizedBox(height: 8),
        scheduleCard(secondAvatar, const Text('Mandy'))
      ],
    );
  }
}

Widget scheduleCard(Widget image, Widget text) {
  return Container(
    height: 82,
    decoration: BoxDecoration(border: Border.all(color: Colors.black)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 16),
        image,
        const SizedBox(width: 21),
        Expanded(child: text),
        const SizedBox(width: 8),
        const Text("OFF"),
        const SizedBox(width: 6),
        Image.asset('assets/images/right_compact_wire.png'),
        const SizedBox(width: 12),
      ],
    ),
  );
}