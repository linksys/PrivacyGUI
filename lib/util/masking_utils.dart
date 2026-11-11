import 'package:privacy_gui/core/utils/fernet_manager.dart';

class MaskingUtils {
  /// Masks the value of every `"<key>": <value>` whose key ends in one of
  /// [keys], in any letter case.
  ///
  /// Case-insensitive because a USP log names a leaf by its TR-181 path, so a
  /// password arrives as `"Device.DynamicDNS.Client.1.Password": "…"` and a
  /// Wi-Fi key as `"…AccessPoint.1.Security.KeyPassphrase": "…"`, never as a
  /// lower-case `password`. Each value is replaced where it was matched, not
  /// by searching the text for it: the same characters can appear earlier
  /// (in a key, or an unrelated value), and replacing that first occurrence
  /// would leave the secret in place. An empty value is left as it is.
  static String maskJsonValue(String raw, List<String> keys) {
    if (keys.isEmpty) return raw;
    final pattern = '"?(${keys.join('|')})"?\\s*:\\s*"?([\\s\\S]*?)"?(?=,|})';
    final regex = RegExp(pattern, multiLine: true, caseSensitive: false);
    return raw.replaceAllMapped(regex, (match) {
      final whole = match.group(0)!;
      final value = match.group(2) ?? '';
      if (value.isEmpty) return whole;
      final end = whole.endsWith('"') ? whole.length - 1 : whole.length;
      return whole.replaceRange(end - value.length, end, '************');
    });
  }

  static String maskUsernamePasswordBodyValue(String raw) {
    List<String> keys = ['username', 'password'];
    final pattern = '(${keys.join('|')})\\s*=\\s*([\\S]*?)(?=&|\\n)';
    RegExp regex = RegExp(pattern, multiLine: true);
    String result = raw;

    regex.allMatches(raw).forEach((element) {
      for (final key in keys) {
        if (element.groupCount == 2 &&
            element.group(1)!.toLowerCase() == key.toLowerCase()) {
          final target = element.group(2)!;
          result = result.replaceFirst(target, '************');
        }
      }
    });
    return result;
  }

  static String maskSensitiveJsonValues(String raw) {
    final keys = [
      'username',
      'password',
      'privateKey',
      'adminPassword',
      'passphrase',
    ];
    return maskJsonValue(raw, keys);
  }

  static String encryptJNAPAuth(String raw) {
    final pattern = RegExp(r'(X-JNAP-Authorization: Basic )([a-zA-Z0-9=+/]+)');
    return raw.replaceAllMapped(pattern, (match) {
      final header = match.group(1)!;
      final encodedPassword = match.group(2)!;

      final encryptedPassword = FernetManager().encrypt(encodedPassword);

      if (encryptedPassword != null) {
        return '$header$encryptedPassword';
      } else {
        return '$header************';
      }
    });
  }

  static String maskSerialNumber(String raw) {
    final pattern = RegExp(r'("?serialNumber"?\s*:\s*"?)([A-Za-z0-9]{4,})("?)',
        caseSensitive: false);
    return raw.replaceAllMapped(pattern, (match) {
      final prefix = match.group(1)!;
      final value = match.group(2)!;
      final suffix = match.group(3)!;
      if (value.length <= 4) return '$prefix****$suffix';
      return '$prefix****${value.substring(value.length - 4)}$suffix';
    });
  }

  static String maskMacAddress(String raw) {
    final pattern = RegExp(r'([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}');
    return raw.replaceAllMapped(pattern, (match) {
      final mac = match.group(0)!;
      final separator = mac.contains(':') ? ':' : '-';
      final lastTwo = mac.split(RegExp(r'[:\-]'));
      return 'XX${separator}XX${separator}XX${separator}XX$separator${lastTwo[4]}$separator${lastTwo[5]}';
    });
  }
}
