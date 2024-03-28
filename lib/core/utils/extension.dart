import 'dart:convert';

import 'package:crypto/crypto.dart';

extension MapExt on Map {
  T getValueByPath<T>(String path) {
    final token = path.split('.');
    if (token.length == 1) {
      return this[token[0]];
    } else {
      return (this[token[0]] as Map)
          .getValueByPath<T>(token.sublist(1).join('.'));
    }
  }
}

extension StringExt on String {
  String capitalized() =>
      '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String camelCapitalized() {
    return split(' ').fold(
        '',
        (previousValue, element) =>
            '${previousValue.isEmpty ? '' : '$previousValue '}${element.capitalized()}');
  }

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

  /// Only use this on version string
  int compareToVersion(String comparedVersion) {
    List<String> currentSplit = split('.');
    final current = currentSplit.map((e) => e.padLeft(8, '0')).join();
    List<String> comparedSplit = comparedVersion.split('.');
    final compared = comparedSplit.map((e) => e.padLeft(8, '0')).join();
    return current.compareTo(compared);
  }
}
