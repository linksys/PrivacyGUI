/// WiFi-related enumerations for USP/TR-181 protocol.
///
/// These enums provide type-safe values for WiFi configuration.
library;

/// WiFi frequency band.
enum WifiBand {
  ghz2_4('2.4GHz'),
  ghz5('5GHz'),
  ghz6('6GHz');

  const WifiBand(this.value);
  final String value;

  /// Parse from string value.
  static WifiBand? fromValue(String? value) {
    if (value == null) return null;
    return WifiBand.values.cast<WifiBand?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// WiFi operating mode (802.11 standard).
enum WifiMode {
  bg('802.11bg'),
  bgn('802.11bgn'),
  bgnax('802.11bgnax'),
  a('802.11a'),
  anac('802.11anac'),
  anacax('802.11anacax'),
  anacaxbe('802.11anacaxbe'),
  ax('802.11ax'),
  ac('802.11ac'),
  n('802.11n'),
  be('802.11be'),
  mixed('802.11mixed');

  const WifiMode(this.value);
  final String value;

  static WifiMode? fromValue(String? value) {
    if (value == null) return null;
    return WifiMode.values.cast<WifiMode?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// WiFi security type.
enum WifiSecurityType {
  none('None'),
  wepOpen('WEP-Open'),
  wepShared('WEP-Shared'),
  wpaPersonal('WPA-Personal'),
  wpa2Personal('WPA2-Personal'),
  wpa3Personal('WPA3-Personal'),
  wpaEnterprise('WPA-Enterprise'),
  wpa2Enterprise('WPA2-Enterprise'),
  wpa3Enterprise('WPA3-Enterprise'),
  wpaWpa2Personal('WPA-WPA2-Personal'),
  wpa2Wpa3Personal('WPA2-WPA3-Personal');

  const WifiSecurityType(this.value);
  final String value;

  static WifiSecurityType? fromValue(String? value) {
    if (value == null) return null;
    return WifiSecurityType.values.cast<WifiSecurityType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// WiFi channel width.
enum WifiChannelWidth {
  auto('Auto'),
  standard('Standard'), // 20MHz
  wide('Wide'), // 40MHz
  wide80('Wide80'), // 80MHz
  wide160('Wide160'); // 160MHz

  const WifiChannelWidth(this.value);
  final String value;

  static WifiChannelWidth? fromValue(String? value) {
    if (value == null) return null;
    return WifiChannelWidth.values.cast<WifiChannelWidth?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}
