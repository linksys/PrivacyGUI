import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

import '../../../design/colors.dart';
import '../../../route/model/dashboard_path.dart';
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
      padding: EdgeInsets.zero,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Scheduled pauses',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
        actions: [
          TextButton(
              onPressed: () {
                NavigationCubit.of(context).popTo(AddSchedulePausePath());
              },
              child: const Text('Add schedule',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: MoabColor.textButtonBlue))),
        ],
      ),
      child: Column(children: [
        for (SchedulePause item in list) ...[
          ScheduledPauseItem(
              item: item,
              onStatusChanged: (value) {
                item.status = value;
              },
              onPress: () {
                NavigationCubit.of(context).popTo(AddSchedulePausePath());
              }),
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
        color: const Color.fromRGBO(217, 217, 217, 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.item.days,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black)),
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
            InkWell(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.item.duration,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color.fromRGBO(102, 102, 102, 1.0))),
                      Image.asset('assets/images/right_compact_wire.png')
                    ]),
                onTap: () {
                  widget.onPress();
                })
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
