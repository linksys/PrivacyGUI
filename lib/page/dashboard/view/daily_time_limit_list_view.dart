import 'package:flutter/material.dart';

class DailyTimeLimitListView extends StatelessWidget {
  const DailyTimeLimitListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return timeListItem();
  }
}

Widget timeListItem() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('M,T,W,Th,F', style: TextStyle(fontSize: 15)),
        Switch(value: true, onChanged: (value) => value)
      ]),
      const SizedBox(height: 45),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('2hr, 00 min', style: TextStyle(fontSize: 25)),
        Image.asset('assets/images/right_compact_wire.png')
      ])
    ],
  );
}
