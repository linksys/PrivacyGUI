// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class WiFiItem extends Equatable {
  final WifiType wifiType;
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
    required this.wifiType,
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
      wifiType: wifiType ?? this.wifiType,
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
  List<Object> get props {
    return [
      wifiType,
      radioID,
      ssid,
      password,
      securityType,
      wirelessMode,
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
