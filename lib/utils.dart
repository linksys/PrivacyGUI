import 'dart:math';

import 'package:flutter/widgets.dart';

class Utils
{
  static const String NoSpeedCalculationText = "-----";
  static const bool ReleaseMode = bool.fromEnvironment('dart.vm.product', defaultValue: false);

  static String formatDuration(Duration d) {
    var seconds = d.inSeconds;
    final days = seconds ~/ Duration.secondsPerDay;
    seconds -= days * Duration.secondsPerDay;
    final hours = seconds ~/ Duration.secondsPerHour;
    seconds -= hours * Duration.secondsPerHour;
    final minutes = seconds ~/ Duration.secondsPerMinute;
    seconds -= minutes * Duration.secondsPerMinute;

    final List<String> tokens = [];
    if (days != 0) {
      tokens.add('${days}d');
    }
    if (tokens.isNotEmpty || hours != 0) {
      tokens.add('${hours}h');
    }
    if (tokens.isNotEmpty || minutes != 0) {
      tokens.add('${minutes}m');
    }
    tokens.add('${seconds}s');

    return tokens.join(' ');
  }

  static String formatTimeMSS(int timeInSecond) {
    final Duration timeAmount = Duration(seconds: timeInSecond);
    final String m = timeAmount.inMinutes.remainder(60).toString();
    final String s = timeAmount.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatBytes(int bytes, {int decimals = 0}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "Kb", "Mb", "Gb", "Tb", "Pb"];
    var i = (log(bytes) / log(1024)).floor();
    var number = (bytes / pow(1024, i));
    return (number).toStringAsFixed(number.truncateToDouble() == number ? 0 : decimals) +
        ' ' +
        suffixes[i];
  }

  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
  static double getScreenRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }
  static Size getPhysicalScreenSize(BuildContext context) {
    return getScreenSize(context) * getScreenRatio(context);
  }
  static double getPhysicalScreenWidth(BuildContext context) {
    return getScreenWidth(context) * getScreenRatio(context);
  }
  static double getPhysicalScreenHeight(BuildContext context) {
    return getScreenHeight(context) * getScreenRatio(context);
  }
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }
  static double getTopSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }
  static double getBottomSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }
  static double getSafeAreaHeight(BuildContext context) {
    return getScreenHeight(context) - getTopSafeAreaPadding(context) - getBottomSafeAreaPadding(context);
  }
}