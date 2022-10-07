class NewRadioSettings {
  final String radioID;
  final RouterRadioInfoSettings settings;

  const NewRadioSettings({
    required this.radioID,
    required this.settings,
  });

  NewRadioSettings copyWith({
    String? radioID,
    RouterRadioInfoSettings? settings,
  }) {
    return NewRadioSettings(
      radioID: radioID ?? this.radioID,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'radioID': radioID,
      'settings': settings,
    };
  }

  factory NewRadioSettings.fromJson(Map<String, dynamic> json) {
    return NewRadioSettings(
      radioID: json['radioID'] as String,
      settings: json['settings'] as RouterRadioInfoSettings,
    );
  }
}
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
  final bool isEnabled;
  final String security;
  final int channel;
  final RouterWPAPersonalSettings wpaPersonalSettings;
  final String channelWidth;
  final String mode;

  const RouterRadioInfoSettings({
    required this.broadcastSSID,
    required this.ssid,
    required this.isEnabled,
    required this.security,
    required this.channel,
    required this.wpaPersonalSettings,
    required this.channelWidth,
    required this.mode,
  });

  Map<String, dynamic> toJson() {
    return {
      'broadcastSSID': broadcastSSID,
      'ssid': ssid,
      'isEnabled': isEnabled,
      'security': security,
      'channel': channel,
      'wpaPersonalSettings': wpaPersonalSettings,
      'channelWidth': channelWidth,
      'mode': mode,
    };
  }

  factory RouterRadioInfoSettings.fromJson(Map<String, dynamic> json) {
    return RouterRadioInfoSettings(
      broadcastSSID: json['broadcastSSID'],
      ssid: json['ssid'],
      isEnabled: json['isEnabled'],
      security: json['security'],
      channel: json['channel'],
      wpaPersonalSettings:
          RouterWPAPersonalSettings.fromJson(json['wpaPersonalSettings']),
      channelWidth: json['channelWidth'],
      mode: json['mode'],
    );
  }

  RouterRadioInfoSettings copyWith({
    bool? broadcastSSID,
    String? ssid,
    bool? isEnable,
    String? security,
    int? channel,
    RouterWPAPersonalSettings? wpaPersonalSettings,
    String? channelWidth,
    String? mode,
  }) {
    return RouterRadioInfoSettings(
      broadcastSSID: broadcastSSID ?? this.broadcastSSID,
      ssid: ssid ?? this.ssid,
      isEnabled: isEnable ?? this.isEnabled,
      security: security ?? this.security,
      channel: channel ?? this.channel,
      wpaPersonalSettings: wpaPersonalSettings ?? this.wpaPersonalSettings,
      channelWidth: channelWidth ?? this.channelWidth,
      mode: mode ?? this.mode,
    );
  }
}

class RouterWPAPersonalSettings {
  final String passphrase;

  const RouterWPAPersonalSettings({
    required this.passphrase,
  });

  RouterWPAPersonalSettings copyWith({
    String? password,
  }) {
    return RouterWPAPersonalSettings(
      passphrase: password ?? passphrase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passphrase': passphrase,
    };
  }

  factory RouterWPAPersonalSettings.fromJson(Map<String, dynamic> json) {
    return RouterWPAPersonalSettings(
      passphrase: json['passphrase'],
    );
  }
}
