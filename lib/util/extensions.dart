import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/util/languages.dart';

extension Unique<E, Id> on List<E> {
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = Set();
    var list = inplace ? this : List<E>.from(this);
    if (list.isEmpty) {
      return list;
    }
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

extension DurationExt on Duration {
  String convertToHMS() {
    String negativeSign = isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

extension TimeOfDayExt on TimeOfDay {
  int compareTo(TimeOfDay other) {
    final double1 = hour + minute / 60.0;
    final double2 = other.hour + minute / 60.0;
    return double1.compareTo(double2);
  }
}

extension LocaleExt on Locale {
  String get displayText {
    final localStr = toLanguageTag();
    return getLanguageData(localStr)['name'] as String;
  }
}

extension DateFormatTryParse on DateFormat {
  DateTime? tryParse(String inputString, [bool utc = false]) {
    try {
      return parse(inputString, utc);
    } on FormatException {
      return null;
    }
  }
}
