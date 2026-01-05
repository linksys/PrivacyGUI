import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/util/languages.dart';

/// An extension on `List` to provide a method for filtering out duplicate elements.
extension Unique<E, Id> on List<E> {
  /// Returns a list with unique elements.
  ///
  /// The uniqueness of elements is determined by an `id` function. If no `id`
  /// function is provided, the elements themselves are used for comparison.
  ///
  /// [id] A function that returns a unique identifier for an element.
  ///
  /// [inplace] If `true`, modifies the original list. Otherwise, returns a new list.
  ///
  /// Returns a list containing only the unique elements.
  List<E> unique([Id Function(E element)? id, bool inplace = true]) {
    final ids = <dynamic>{};
    var list = inplace ? this : List<E>.from(this);
    if (list.isEmpty) {
      return list;
    }
    list.retainWhere((x) => ids.add(id != null ? id(x) : x as Id));
    return list;
  }
}

/// An extension on `Duration` to provide custom formatting.
extension DurationExt on Duration {
  /// Converts the duration into a string format of "HH:MM:SS".
  ///
  /// This method handles both positive and negative durations, prepending a '-'
  /// sign if the duration is negative.
  ///
  /// Returns a formatted string representing the duration.
  String convertToHMS() {
    String negativeSign = isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(inSeconds.remainder(60).abs());
    return "$negativeSign${twoDigits(inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

/// An extension on `TimeOfDay` to add comparison functionality.
extension TimeOfDayExt on TimeOfDay {
  /// Compares this `TimeOfDay` to another, returning a value indicating their relationship.
  ///
  /// [other] The `TimeOfDay` to compare against.
  ///
  /// Returns a negative integer if this time is earlier than `other`, a positive
  /// integer if it's later, and zero if they are the same.
  int compareTo(TimeOfDay other) {
    final double1 = hour + minute / 60.0;
    final double2 = other.hour + minute / 60.0;
    return double1.compareTo(double2);
  }
}

/// An extension on `Locale` to provide additional utility methods.
extension LocaleExt on Locale {
  /// Gets a human-readable display name for the locale.
  ///
  /// This getter retrieves the language name from a predefined map based on the
  /// locale's language tag.
  String get displayText {
    final localStr = toLanguageTag();
    return getLanguageData(localStr)['name'] as String;
  }

  /// Creates a `Locale` object from a standard language tag string.
  ///
  /// This method parses a language tag (e.g., "en", "en-US", "zh-Hans-CN") and
  /// constructs the appropriate `Locale` object.
  ///
  /// [languageTag] The language tag string.
  ///
  /// Returns a `Locale` object.
  static Locale fromLanguageTag(String languageTag) {
    final token = languageTag.split('-');

    return switch (token.length) {
      1 => Locale(token[0]),
      2 => Locale(token[0], token[1]),
      3 => Locale.fromSubtags(
          languageCode: token[0], scriptCode: token[1], countryCode: token[2]),
      _ => Locale.fromSubtags(
          languageCode: token[0], scriptCode: token[1], countryCode: token[2]),
    };
  }
}

/// An extension on `DateFormat` to provide a safe parsing method.
extension DateFormatTryParse on DateFormat {
  /// Attempts to parse a string into a `DateTime` object, returning `null` on failure.
  ///
  /// This method wraps the default `parse` method in a try-catch block. If a
  /// `FormatException` occurs during parsing, it returns `null` instead of
  /// throwing an exception.
  ///
  /// [inputString] The string to parse.
  ///
  /// [utc] Whether to parse the string as a UTC time.
  ///
  /// Returns a `DateTime` object if parsing is successful, otherwise `null`.
  DateTime? tryParse(String inputString, [bool utc = false]) {
    try {
      return parse(inputString, utc);
    } on FormatException {
      return null;
    }
  }
}
