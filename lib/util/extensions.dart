import 'dart:ui';

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

extension LocaleExt on Locale {
  String get displayText => switch ((languageCode, countryCode, scriptCode)) {
        ('en') => 'English (United States)',
        ('ja', null, null) => '日本語',
        ('fr', null, null) => 'Francais (France)',
        ('ko', null, null) => 'Korean',
        ('zh', null, 'Hans') => '簡體中文',
        ('zh', null, 'Hant') => '繁體中文',
        _ => 'English (United States)',
      };
}
