import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';

import '../../../design/colors.dart';
import '../../../route/model/dashboard_path.dart';
import '../../../route/navigation_cubit.dart';

class DailyTimeLimitListView extends StatelessWidget {
  const DailyTimeLimitListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return timeListItem(context);
  }
}

List<TimeLimit> list = [
  TimeLimit('M, T, W, Th, F', '2hr,00 min', true),
  TimeLimit('M, W, Th, F', '2hr,30 min', false)
];

Widget timeListItem(BuildContext context) {
  return BasePageView.onDashboardSecondary(
    padding: EdgeInsets.zero,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Daily time limit', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
        actions: [
          TextButton(
              onPressed: () {
                NavigationCubit.of(context).popTo(AddDailyTimeLimitPath());
              },
              child: const Text('Add',
                  style:
                      TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: MoabColor.textButtonBlue))),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 19),
          for (TimeLimit item in list) ...[
            DailyTimeLimitItem(
                item: item,
                onStatusChanged: (value) {
                  item.status = value;
                },
                onPress: () {
                  NavigationCubit.of(context).popTo(AddDailyTimeLimitPath());
                }),
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
      required this.onPress,
      })
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
    return Container(
        padding: const EdgeInsets.all(16),
        color: const Color.fromRGBO(217, 217, 217, 1.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.item.days,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black)),
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
                          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Color.fromRGBO(0, 0, 0, 0.5))),
                      Image.asset('assets/images/right_compact_wire.png')
                    ]),
                onTap: () { widget.onPress();})
          ],
        ));
  }
}

class TimeLimit {
  TimeLimit(this.days, this.duration, this.status);

  String days;
  String duration;
  bool status;
}
