import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/dashboard/view/time_picker_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

import 'day_picker_view.dart';

class AddSchedulePauseView extends StatefulWidget {
  const AddSchedulePauseView({Key? key}) : super(key: key);

  @override
  State<AddSchedulePauseView> createState() => _AddSchedulePauseViewState();
}

class _AddSchedulePauseViewState extends State<AddSchedulePauseView> {
  bool isCustomizeTime = false;

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Add schedule',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
          actions: [
            TextButton(
                onPressed: () {
                  NavigationCubit.of(context).push(SchedulePauseListPath());
                },
                child: const Text('Save',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MoabColor.textButtonBlue))),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            const Text('Internet access will be paused on these days/times.',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
            const SizedBox(height: 8),
            const DayPickerView(),
            const SizedBox(height: 49),
            if (isCustomizeTime) ...[
              Row(children: [
                TimePickerView(
                    title: 'start',
                    current: Time(hour: 10, minutes: 0),
                    isNextDay: false),
                const SizedBox(width: 22),
                TimePickerView(
                    title: 'end',
                    current: Time(hour: 8, minutes: 0),
                    isNextDay: true),
                const SizedBox(width: 57),
                TextButton(
                    onPressed: () {
                      setState(() {
                        isCustomizeTime = false;
                      });
                    },
                    child: const Text('Remove',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: MoabColor.textButtonBlue)))
              ])
            ] else ...[
              GestureDetector(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start and end time',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 19),
                      Image.asset('assets/images/add.png'),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      isCustomizeTime = true;
                    });
                  })
            ],
            const SizedBox(height: 63),
            TextButton(
                onPressed: () {
                  NavigationCubit.of(context).pop();
                },
                child: const Text('Delete',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color.fromRGBO(207, 26, 26, 1.0))),
                style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 0))),
            const SizedBox(height: 25),
            const Text('Router time: 5:05pm',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color.fromRGBO(0, 0, 0, 0.5)))
          ],
        ));
  }
}