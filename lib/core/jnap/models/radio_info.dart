// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:equatable/equatable.dart';
/*
class SimpleWiFiSettings {
  const SimpleWiFiSettings({
    required this.ssid,
    required this.band,
    required this.security,
    required this.passphrase,
  });

  factory SimpleWiFiSettings.fromRadioInfo(RouterRadioInfo radioInfo) {
    return SimpleWiFiSettings(
      ssid: radioInfo.settings.ssid,
      band: radioInfo.band,
      security: radioInfo.settings.security,
      passphrase: radioInfo.settings.wpaPersonalSettings.passphrase,
    );
  }

  final String ssid;
  final String band;
  final String security;
  final String passphrase;

  SimpleWiFiSettings copyWith({
    String? ssid,
    String? band,
    String? security,
    String? passphrase,
  }) {
    return SimpleWiFiSettings(
      ssid: ssid ?? this.ssid,
      band: band ?? this.band,
      security: security ?? this.security,
      passphrase: passphrase ?? this.passphrase,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'band': band,
      'security': security,
      'passphrase': passphrase,
    }..removeWhere((key, value) => value == null);
  }

  factory SimpleWiFiSettings.fromMap(Map<String, dynamic> json) {
    return SimpleWiFiSettings(
      ssid: json['ssid'],
      band: json['band'],
      security: json['security'],
      passphrase: json['passphrase'],
    );
  }
}
*/

class NewRadioSettings extends Equatable {
  final String radioID;
  final RouterRadioInfoSettings settings;

  const NewRadioSettings({
    required this.radioID,
    required this.settings,
  });

  @override
  List<Object?> get props => [
        radioID,
        settings,
      ];

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
    }..removeWhere((key, value) => value == null);
  }

  factory NewRadioSettings.fromJson(Map<String, dynamic> json) {
    return NewRadioSettings(
      radioID: json['radioID'] as String,
      settings: json['settings'] as RouterRadioInfoSettings,
    );
  }
}

// This data model is based on 'GetRadioInfo3'
class GetRadioInfo extends Equatable {
  final bool isBandSteeringSupported;
  final List<RouterRadio> radios;

  const GetRadioInfo({
    required this.isBandSteeringSupported,
    required this.radios,
  });

  GetRadioInfo copyWith({
    bool? isBandSteeringSupported,
    List<RouterRadio>? radios,
  }) {
    return GetRadioInfo(
      isBandSteeringSupported:
          isBandSteeringSupported ?? this.isBandSteeringSupported,
      radios: radios ?? this.radios,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isBandSteeringSupported': isBandSteeringSupported,
      'radios': radios.map((x) => x.toMap()).toList(),
    };
  }

