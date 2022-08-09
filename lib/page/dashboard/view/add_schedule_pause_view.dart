import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';

class AddSchedulePauseView extends StatefulWidget {
  const AddSchedulePauseView({Key? key}) : super(key: key);

  @override
  State<AddSchedulePauseView> createState() => _AddSchedulePauseViewState();
}

class _AddSchedulePauseViewState extends State<AddSchedulePauseView> {
  bool isCustomizeTime = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        const Text('Internet access will be paused on these days/times.',
            style: TextStyle(fontSize: 15)),
        const SizedBox(height: 8),
        dayPicker(),
        const SizedBox(height: 49),
        if (isCustomizeTime) ...[
          Row(children: [
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Start'),
                  const SizedBox(height: 11),
                  TextButton(
                      onPressed: () {},
                      child: const Text('10:00 pm'),
                      style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 0))),
                  const SizedBox(height: 6),
                  Image.asset('assets/images/line.png'),
                  const SizedBox(height: 6),
                  Visibility(child: const Text('next day', style: TextStyle(fontSize: 13)), visible: false, maintainSize: true, maintainAnimation: true, maintainState: true,)
                ]),
            const SizedBox(width: 22),
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('End'),
                  const SizedBox(height: 11),
                  TextButton(
                      onPressed: () {},
                      child: const Text('8:00 am'),
                      style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 0))),
                  const SizedBox(height: 6),
                  Image.asset('assets/images/line.png'),
                  const SizedBox(height: 6),
                  const Text('next day', style: TextStyle(fontSize: 13))
                ]),
            const SizedBox(width: 57),
            TextButton(
                onPressed: () {},
                child: const Text('Remove',
                    style:
                        TextStyle(fontSize: 13, color: MoabColor.primaryBlue)))
          ])
        ] else ...[
          Image.asset('assets/images/add.png')
        ],
        const SizedBox(height: 114),
        const Text('Router time: 5:05pm', style: TextStyle(fontSize: 14))
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
