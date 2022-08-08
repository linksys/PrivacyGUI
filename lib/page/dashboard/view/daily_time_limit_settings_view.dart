import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

class DailyTimeLimitSettingsView extends StatefulWidget {
  const DailyTimeLimitSettingsView({Key? key}) : super(key: key);

  @override
  State<DailyTimeLimitSettingsView> createState() =>
      _DailyTimeLimitSettingsViewState();
}

class _DailyTimeLimitSettingsViewState
    extends State<DailyTimeLimitSettingsView> {
  final TextEditingController hourController = TextEditingController();
  final TextEditingController minController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 33),
        dayPicker(),
        const SizedBox(height: 36),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Hours'),
            const SizedBox(height: 11),
            TextButton(
                onPressed: () {},
                child: const Text('2'),
                style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 0))),
            const SizedBox(height: 6),
            Image.asset('assets/images/line.png')
          ]),
          const SizedBox(width: 22),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Minutes'),
            const SizedBox(height: 11),
            TextButton(
                onPressed: () {},
                child: const Text('00'),
                style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 0))),
            const SizedBox(height: 6),
            Image.asset('assets/images/line.png')
          ])
        ]),
        const SizedBox(height: 66),
        TextButton(
            onPressed: () {},
            child: const Text('Delete',
                style: TextStyle(color: Colors.red, fontSize: 15)))
      ],
    );
  }
}

Widget dayPicker() {
  List<String> days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
  return Row(children: [
    for (var item in days)
      Container(
          width: 40,
          height: 44,
          margin: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 0.5)),
          child: Center(child: Text(item)))
  ]);
}
