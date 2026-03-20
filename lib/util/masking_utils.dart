import 'package:privacy_gui/core/utils/fernet_manager.dart';

class MaskingUtils {
  static String maskJsonValue(String raw, List<String> keys) {
    final pattern = '"?(${keys.join('|')})"?\\s*:\\s*"?([\\s\\S]*?)"?(?=,|})';
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

  static String replaceHttpScheme(String raw) {
    const pattern =
        r'(https?:\/\/)?((www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b)([-a-zA-Z0-9()@:%_\+.~#?&\/\/=]*)';
    RegExp regex = RegExp(pattern, multiLine: true);
    String result = raw;
    int idx = 0;
    regex.allMatches(result).forEach((element) {
      element.groups([1, 2, 4]).nonNulls.forEach((group) {
            int start = raw.indexOf(group, idx);
            int end = start + group.length;
            final replaced = group.replaceAll(':', '-').replaceAll('.', '-');
            result = result.replaceRange(start, end, replaced);
            idx = end;
          });
    });
    return result;
  }
}