  factory GetRadioInfo.fromMap(Map<String, dynamic> map) {
    return GetRadioInfo(
      isBandSteeringSupported: map['isBandSteeringSupported'] as bool,
      radios: List<RouterRadio>.from(
        (map['radios'] as List<dynamic>).map<RouterRadio>(
          (x) => RouterRadio.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory GetRadioInfo.fromJson(String source) =>
      GetRadioInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [isBandSteeringSupported, radios];
}

class RouterRadio extends Equatable {
  final String radioID;
  final String physicalRadioID;
  final String bssid;
  final String band;
  final List<String> supportedModes;
  final String? defaultMixedMode;
  final List<SupportedChannelsForChannelWidths>
      supportedChannelsForChannelWidths;
  final List<String> supportedSecurityTypes;
  final int maxRadiusSharedKeyLength;
  final RouterRadioSettings settings;

  const RouterRadio({
    required this.radioID,
    required this.physicalRadioID,
    required this.bssid,
    required this.band,
    required this.supportedModes,
    this.defaultMixedMode,
    required this.supportedChannelsForChannelWidths,
    required this.supportedSecurityTypes,
    required this.maxRadiusSharedKeyLength,
    required this.settings,
  });

  RouterRadio copyWith({
    String? radioID,
    String? physicalRadioID,
    String? bssid,
    String? band,
    List<String>? supportedModes,
    String? defaultMixedMode,
    List<SupportedChannelsForChannelWidths>? supportedChannelsForChannelWidths,
    List<String>? supportedSecurityTypes,
    int? maxRadiusSharedKeyLength,
    RouterRadioSettings? settings,
  }) {
    return RouterRadio(
      radioID: radioID ?? this.radioID,
      physicalRadioID: physicalRadioID ?? this.physicalRadioID,
      bssid: bssid ?? this.bssid,
      band: band ?? this.band,
      supportedModes: supportedModes ?? this.supportedModes,
      defaultMixedMode: defaultMixedMode ?? this.defaultMixedMode,
      supportedChannelsForChannelWidths: supportedChannelsForChannelWidths ??
          this.supportedChannelsForChannelWidths,
      supportedSecurityTypes:
          supportedSecurityTypes ?? this.supportedSecurityTypes,
      maxRadiusSharedKeyLength:
          maxRadiusSharedKeyLength ?? this.maxRadiusSharedKeyLength,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radioID': radioID,
      'physicalRadioID': physicalRadioID,
      'bssid': bssid,
      'band': band,
      'supportedModes': supportedModes,
      'defaultMixedMode': defaultMixedMode,
      'supportedChannelsForChannelWidths': supportedChannelsForChannelWidths,
      'supportedSecurityTypes': supportedSecurityTypes,
      'maxRADIUSSharedKeyLength': maxRadiusSharedKeyLength,
      'settings': settings.toMap(),
    };
  }

  factory RouterRadio.fromMap(Map<String, dynamic> map) {
    return RouterRadio(
      radioID: map['radioID'] as String,
      physicalRadioID: map['physicalRadioID'] as String,
      bssid: map['bssid'] as String,
      band: map['band'] as String,
      supportedModes:
          List<String>.from((map['supportedModes'] as List<dynamic>)),
      defaultMixedMode: map['defaultMixedMode'] != null
          ? map['defaultMixedMode'] as String
          : null,
      supportedChannelsForChannelWidths:
          List<SupportedChannelsForChannelWidths>.from(
        (map['supportedChannelsForChannelWidths'] as List<dynamic>)
            .map<SupportedChannelsForChannelWidths>(
          (x) => SupportedChannelsForChannelWidths.fromMap(x),
        ),
      ),
      supportedSecurityTypes: List<String>.from(
        (map['supportedSecurityTypes'] as List<dynamic>),
      ),
      maxRadiusSharedKeyLength: map['maxRADIUSSharedKeyLength'] as int,
      settings:
          RouterRadioSettings.fromMap(map['settings'] as Map<String, dynamic>),
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterRadio.fromJson(String source) =>
      RouterRadio.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      radioID,
      physicalRadioID,
      bssid,
      band,
      supportedModes,
      defaultMixedMode,
      supportedChannelsForChannelWidths,
      supportedSecurityTypes,
      maxRadiusSharedKeyLength,
      settings,
    ];
  }
}

class RouterRadioSettings extends Equatable {
  final bool isEnabled;
  final String mode;
  final String ssid;
  final bool broadcastSSID;
  final String channelWidth;
  final int channel;
  final String security;
  final WepSettings? wepSettings;
  final WpaPersonalSettings? wpaPersonalSettings;
  final WpaEnterpriseSettings? wpaEnterpriseSettings;

  const RouterRadioSettings({
    required this.isEnabled,
    required this.mode,
    required this.ssid,
    required this.broadcastSSID,
    required this.channelWidth,
    required this.channel,
    required this.security,
    this.wepSettings,
    this.wpaPersonalSettings,
    this.wpaEnterpriseSettings,
  });

  RouterRadioSettings copyWith({
    bool? isEnabled,
    String? mode,
    String? ssid,
    bool? broadcastSSID,
    String? channelWidth,
    int? channel,
    String? security,
    WepSettings? wepSettings,
    WpaPersonalSettings? wpaPersonalSettings,
    WpaEnterpriseSettings? wpaEnterpriseSettings,
  }) {
    return RouterRadioSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      mode: mode ?? this.mode,
      ssid: ssid ?? this.ssid,
      broadcastSSID: broadcastSSID ?? this.broadcastSSID,
      channelWidth: channelWidth ?? this.channelWidth,
      channel: channel ?? this.channel,
      security: security ?? this.security,
      wepSettings: wepSettings ?? this.wepSettings,
      wpaPersonalSettings: wpaPersonalSettings ?? this.wpaPersonalSettings,
      wpaEnterpriseSettings:
          wpaEnterpriseSettings ?? this.wpaEnterpriseSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isEnabled': isEnabled,
      'mode': mode,
      'ssid': ssid,
      'broadcastSSID': broadcastSSID,
      'channelWidth': channelWidth,
      'channel': channel,
      'security': security,
      'wepSettings': wepSettings?.toMap(),
      'wpaPersonalSettings': wpaPersonalSettings?.toMap(),
      'wpaEnterpriseSettings': wpaEnterpriseSettings?.toMap(),
    };
  }

  factory RouterRadioSettings.fromMap(Map<String, dynamic> map) {
    return RouterRadioSettings(
      isEnabled: map['isEnabled'] as bool,
      mode: map['mode'] as String,
      ssid: map['ssid'] as String,
      broadcastSSID: map['broadcastSSID'] as bool,
      channelWidth: map['channelWidth'] as String,
      channel: map['channel'] as int,
      security: map['security'] as String,
      wepSettings: map['wepSettings'] != null
          ? WepSettings.fromMap(map['wepSettings'] as Map<String, dynamic>)
          : null,
      wpaPersonalSettings: map['wpaPersonalSettings'] != null
          ? WpaPersonalSettings.fromMap(
              map['wpaPersonalSettings'] as Map<String, dynamic>)
          : null,
      wpaEnterpriseSettings: map['wpaEnterpriseSettings'] != null
          ? WpaEnterpriseSettings.fromMap(
              map['wpaEnterpriseSettings'] as Map<String, dynamic>)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RouterRadioSettings.fromJson(String source) =>
      RouterRadioSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      isEnabled,
      mode,
      ssid,
      broadcastSSID,
      channelWidth,
      channel,
      security,
      wepSettings,
      wpaPersonalSettings,
      wpaEnterpriseSettings,
    ];
  }
}

class WepSettings extends Equatable {
  final String encryption;
  final String key1;
  final String key2;
  final String key3;
  final String key4;
  final int txKey;

  const WepSettings({
    required this.encryption,
    required this.key1,
    required this.key2,
    required this.key3,
    required this.key4,
    required this.txKey,
  });

  WepSettings copyWith({
    String? encryption,
    String? key1,
    String? key2,
    String? key3,
    String? key4,
    int? txKey,
  }) {
    return WepSettings(
      encryption: encryption ?? this.encryption,
      key1: key1 ?? this.key1,
      key2: key2 ?? this.key2,
      key3: key3 ?? this.key3,
      key4: key4 ?? this.key4,
      txKey: txKey ?? this.txKey,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'encryption': encryption,
      'key1': key1,
      'key2': key2,
      'key3': key3,
      'key4': key4,
      'txKey': txKey,
    };
  }

  factory WepSettings.fromMap(Map<String, dynamic> map) {
    return WepSettings(
      encryption: map['encryption'] as String,
      key1: map['key1'] as String,
      key2: map['key2'] as String,
      key3: map['key3'] as String,
      key4: map['key4'] as String,
      txKey: map['txKey'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory WepSettings.fromJson(String source) =>
      WepSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props {
    return [
      encryption,
      key1,
      key2,
      key3,
      key4,
      txKey,
    ];
  }
}

class WpaPersonalSettings extends Equatable {
  final String passphrase;

  const WpaPersonalSettings({
    required this.passphrase,
  });

  WpaPersonalSettings copyWith({
    String? passphrase,
  }) {
    return WpaPersonalSettings(
      passphrase: passphrase ?? this.passphrase,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'passphrase': passphrase,
    };
  }

  factory WpaPersonalSettings.fromMap(Map<String, dynamic> map) {
    return WpaPersonalSettings(
      passphrase: map['passphrase'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory WpaPersonalSettings.fromJson(String source) =>
      WpaPersonalSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [passphrase];
}

class WpaEnterpriseSettings extends Equatable {
  final String radiusServer;
  final int radiusPort;
  final String sharedKey;

  const WpaEnterpriseSettings({
    required this.radiusServer,
    required this.radiusPort,
    required this.sharedKey,
  });

  WpaEnterpriseSettings copyWith({
    String? radiusServer,
    int? radiusPort,
    String? sharedKey,
  }) {
    return WpaEnterpriseSettings(
      radiusServer: radiusServer ?? this.radiusServer,
      radiusPort: radiusPort ?? this.radiusPort,
      sharedKey: sharedKey ?? this.sharedKey,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radiusServer': radiusServer,
      'radiusPort': radiusPort,
      'sharedKey': sharedKey,
    };
  }

  factory WpaEnterpriseSettings.fromMap(Map<String, dynamic> map) {
    return WpaEnterpriseSettings(
      radiusServer: map['radiusServer'] as String,
      radiusPort: map['radiusPort'] as int,
      sharedKey: map['sharedKey'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory WpaEnterpriseSettings.fromJson(String source) =>
      WpaEnterpriseSettings.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [radiusServer, radiusPort, sharedKey];
}

class SupportedChannelsForChannelWidths extends Equatable {
  final String channelWidth;
  final List<int> channels;

  const SupportedChannelsForChannelWidths({
    required this.channelWidth,
    required this.channels,
  });

  SupportedChannelsForChannelWidths copyWith({
    String? channelWidth,
    List<int>? channels,
  }) {
    return SupportedChannelsForChannelWidths(
      channelWidth: channelWidth ?? this.channelWidth,
      channels: channels ?? this.channels,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'channelWidth': channelWidth,
      'channels': channels,
    };
  }

  factory SupportedChannelsForChannelWidths.fromMap(Map<String, dynamic> map) {
    return SupportedChannelsForChannelWidths(
      channelWidth: map['channelWidth'] as String,
      channels: List<int>.from((map['channels'] as List<dynamic>)),
    );
  }

  String toJson() => json.encode(toMap());

  factory SupportedChannelsForChannelWidths.fromJson(String source) =>
      SupportedChannelsForChannelWidths.fromMap(
          json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [channelWidth, channels];
}

class RouterRadioInfoSettings extends Equatable {
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

  @override
  List<Object?> get props => [
        broadcastSSID,
        ssid,
        isEnabled,
        security,
        channel,
        wpaPersonalSettings,
        channelWidth,
        mode,
      ];

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
    }..removeWhere((key, value) => value == null);
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
      isEnabled: isEnable ?? isEnabled,
      security: security ?? this.security,
      channel: channel ?? this.channel,
      wpaPersonalSettings: wpaPersonalSettings ?? this.wpaPersonalSettings,
      channelWidth: channelWidth ?? this.channelWidth,
      mode: mode ?? this.mode,
    );
  }
}

class RouterWPAPersonalSettings extends Equatable {
  final String passphrase;

  const RouterWPAPersonalSettings({
    required this.passphrase,
  });

  @override
  List<Object?> get props => [
        passphrase,
      ];

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
    }..removeWhere((key, value) => value == null);
  }

  factory RouterWPAPersonalSettings.fromJson(Map<String, dynamic> json) {
    return RouterWPAPersonalSettings(
      passphrase: json['passphrase'],
    );
  }
}
