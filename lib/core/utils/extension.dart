import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// An extension on the `Map` class providing additional utility methods.
extension MapExt on Map {
  /// Retrieves a value from a nested map structure using a dot-separated path.
  ///
  /// For example, given a map `{'a': {'b': 1}}`, calling `getValueByPath('a.b')`
  /// would return `1`.
  ///
  /// [path] A dot-separated string representing the path to the desired value.
  ///
  /// Returns the value of type [T] found at the specified path. Throws an error
  /// if the path is invalid or the value is not of type [T].
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

/// An extension on the `String` class providing various formatting and utility methods.
extension StringExt on String {
  /// Capitalizes the first letter of the string.
  ///
  /// Example: 'word' becomes 'Word'.
  String capitalize() => isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;

  /// Capitalizes the first letter of each word in a space-separated string,
  /// preserving the original casing of other letters.
  ///
  /// Note: This is similar to `capitalizeWords`, but implemented with `fold`.
  String camelCapitalize() {
    return split(' ').fold(
        '',
        (previousValue, element) =>
            '${previousValue.isEmpty ? '' : '$previousValue '}${element.capitalize()}');
  }

  /// Capitalizes the first letter of each word in a space-separated string.
  ///
  /// Example: 'hello world' becomes 'Hello World'.
  String capitalizeWords() {
    return split(' ').map((element) => element.capitalize()).join(' ');
  }

  /// Capitalizes the first letter of each sentence in the string.
  ///
  /// Assumes sentences are separated by '. '.
  /// Example: 'hello world. how are you?' becomes 'Hello world. How are you?'.
  String capitalizeSentence() {
    return split('. ').map((element) => element.capitalize()).join('. ');
  }

  /// Converts a camelCase or PascalCase string into kebab-case.
  ///
  /// Example: 'helloWorld' becomes 'hello-world'.
  String kebab() {
    // Replace uppercase letters with a hyphen and the lowercase letter
    final pattern = RegExp(r'(?=[A-Z])');
    return '${this[0].toLowerCase()}${substring(1)}'
        .replaceAll(' ', '')
        .replaceAllMapped(pattern, (match) => '-')
        .toLowerCase();
  }

  /// Checks if the string is a valid JSON-formatted string.
  ///
  /// Returns `true` if the string can be decoded as JSON, `false` otherwise.
  bool isJsonFormat() {
    try {
      jsonDecode(this);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Computes the HMAC-SHA256 hash of the string using a given secret.
  ///
  /// [secret] The secret key for the HMAC function.
  ///
  /// Returns the hexadecimal representation of the hash.
  String toHmacSHA256(String secret) {
    final hmac = Hmac(sha256, secret.codeUnits);
    final digest = hmac.convert(utf8.encode(this));
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Computes the MD5 hash of the string.
  ///
  /// Returns the hexadecimal representation of the hash.
  String toMd5() {
    return md5.convert(utf8.encode(this)).toString();
  }

  /// Compares this version string to another version string.
  ///
  /// This method is designed for version strings like '1.2.3'. It pads each
  /// component with leading zeros to ensure correct lexicographical comparison.
  ///
  /// [comparedVersion] The version string to compare against.
  ///
  /// Returns a negative value if this version is less than [comparedVersion],
  /// a positive value if it's greater, and zero if they are equal.
  int compareToVersion(String comparedVersion) {
    List<String> currentSplit = split('.');
    final current = currentSplit.map((e) => e.padLeft(8, '0')).join();
    List<String> comparedSplit = comparedVersion.split('.');
    final compared = comparedSplit.map((e) => e.padLeft(8, '0')).join();
    return current.compareTo(compared);
  }
}
