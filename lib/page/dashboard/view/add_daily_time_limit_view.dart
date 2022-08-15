import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/dashboard/view/number_picker_view.dart';
import 'package:linksys_moab/route/route.dart';

import '../../../design/colors.dart';
import '../../../route/model/dashboard_path.dart';
import 'day_picker_view.dart';

class AddDailyTimeLimitView extends StatefulWidget {
  const AddDailyTimeLimitView({Key? key}) : super(key: key);

  @override
  State<AddDailyTimeLimitView> createState() => _AddDailyTimeLimitViewState();
}

class _AddDailyTimeLimitViewState extends State<AddDailyTimeLimitView> {
  int hour = 0;
  int minutes = 0;

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Daily time limit', style: TextStyle(fontSize: 15)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
          actions: [
            TextButton(
                onPressed: () {
                  NavigationCubit.of(context).push(DailyTimeLimitListPath());
                },
                child: const Text('Save',
                    style:
                        TextStyle(fontSize: 13, color: MoabColor.primaryBlue))),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 33),
            const DayPickerView(),
            const SizedBox(height: 36),
            timePicker(hour, minutes, (value) {
              setState(() {
                hour = value;
              });
            }, (value) {
              setState(() {
                minutes = value;
              });
            }),
            const SizedBox(height: 66),
            TextButton(
                onPressed: () {},
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red, fontSize: 15)))
          ],
        ));
  }
}

typedef ValueChanged<T> = void Function(T value);

Widget timePicker(int hour, int minutes, ValueChanged onHourChanged,
    ValueChanged onMinutesChanged) {
  return Row(children: [
    NumberPickerView(
        title: 'Hours',
        value: hour,
        min: 0,
        max: 24,
        step: 1,
        callback: onHourChanged),
    const SizedBox(width: 22),
    NumberPickerView(
        title: 'Minutes',
        value: minutes,
        min: 0,
        max: 60,
        step: 15,
        callback: onMinutesChanged),
  ]);
}
