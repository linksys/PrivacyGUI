// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';

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

  factory WiFiItem.fromRadio(RouterRadio radio, {int numOfDevices = 0}) {
    return WiFiItem(
      radioID: WifiRadioBand.getByValue(radio.radioID),
      ssid: radio.settings.ssid,
      password: radio.settings.wpaPersonalSettings?.passphrase ?? '',
      securityType: WifiSecurityType.getByValue(radio.settings.security),
      wirelessMode: WifiWirelessMode.getByValue(radio.settings.mode),
      defaultMixedMode: radio.defaultMixedMode != null
          ? WifiWirelessMode.getByValue(radio.defaultMixedMode!)
          : null,
      channelWidth: WifiChannelWidth.getByValue(radio.settings.channelWidth),
      channel: radio.settings.channel,
      isBroadcast: radio.settings.broadcastSSID,
      isEnabled: radio.settings.isEnabled,
      availableSecurityTypes: radio.supportedSecurityTypes
          .map((e) => WifiSecurityType.getByValue(e))
          //Remove "WEP" and "WPA-Enterprise" types from UI for now
          .where((e) => e.isOpenVariant || e.isWpaPersonalVariant)
          .toList(),
      availableWirelessModes: radio.supportedModes
          .map((e) => WifiWirelessMode.getByValue(e))
          .toList(),
      availableChannels:
          Map.fromIterable(radio.supportedChannelsForChannelWidths, key: (e) {
        final channelWidth =
            (e as SupportedChannelsForChannelWidths).channelWidth;
        return WifiChannelWidth.getByValue(channelWidth);
      }, value: ((e) {
        return (e as SupportedChannelsForChannelWidths).channels;
      })),
      numOfDevices: numOfDevices,
    );
  }

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
      'availableChannels': availableChannels,
      'numOfDevices': numOfDevices,
    };
  }

  factory WiFiItem.fromMap(Map<String, dynamic> map) {
    return WiFiItem(
      radioID: WifiRadioBand.getByValue(map['radioID'] as String),
      ssid: map['ssid'] as String,
      password: map['password'] as String,
      securityType: WifiSecurityType.getByValue(map['securityType']),
      wirelessMode: WifiWirelessMode.getByValue(map['wirelessMode']),
      defaultMixedMode: map['defaultMixedMode'] != null
          ? WifiWirelessMode.getByValue(map['defaultMixedMode'])
          : null,
      channelWidth: WifiChannelWidth.getByValue(map['channelWidth']),
      channel: map['channel'] as int,
      isBroadcast: map['isBroadcast'] as bool,
      isEnabled: map['isEnabled'] as bool,
      availableSecurityTypes: List<WifiSecurityType>.from(
        (map['availableSecurityTypes'] as List).map<WifiSecurityType>(
          (x) => WifiSecurityType.getByValue(x),
        ),
      ),
      availableWirelessModes: List<WifiWirelessMode>.from(
        (map['availableWirelessModes'] as List)
            .map<WifiWirelessMode>((x) => WifiWirelessMode.getByValue(x)),
      ),
      availableChannels: Map<WifiChannelWidth, List<int>>.from(
          (map['availableChannels'] as Map<WifiChannelWidth, List<int>>)),
      numOfDevices: map['numOfDevices'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory WiFiItem.fromJson(String source) =>
      WiFiItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

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
    return WifiRadioBand.values.firstWhere((item) => item.value == value);
  }
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
    return WifiSecurityType.values.firstWhere((item) => item.value == value);
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
  a(value: '802.11a'),
  b(value: '802.11b'),
  g(value: '802.11g'),
  n(value: '802.11n'),
  ac(value: '802.11ac'),
  ax(value: '802.11ax'),
  an(value: '802.11an'),
  bg(value: '802.11bg'),
  bn(value: '802.11bn'),
  gn(value: '802.11gn'),
  anac(value: '802.11anac'),
  anacax(value: '802.11anacax'),
  anacaxbe(value: '802.11anacaxbe'),
  bgn(value: '802.11bgn'),
  bgnac(value: '802.11bgnac'),
  bgnax(value: '802.11bgnax'),
  axbe(value: '802.11axbe'),
  mixed(value: '802.11mixed');

  const WifiWirelessMode({
    required this.value,
  });

  final String value;

  static WifiWirelessMode getByValue(String value) {
    return WifiWirelessMode.values.firstWhere((item) => item.value == value);
  }

  bool get isIncludeBeMixedMode => this == axbe || this == anacaxbe;
}

enum WifiChannelWidth {
  auto(value: 'Auto'),
  wide20(value: 'Standard'),
  wide40(value: 'Wide'),
  wide80(value: 'Wide80'),
  wide160c(value: 'Wide160c'),
  wide160nc(value: 'Wide160nc');

  const WifiChannelWidth({
    required this.value,
  });

  final String value;

  static WifiChannelWidth getByValue(String value) {
    return WifiChannelWidth.values.firstWhere((item) => item.value == value);
  }
}
