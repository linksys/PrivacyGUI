enum SecurityType { wpa, wep, none }

class WiFiCredential {
  const WiFiCredential._(
      {this.ssid = '',
        this.password = '',
        this.type = SecurityType.none,
        this.isHidden = false});

  factory WiFiCredential.parse(String raw) {
    String ssid = '', password = '';
    bool isHidden = false;
    SecurityType type = SecurityType.none;

    RegExp regex =
    RegExp(r"([(?=S|T|P|H):]{1}:[\S\s]*?(?=;T:|;H:|;P:|;S:|;;$))");
    regex.allMatches(raw).forEach((element) {
      final data = element.group(0) ?? "";
      print(data);
      RegExp regex = RegExp(r"([(?=S|T|P|H):]{1}):([\S\s]*)");
      regex.allMatches(data).forEach((element) {
        switch (element.group(1)) {
          case 'S':
            ssid = element.group(2) ?? '';
            break;
          case 'T':
            type = SecurityType.values.firstWhere(
                    (e) => e.toString() == (element.group(2) ?? 'none'),
                orElse: () => SecurityType.none);
            break;
          case 'P':
            password = element.group(2) ?? '';
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
    return 'S:$ssid;P:$password;T:${type.name};H:$isHidden;;';
  }
}