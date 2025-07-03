import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:privacy_gui/core/utils/logger.dart';

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
  /// Capitalize ONE word
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;

  /// Camel capitalize words
  String camelCapitalize() {
    return split(' ').fold(
        '',
        (previousValue, element) =>
            '${previousValue.isEmpty ? '' : '$previousValue '}${element.capitalize()}');
  }

  /// Capitalize words
  String capitalizeWords() {
    return split(' ').map((element) => element.capitalize()).join(' ');
  }

  /// Capitalize sentences
  String capitalizeSentence() {
    return split('. ').map((element) => element.capitalize()).join('. ');
  }

  String kebab() {
    // Replace uppercase letters with a hyphen and the lowercase letter
    final pattern = RegExp(r'(?=[A-Z])');
    return '${this[0].toLowerCase()}${substring(1)}'
        .replaceAll(' ', '')
        .replaceAllMapped(pattern, (match) => '-')
        .toLowerCase();
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

  /// Only use this on version string
  int compareToVersion(String comparedVersion) {
    List<String> currentSplit = split('.');
    final current = currentSplit.map((e) => e.padLeft(8, '0')).join();
    List<String> comparedSplit = comparedVersion.split('.');
    final compared = comparedSplit.map((e) => e.padLeft(8, '0')).join();
    return current.compareTo(compared);
  }
}
