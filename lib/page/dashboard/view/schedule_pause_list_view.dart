import 'package:flutter/material.dart';

class SchedulePauseListView extends StatelessWidget {
  const SchedulePauseListView({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        pauseListItem()
      ],
    );
  }
}

Widget pauseListItem() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('M,T,W,Th,F', style: TextStyle(fontSize: 15)),
        Switch.adaptive(value: true, onChanged: (value) => value)
      ]),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [
        Text('10 pm - 8 am next day', style: TextStyle(fontSize: 13)),
      ])
    ],
  );
}