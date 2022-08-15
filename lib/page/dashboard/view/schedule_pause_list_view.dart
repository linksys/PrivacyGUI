import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

import '../../../design/colors.dart';
import '../../../route/navigation_cubit.dart';

List<SchedulePause> list = [
  SchedulePause('M, T, W, Th, F', '10pm - 8am next day', true),
  SchedulePause('M, W, Th, F', 'All day', true)
];

class SchedulePauseListView extends StatelessWidget {
  const SchedulePauseListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scheduled pauses', style: TextStyle(fontSize: 15)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
        actions: [
          TextButton(
              onPressed: () {},
              child: const Text('Add schedule',
                  style:
                      TextStyle(fontSize: 13, color: MoabColor.primaryBlue))),
        ],
      ),
      child: Column(children: [
        for (SchedulePause item in list) ...[
          ScheduledPauseItem(
              item: item,
              onStatusChanged: (value) {
                item.status = value;
              },
              onPress: () {}),
          const SizedBox(height: 8)
        ]
      ]),
    );
  }
}

typedef ValueChanged<T> = void Function(T value);

class ScheduledPauseItem extends StatefulWidget {
  ScheduledPauseItem(
      {Key? key,
      required this.item,
      required this.onStatusChanged,
      required this.onPress})
      : super(key: key);
  SchedulePause item;
  ValueChanged onStatusChanged;
  VoidCallback onPress;

  @override
  State<ScheduledPauseItem> createState() => _schedulePauseItemState();
}

class _schedulePauseItemState extends State<ScheduledPauseItem> {
  bool isOn = false;

  @override
  void initState() {
    super.initState();
    isOn = widget.item.status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey,
        child: Column(
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
                      Text(widget.item.duration,
                          style: TextStyle(fontSize: 15)),
                      Image.asset('assets/images/right_compact_wire.png')
                    ]),
                onTap: () => widget.onPress)
          ],
        ));
  }
}

class SchedulePause {
  SchedulePause(this.days, this.duration, this.status);

  String days;
  String duration;
  bool status;
}
