import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class TimePickerView extends ConsumerStatefulWidget {
  const TimePickerView({
    Key? key,
    required this.title,
    required this.current,
    this.isNextDay = false,
    this.onChanged,
  }) : super(key: key);

  final String title;
  final Duration current;
  final bool isNextDay;
  final Function(Duration)? onChanged;

  @override
  ConsumerState<TimePickerView> createState() => _TimePickerViewState();
}

class _TimePickerViewState extends ConsumerState<TimePickerView> {
  late Duration _current;

  _androidSelectTime(BuildContext context) async {
    final TimeOfDay? timeOfDay = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: _current.inHours.remainder(24),
            minute: _current.inMinutes.remainder(60)),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child ?? Container(),
          );
        });
    if (timeOfDay != null) {
      final newTime =
          Duration(hours: timeOfDay.hour, minutes: timeOfDay.minute);
      if (newTime == _current) return;
      setState(() {
        _current = Duration(hours: timeOfDay.hour, minutes: timeOfDay.minute);
      });
      widget.onChanged?.call(newTime);
    }
  }

  void _iosSelectTime(BuildContext context) {
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) => Container(
              height: 216,
              padding: const EdgeInsets.only(top: 6.0),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: SafeArea(
                top: false,
                child: CupertinoDatePicker(
                  initialDateTime: DateTime.fromMillisecondsSinceEpoch(
                      _current.inMilliseconds,
                      isUtc: true),
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: false,
                  onDateTimeChanged: (DateTime newTime) {
                    setState(() => _current =
                        Duration(hours: newTime.hour, minutes: newTime.minute));
                    widget.onChanged?.call(_current);
                  },
                ),
              ),
            ));
  }

  @override
  void initState() {
    super.initState();
    _current = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText.bodyLarge(
            widget.title,
            color: const Color.fromRGBO(0, 0, 0, 0.4),
          ),
          const AppGap.semiSmall(),
          TextButton(
            onPressed: () {
              if (Platform.isAndroid) {
                _androidSelectTime(context);
              } else if (Platform.isIOS) {
                _iosSelectTime(context);
              }
            },
            style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 0)),
            child: AppText.titleLarge(
              DateFormatUtils.formatTimeAmPm(_current.inSeconds),
            ),
          ),
          const AppGap.small(),
          Image.asset('assets/images/line.png'),
          const AppGap.small(),
          Visibility(
            visible: widget.isNextDay,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: const AppText.bodyMedium(
              'next day',
              color: Colors.grey,
            ),
          )
        ]);
  }
}
