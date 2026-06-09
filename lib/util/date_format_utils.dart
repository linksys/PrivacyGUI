import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

class DateFormatUtils {
  static String formatDuration(Duration d,
      [BuildContext? context, bool excludeSecs = false]) {
    var seconds = d.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];
    if (days != 0) {
      final token = context == null ? '${days}d' : loc(context).nDays(days);
      tokens.add(token);
    }
    if (tokens.isNotEmpty || hours != 0) {
      final token = context == null ? '${hours}h' : loc(context).nHours(hours);
      tokens.add(token);
    }
    if (tokens.isNotEmpty || minutes != 0) {
      final token =
          context == null ? '${minutes}m' : loc(context).nMinutes(minutes);
      tokens.add(token);
    }
    if (!excludeSecs) {
      final token =
          context == null ? '${seconds}s' : loc(context).nSeconds(seconds);
      tokens.add(token);
    }

    return tokens.join(' ');
  }

  static String formatTimeMSS(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String m = timeAmount.inMinutes.remainder(60).toString();
    final String s =
        timeAmount.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatTimeInterval(int startTimeInSecond, int endTimeInSecond) {
    bool isNextDay = startTimeInSecond > endTimeInSecond;
    return '${formatTimeAmPm(startTimeInSecond)} - ${formatTimeAmPm(endTimeInSecond)}${isNextDay ? ' next day' : ''}';
  }

  static String formatTimeAmPm(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String h = timeAmount.inHours == 12
        ? timeAmount.inHours.toString()
        : timeAmount.inHours.remainder(12).toString().padLeft(2, '0');
    final String m =
        timeAmount.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ampm = timeAmount.inHours.remainder(24) >= 12 ? 'pm' : 'am';
    return '$h:$m $ampm';
  }

  static String formatTimeHM(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String h = timeAmount.inHours.toString().padLeft(2, '0');
    final String m =
        timeAmount.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$h hr,$m min';
  }

  /// Formats an ISO 8601 timestamp as relative time ("3 minutes ago").
  static String formatRelativeTime(String? isoTime) {
    if (isoTime == null || isoTime.isEmpty) return '--';
    try {
      final dateTime = DateTime.parse(isoTime);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return isoTime;
    }
  }
}
