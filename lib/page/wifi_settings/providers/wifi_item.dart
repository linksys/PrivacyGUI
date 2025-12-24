// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_enums.dart';

export 'package:privacy_gui/page/wifi_settings/models/wifi_enums.dart';

class WiFiItem extends Equatable {
  final WifiRadioBand radioID;
  final String ssid;
  final String password;
  final WifiSecurityType securityType;
  final WifiWirelessMode wirelessMode;
  final WifiWirelessMode? defaultMixedMode;
  final WifiChannelWidth channelWidth;
  final int channel;
  final bool isBroadcast;
  final bool isEnabled;
  final List<WifiSecurityType> availableSecurityTypes;
  final List<WifiWirelessMode> availableWirelessModes;
  final Map<WifiChannelWidth, List<int>> availableChannels;
  final int numOfDevices;

  const WiFiItem({
    required this.radioID,
    required this.ssid,
    required this.password,
    required this.securityType,
    required this.wirelessMode,
    this.defaultMixedMode,
    required this.channelWidth,
    required this.channel,
    required this.isBroadcast,
    required this.isEnabled,
    required this.availableSecurityTypes,
    required this.availableWirelessModes,
    required this.availableChannels,
    required this.numOfDevices,
  });

  WiFiItem copyWith({
    WifiType? wifiType,
    WifiRadioBand? radioID,
    String? ssid,
    String? password,
    WifiSecurityType? securityType,
    WifiWirelessMode? wirelessMode,
    WifiWirelessMode? defaultMixedMode,
    WifiChannelWidth? channelWidth,
    int? channel,
    bool? isBroadcast,
    bool? isEnabled,
    List<WifiSecurityType>? availableSecurityTypes,
    List<WifiWirelessMode>? availableWirelessModes,
    Map<WifiChannelWidth, List<int>>? availableChannels,
    int? numOfDevices,
  }) {
    return WiFiItem(
      radioID: radioID ?? this.radioID,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      securityType: securityType ?? this.securityType,
      wirelessMode: wirelessMode ?? this.wirelessMode,
      defaultMixedMode: defaultMixedMode ?? this.defaultMixedMode,
      channelWidth: channelWidth ?? this.channelWidth,
      channel: channel ?? this.channel,
      isBroadcast: isBroadcast ?? this.isBroadcast,
      isEnabled: isEnabled ?? this.isEnabled,
      availableSecurityTypes:
          availableSecurityTypes ?? this.availableSecurityTypes,
      availableWirelessModes:
          availableWirelessModes ?? this.availableWirelessModes,
      availableChannels: availableChannels ?? this.availableChannels,
      numOfDevices: numOfDevices ?? this.numOfDevices,
    );
  }

  @override
  bool get stringify => true;

  @override
  List<Object?> get props {
    return [
      radioID,
      ssid,
      password,
      securityType,
      wirelessMode,
      defaultMixedMode,
      channelWidth,
      channel,
      isBroadcast,
      isEnabled,
      availableSecurityTypes,
      availableWirelessModes,
      availableChannels,
      numOfDevices,
    ];
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'radioID': radioID.value,
      'ssid': ssid,
      'password': password,
      'securityType': securityType.value,
      'wirelessMode': wirelessMode.value,
      'defaultMixedMode': defaultMixedMode?.value,
      'channelWidth': channelWidth.value,
      'channel': channel,
      'isBroadcast': isBroadcast,
      'isEnabled': isEnabled,
      'availableSecurityTypes':
          availableSecurityTypes.map((x) => x.value).toList(),
      'availableWirelessModes':
          availableWirelessModes.map((x) => x.value).toList(),
      'availableChannels':
          availableChannels.map((key, value) => MapEntry(key.value, value)),
      'numOfDevices': numOfDevices,
    };
  }

  factory WiFiItem.fromMap(Map<String, dynamic> map) {
    final availableChannels = map['availableChannels'] != null
        ? (map['availableChannels'] as Map).map(
            (key, value) => MapEntry(
                WifiChannelWidth.getByValue(key), List<int>.from(value)),
          )
        : <WifiChannelWidth, List<int>>{};
    final availableWirelessModes = map['availableWirelessModes'] != null
        ? (map['availableWirelessModes'] as List)
            .map<WifiWirelessMode>((x) => WifiWirelessMode.getByValue(x))
            .toList()
        : <WifiWirelessMode>[];
    final availableSecurityTypes = map['availableSecurityTypes'] != null
        ? (map['availableSecurityTypes'] as List)
            .map<WifiSecurityType>(
              (x) => WifiSecurityType.getByValue(x),
            )
            .toList()
        : <WifiSecurityType>[];
    return WiFiItem(
      radioID: map['radioID'] != null
          ? WifiRadioBand.getByValue(map['radioID'] as String)
          : WifiRadioBand.radio_24,
      ssid: map['ssid'] != null ? map['ssid'] as String : '',
      password: map['password'] != null ? map['password'] as String : '',
      securityType: map['securityType'] != null
          ? WifiSecurityType.getByValue(map['securityType'] as String)
          : WifiSecurityType.open,
      wirelessMode: map['wirelessMode'] != null
          ? WifiWirelessMode.getByValue(map['wirelessMode'] as String)
          : WifiWirelessMode.ac,
      defaultMixedMode: map['defaultMixedMode'] != null
          ? WifiWirelessMode.getByValue(map['defaultMixedMode'] as String)
          : null,
      channelWidth: map['channelWidth'] != null
          ? WifiChannelWidth.getByValue(map['channelWidth'] as String)
          : WifiChannelWidth.auto,
      channel: map['channel'] as int,
      isBroadcast: map['isBroadcast'] as bool,
      isEnabled: map['isEnabled'] as bool,
      availableSecurityTypes: availableSecurityTypes,
      availableWirelessModes: availableWirelessModes,
      availableChannels: availableChannels,
      numOfDevices: map['numOfDevices'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory WiFiItem.fromJson(String source) =>
      WiFiItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
