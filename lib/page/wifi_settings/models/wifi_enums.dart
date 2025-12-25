// WiFi Settings Enums
// This file contains all WiFi-related enumerations used across the wifi_settings module.

enum WifiType {
  main,
  guest;
}

enum WifiRadioBand {
  radio_24(value: 'RADIO_2.4GHz'),
  radio_5_1(value: 'RADIO_5GHz'),
  radio_5_2(value: 'RADIO_5GHz_2'),
  radio_6(value: 'RADIO_6GHz');

  const WifiRadioBand({
    required this.value,
  });

  final String value;

  static WifiRadioBand getByValue(String value) {
    return WifiRadioBand.values.firstWhere((item) => item.value == value,
        orElse: () {
      print('⚠️ [WifiRadioBand] Unknown value: $value');
      return WifiRadioBand.values.first;
    });
  }

  String get bandName => value.replaceFirst('RADIO_', '');
}

enum WifiSecurityType {
  open(value: 'None'),
  wep(value: 'WEP'),
  wpaPersonal(value: 'WPA-Personal'),
  wpaEnterprise(value: 'WPA-Enterprise'),
  wpa2Personal(value: 'WPA2-Personal'),
  wpa2Enterprise(value: 'WPA2-Enterprise'),
  wpa1Or2MixedPersonal(value: 'WPA-Mixed-Personal'),
  wpa1Or2MixedEnterprise(value: 'WPA-Mixed-Enterprise'),
  wpa2Or3MixedPersonal(value: 'WPA2/WPA3-Mixed-Personal'),
  wpa3Personal(value: 'WPA3-Personal'),
  wpa3Enterprise(value: 'WPA3-Enterprise'),
  enhancedOpenNone(value: 'Enhanced-Open+None'),
  enhancedOpenOnly(value: 'Enhanced-Open-Only');

  const WifiSecurityType({
    required this.value,
  });

  final String value;

  static WifiSecurityType getByValue(String value) {
    return WifiSecurityType.values.firstWhere((item) => item.value == value,
        orElse: () {
      print('⚠️ [WifiSecurityType] Unknown value: $value');
      return WifiSecurityType.open;
    });
  }

  bool get isWPA3Variant =>
      this == WifiSecurityType.wpa2Or3MixedPersonal ||
      this == WifiSecurityType.wpa3Personal ||
      this == WifiSecurityType.wpa3Enterprise;

  bool get isWpaPersonalVariant =>
      this == WifiSecurityType.wpaPersonal ||
      this == WifiSecurityType.wpa2Personal ||
      this == WifiSecurityType.wpa1Or2MixedPersonal ||
      this == WifiSecurityType.wpa2Or3MixedPersonal ||
      this == wpa3Personal;

  bool get isWpaEnterpriseVariant =>
      this == WifiSecurityType.wpaEnterprise ||
      this == WifiSecurityType.wpa2Enterprise ||
      this == WifiSecurityType.wpa1Or2MixedEnterprise ||
      this == WifiSecurityType.wpa3Enterprise;

  bool get isOpenVariant =>
      this == WifiSecurityType.open ||
      this == WifiSecurityType.enhancedOpenNone ||
      this == WifiSecurityType.enhancedOpenOnly;
}

enum WifiWirelessMode {
  // Legacy (Max 20MHz)
  a(value: '802.11a'),
  b(value: '802.11b'),
  g(value: '802.11g'),
  bg(value: '802.11bg'),
  // 802.11n (Max 40MHz)
  n(value: '802.11n'),
  an(value: '802.11an'),
  bn(value: '802.11bn'),
  gn(value: '802.11gn'),
  bgn(value: '802.11bgn'),
  // 802.11ac (Max 160MHz - Assuming Wave 2 support for the highest option)
  ac(value: '802.11ac'),
  anac(value: '802.11anac'),
  bgnac(value: '802.11bgnac'),
  // 802.11ax (Max 160MHz)
  ax(value: '802.11ax'),
  anacax(value: '802.11anacax'),
  bgnax(value: '802.11bgnax'),
  // 802.11be (Max 320MHz)
  be(value: '802.11be'),
  anacaxbe(value: '802.11anacaxbe'),
  axbe(value: '802.11axbe'),
  // Special Case
  mixed(value: '802.11mixed');

  const WifiWirelessMode({
    required this.value,
  });

  final String value;

  static WifiWirelessMode getByValue(String value) {
    return WifiWirelessMode.values.firstWhere((item) => item.value == value,
        orElse: () {
      print('⚠️ [WifiWirelessMode] Unknown value: $value');
      return WifiWirelessMode.mixed;
    });
  }

  bool get isIncludeBeMixedMode =>
      this == be || this == axbe || this == anacaxbe || this == mixed;

  /// Gets the maximum channel width supported by this wireless mode.
  WifiChannelWidth get maxSupportedWidth {
    switch (this) {
      // 802.11be (Wi-Fi 7) supports 320MHz
      case WifiWirelessMode.be:
      case WifiWirelessMode.anacaxbe:
      case WifiWirelessMode.axbe:
      case WifiWirelessMode.mixed:
        return WifiChannelWidth.wide320;

      // 802.11ax (Wi-Fi 6/6E) supports up to 160MHz
      case WifiWirelessMode.ax:
      case WifiWirelessMode.anacax:
      case WifiWirelessMode.bgnax:
        // Includes both contiguous and non-contiguous 160MHz options
        return WifiChannelWidth.wide160nc;

      // 802.11ac (Wi-Fi 5) supports 80MHz (160MHz is optional, conservatively set to 80MHz)
      case WifiWirelessMode.ac:
      case WifiWirelessMode.anac:
      case WifiWirelessMode.bgnac:
        return WifiChannelWidth.wide80;

      // 802.11n (Wi-Fi 4) supports 40MHz
      case WifiWirelessMode.n:
      case WifiWirelessMode.an:
      case WifiWirelessMode.bn:
      case WifiWirelessMode.gn:
      case WifiWirelessMode.bgn:
        return WifiChannelWidth.wide40;

      // 802.11a/b/g and other legacy modes only support 20MHz
      case WifiWirelessMode.a:
      case WifiWirelessMode.b:
      case WifiWirelessMode.g:
      case WifiWirelessMode.bg:
        return WifiChannelWidth.wide20;
    }
  }
}

enum WifiChannelWidth {
  auto(value: 'Auto'),
  wide20(value: 'Standard'), // 20 MHz (802.11a/b/g+)
  wide40(value: 'Wide'), // 40 MHz (802.11n+)
  wide80(value: 'Wide80'), // 80 MHz (802.11ac+)
  wide160c(value: 'Wide160c'), // 160 MHz Contiguous (802.11ac/ax+)
  wide160nc(value: 'Wide160nc'), // 160 MHz Non-Contiguous (802.11ac/ax+)
  wide320(value: 'Wide320'); // 320 MHz (802.11be/Wi-Fi 7+)

  const WifiChannelWidth({
    required this.value,
  });

  final String value;

  static WifiChannelWidth getByValue(String value) {
    return WifiChannelWidth.values.firstWhere((item) => item.value == value,
        orElse: () {
      print('⚠️ [WifiChannelWidth] Unknown value: $value');
      return WifiChannelWidth.auto;
    });
  }
}
