import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/utils.dart';
import 'package:ui_kit_library/ui_kit.dart';

class TimerCountdownWidget extends StatelessWidget {
  final int initialSeconds;
  final String? title;
  const TimerCountdownWidget({
    Key? key,
    required this.initialSeconds,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream.periodic(
        const Duration(seconds: 1),
        (count) => initialSeconds - count,
      ).take(initialSeconds + 1),
      builder: (context, snapshot) {
        final secondsLeft = snapshot.data ?? initialSeconds;
        final display = secondsLeft > 0
            ? title == 'Pin code'
                ? loc(context).remoteAssistancePinCodeExpiresIn(
                    DateFormatUtils.formatTimeMSS(secondsLeft))
                : loc(context).remoteAssistanceSessionExpiresIn(
                    DateFormatUtils.formatTimeMSS(secondsLeft))
            : title == 'Pin code'
                ? loc(context).remoteAssistancePinCodeExpired
                : loc(context).remoteAssistanceSessionExpired;
        return AppText.bodyMedium(display);
      },
    );
  }
}
