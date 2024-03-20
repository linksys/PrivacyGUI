import 'dart:convert';

import 'package:crypto/crypto.dart';

extension StringExt on String {
  bool isJsonFormat() {
    try {
      jsonDecode(this);
      return true;
    } catch (_) {
      return false;
    }
  }

  String toHmacSHA256(String secret) {
    final hmac = Hmac(sha256, secret.codeUnits);
    final digest = hmac.convert(utf8.encode(this));
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String toMd5() {
    return md5.convert(utf8.encode(this)).toString();
  }

  String capitalize(String value) {
    return "${value[0].toUpperCase()}${value.substring(1).toLowerCase()}";
  }

  String capitalizeWords(String value) {
    return value.split(' ').map((element) => capitalize(element)).join(' ');
  }
  String capitalizeSentence(String value) {
    return value.split('. ').map((element) => capitalize(element)).join('. ');
  }
}

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
