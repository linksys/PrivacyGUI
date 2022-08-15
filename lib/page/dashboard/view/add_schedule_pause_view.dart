import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/dashboard/view/time_picker_view.dart';

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
          title: const Text('Add schedule', style: TextStyle(fontSize: 15)),
          leading: Transform.translate(
              offset: const Offset(-15, 0),
              child: BackButton(onPressed: () {})),
          actions: [
            TextButton(
                onPressed: () {},
                child: const Text('Save',
                    style:
                        TextStyle(fontSize: 13, color: MoabColor.primaryBlue))),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 22),
            const Text('Internet access will be paused on these days/times.',
                style: TextStyle(fontSize: 15, color: Colors.black)),
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
                            fontSize: 13, color: MoabColor.primaryBlue)))
              ])
            ] else ...[
              GestureDetector(
                  child: Image.asset('assets/images/add.png'),
                  onTap: () {
                    setState(() {
                      isCustomizeTime = true;
                    });
                  })
            ],
            const SizedBox(height: 63),
            TextButton(
                onPressed: () {},
                child: const Text('Delete',
                    style: TextStyle(fontSize: 15, color: Colors.red)),
                style: TextButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 0))),
            const SizedBox(height: 25),
            const Text('Router time: 5:05pm', style: TextStyle(fontSize: 14))
          ],
        ));
  }
}