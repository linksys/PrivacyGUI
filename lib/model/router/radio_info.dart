class RouterRadioInfo {
  final String band;
  final String bssid;
  final String radioID;
  final String physicalRadioID;
  final RouterRadioInfoSettings settings;

  const RouterRadioInfo({
    required this.band,
    required this.bssid,
    required this.radioID,
    required this.physicalRadioID,
    required this.settings,
  });

  Map<String, dynamic> toJson() {
    return {
      'band': band,
      'bssid': bssid,
      'radioID': radioID,
      'physicalRadioID': physicalRadioID,
      'settings': settings,
    };
  }

  factory RouterRadioInfo.fromJson(Map<String, dynamic> json) {
    return RouterRadioInfo(
      band: json['band'] as String,
      bssid: json['bssid'] as String,
      radioID: json['radioID'] as String,
      physicalRadioID: json['physicalRadioID'] as String,
      settings: RouterRadioInfoSettings.fromJson(json['settings']),
    );
  }

  RouterRadioInfo copyWith({
    String? band,
    String? bssid,
    String? radioID,
    String? physicalRadioID,
    RouterRadioInfoSettings? settings,
  }) {
    return RouterRadioInfo(
      band: band ?? this.band,
      bssid: bssid ?? this.bssid,
      radioID: radioID ?? this.radioID,
      physicalRadioID: physicalRadioID ?? this.physicalRadioID,
      settings: settings ?? this.settings,
    );
  }
}

class RouterRadioInfoSettings {
  final bool broadcastSSID;
  final String ssid;
  final bool isEnable;
  final String security;
  final int channel;
  final RouterWPAPersonalSettings wpaPersonalSettings;

  const RouterRadioInfoSettings({
    required this.broadcastSSID,
    required this.ssid,
    required this.isEnable,
    required this.security,
    required this.channel,
    required this.wpaPersonalSettings,
  });

  Map<String, dynamic> toJson() {
    return {
      'broadcastSSID': broadcastSSID,
      'ssid': ssid,
      'isEnable': isEnable,
      'security': security,
      'channel': channel,
      'wpaPersonalSettings': wpaPersonalSettings,
    };
  }

  factory RouterRadioInfoSettings.fromJson(Map<String, dynamic> json) {
    return RouterRadioInfoSettings(
      broadcastSSID: json['broadcastSSID'],
      ssid: json['ssid'],
      isEnable: json['isEnabled'],
      security: json['security'],
      channel: json['channel'],
      wpaPersonalSettings:
          RouterWPAPersonalSettings.fromJson(json['wpaPersonalSettings']),
    );
  }

  RouterRadioInfoSettings copyWith({
    bool? broadcastSSID,
    String? ssid,
    bool? isEnable,
    String? security,
    int? channel,
    RouterWPAPersonalSettings? wpaPersonalSettings,
  }) {
    return RouterRadioInfoSettings(
      broadcastSSID: broadcastSSID ?? this.broadcastSSID,
      ssid: ssid ?? this.ssid,
      isEnable: isEnable ?? this.isEnable,
      security: security ?? this.security,
      channel: channel ?? this.channel,
      wpaPersonalSettings: wpaPersonalSettings ?? this.wpaPersonalSettings,
    );
  }
}

class RouterWPAPersonalSettings {
  final String password;

  const RouterWPAPersonalSettings({
    required this.password,
  });

  RouterWPAPersonalSettings copyWith({
    String? password,
  }) {
    return RouterWPAPersonalSettings(
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'password': password,
    };
  }

  factory RouterWPAPersonalSettings.fromJson(Map<String, dynamic> json) {
    return RouterWPAPersonalSettings(
      password: json['passphrase'],
    );
  }
}
