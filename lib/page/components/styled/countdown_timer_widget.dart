import 'dart:async';
import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';
import 'package:privacy_gui/utils.dart';

class CountdownTimerWidget extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback? onFinished;
  const CountdownTimerWidget({
    Key? key,
    required this.initialSeconds,
    this.onFinished,
  }) : super(key: key);

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
        if (_secondsLeft == 0 && widget.onFinished != null) {
          widget.onFinished!();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppText.labelLarge(DateFormatUtils.formatTimeMSS(_secondsLeft));
  }
}
