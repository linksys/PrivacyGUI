import 'package:privacy_gui/core/utils/fernet_manager.dart';

class MaskingUtils {
  /// Masks the value of every `"<key>": <value>` whose key ends in one of
  /// [keys], in any letter case.
  ///
  /// Case-insensitive because a USP log names a leaf by its TR-181 path, so a
  /// password arrives as `"Device.DynamicDNS.Client.1.Password": "…"` and a
  /// Wi-Fi key as `"…AccessPoint.1.Security.KeyPassphrase": "…"`, never as a
  /// lower-case `password`.
  ///
  /// A quoted value is read as a JSON string, to its closing quote, so a
  /// secret holding `,`, `}` or an escaped `"` is masked whole; an unquoted one
  /// runs to the next `,` or `}`. Each value is replaced where it was matched,
  /// not by searching the text for it: the same characters can appear earlier
  /// (in a key, or an unrelated value), and replacing that occurrence would
  /// leave the secret in place. An empty value is left as it is.
  static String maskJsonValue(String raw, List<String> keys) {
    if (keys.isEmpty) return raw;
    final regex = RegExp(
      '("?(?:${keys.join('|')})"?\\s*:\\s*)'
      r'(?:"((?:[^"\\]|\\.)*)"|([^,}\s][^,}\n]*))',
      caseSensitive: false,
    );
    return raw.replaceAllMapped(regex, (match) {
      final prefix = match.group(1)!;
      final quoted = match.group(2);
      if (quoted == null) return '$prefix************';
      return quoted.isEmpty ? match.group(0)! : '$prefix"************"';
    });
  }

  /// Masks the user name and password of a form body
  /// (`username=…&password=…`), in any letter case, each where it was matched.
  /// A value runs to the next `&`, line end or the end of the text.
  static String maskUsernamePasswordBodyValue(String raw) {
    final regex = RegExp(
      r'((?:username|password)\s*=\s*)([^&\s]*)(?=&|\n|$)',
      caseSensitive: false,
    );
    return raw.replaceAllMapped(
      regex,
      (match) => match.group(2)!.isEmpty
          ? match.group(0)!
          : '${match.group(1)}************',
    );
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
