/// Characters the WiFi QR format gives a meaning of its own: ; : , separate
/// the fields, \ escapes and " quotes. A name or password holding one must
/// escape it with a backslash.
final _qrSpecialCharacters = RegExp(r'[\\;,:"]');
final _qrEscapedCharacter = RegExp(r'\\([\\;,:"])');

enum SecurityType { wpa, wep, none }

class WiFiCredential {
  const WiFiCredential({
    this.ssid = '',
    this.password = '',
    this.type = SecurityType.none,
    this.isHidden = false,
  });

  const WiFiCredential._({
    this.ssid = '',
    this.password = '',
    this.type = SecurityType.none,
    this.isHidden = false,
  });

  factory WiFiCredential.parse(String raw) {
    String ssid = '', password = '';
    bool isHidden = false;
    SecurityType type = SecurityType.none;

    RegExp regex =
        RegExp(r"([(?=S|T|P|H):]{1}:[\S\s]*?(?=;T:|;H:|;P:|;S:|;$|;;$))");
    regex.allMatches(raw).forEach((element) {
      final data = element.group(0) ?? "";
      RegExp regex = RegExp(r"([(?=S|T|P|H):]{1}):([\S\s]*)");
      regex.allMatches(data).forEach((element) {
        switch (element.group(1)) {
          case 'S':
            ssid = _unescape(element.group(2) ?? '');
            break;
          case 'T':
            // WPA, WEP or nopass; nopass, like any other, is no security.
            type = SecurityType.values.firstWhere(
                (e) => e.name == (element.group(2) ?? '').toLowerCase(),
                orElse: () => SecurityType.none);
            break;
          case 'P':
            password = _unescape(element.group(2) ?? '');
            break;
          case 'H':
            isHidden = (element.group(2) ?? '') == 'true';
            break;
        }
      });
    });

    return WiFiCredential._(
        ssid: ssid, password: password, type: type, isHidden: isHidden);
  }

  WiFiCredential copyWith(
      {String? ssid, String? password, bool? isHidden, SecurityType? type}) {
    return WiFiCredential._(
        ssid: ssid ?? this.ssid,
        password: password ?? this.password,
        isHidden: isHidden ?? this.isHidden,
        type: type ?? this.type);
  }

  final String ssid;
  final String password;
  final SecurityType type;
  final bool isHidden;

  String generate() {
    final name = _escape(ssid);
    // An open network is "nopass" in the WiFi QR format, and must not carry a
    // password, or phones try to join it as WPA.
    if (type == SecurityType.none) {
      return 'WIFI:S:$name;T:nopass;H:$isHidden;;';
    }
    return 'WIFI:S:$name;P:${_escape(password)};'
        'T:${type.name.toUpperCase()};H:$isHidden;;';
  }

  static String _escape(String value) =>
      value.replaceAllMapped(_qrSpecialCharacters, (m) => '\\${m[0]}');

  static String _unescape(String value) =>
      value.replaceAllMapped(_qrEscapedCharacter, (m) => m[1]!);
}
