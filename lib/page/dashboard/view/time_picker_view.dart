import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TimePickerView extends StatefulWidget {
  TimePickerView(
      {Key? key, required this.title, required this.current, required this.isNextDay})
      : super(key: key);

  String title;
  Time current;
  bool isNextDay = false;

  @override
  State<TimePickerView> createState() => _TimePickerViewState();
}

class _TimePickerViewState extends State<TimePickerView> {
  late TimeOfDay androidSelectedTime;
  late DateTime iosSelectTime;

  _androidSelectTime(BuildContext context) async {
    final TimeOfDay? timeOfDay = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: androidSelectedTime.hour, minute: androidSelectedTime.minute),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data:
            MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child ?? Container(),
          );
        });
    if (timeOfDay != null && timeOfDay != androidSelectedTime) {
      setState(() {
        androidSelectedTime = timeOfDay;
      });
    }
  }

  void _iosSelectTime(BuildContext context) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) =>
            Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              margin: EdgeInsets.only(
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: CupertinoDatePicker(
                  initialDateTime: iosSelectTime,
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() => iosSelectTime = newTime);
                  },
                ),
              ),
            ));
  }

  String getTimeString() {
    if (Platform.isAndroid) {
      return '${androidSelectedTime.hour}:${androidSelectedTime.minute <= 0 ? '0${androidSelectedTime.minute}' : androidSelectedTime.minute}';
    } else if( Platform.isIOS) {
      return '${iosSelectTime.hour} : ${iosSelectTime.minute <= 10 ? '0${iosSelectTime.minute}' : iosSelectTime.minute}';
    } else {
      return '';
    }
  }


  @override
  void initState() {
    super.initState();
    androidSelectedTime =
        TimeOfDay(hour: widget.current.hour, minute: widget.current.minutes);
    iosSelectTime =
        DateTime(2022, 8, 12, widget.current.hour, widget.current.minutes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.title,
              style: const TextStyle(fontSize: 15, color: Color.fromRGBO(0, 0, 0, 0.4))),
          const SizedBox(height: 11),
          TextButton(
              onPressed: () {
                if (Platform.isAndroid) {
                  _androidSelectTime(context);
                } else if (Platform.isIOS) {
                  _iosSelectTime(context);
                }
              },
              child: Text(getTimeString(), style: const TextStyle(color: Colors.black, fontSize: 25, fontWeight: FontWeight.w500)),
              style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 0))),
          const SizedBox(height: 6),
          Image.asset('assets/images/line.png'),
          const SizedBox(height: 6),
          Visibility(
            child: const Text(
                'next day', style: TextStyle(fontSize: 13, color: Colors.grey)),
            visible: widget.isNextDay,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
          )
        ]);
  }
}

class Time {
  int hour;
  int minutes;

  Time({required this.hour, required this.minutes});
}
