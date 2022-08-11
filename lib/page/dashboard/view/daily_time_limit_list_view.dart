import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';

import '../../../design/colors.dart';

class DailyTimeLimitListView extends StatelessWidget {
  const DailyTimeLimitListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return timeListItem();
  }
}

List<TimeLimit> list = [
  TimeLimit('M, T, W, Th, F', '2hr,00 min', true),
  TimeLimit('M, W, Th, F', '2hr,30 min', false)
];

Widget timeListItem() {
  return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Daily time limit', style: TextStyle(fontSize: 15)),
        leading: Transform.translate(
            offset: const Offset(-15, 0), child: BackButton(onPressed: () {})),
        actions: [
          TextButton(
              onPressed: () {},
              child: const Text('Add',
                  style:
                      TextStyle(fontSize: 13, color: MoabColor.primaryBlue))),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (TimeLimit item in list) ...[
            DailyTimeLimitItem(
                item: item,
                onStatusChanged: (value) {
                  item.status = value;
                },
                onPress: () {}),
            const SizedBox(height: 8)
          ]
        ],
      ));
}

typedef ValueChanged<T> = void Function(T value);

class DailyTimeLimitItem extends StatefulWidget {
  DailyTimeLimitItem(
      {Key? key,
      required this.item,
      required this.onStatusChanged,
      required this.onPress})
      : super(key: key);
  TimeLimit item;
  ValueChanged onStatusChanged;
  VoidCallback onPress;

  @override
  State<DailyTimeLimitItem> createState() => _dailyTimeLimitItemState();
}

class _dailyTimeLimitItemState extends State<DailyTimeLimitItem> {
  bool isOn = false;

  @override
  void initState() {
    super.initState();
    isOn = widget.item.status;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.item.days,
              style: const TextStyle(fontSize: 15, color: Colors.black)),
          Switch.adaptive(
              value: widget.item.status,
              onChanged: (value) {
                setState(() {
                  isOn = value;
                });
                widget.onStatusChanged(value);
              })
        ]),
        const SizedBox(height: 25),
        GestureDetector(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.item.duration, style: TextStyle(fontSize: 25)),
                  Image.asset('assets/images/right_compact_wire.png')
                ]),
            onTap: () => widget.onPress)
      ],
    );
  }
}

class TimeLimit {
  TimeLimit(this.days, this.duration, this.status);

  String days;
  String duration;
  bool status;
}
