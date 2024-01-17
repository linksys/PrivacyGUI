// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/utils/logger.dart';

class WifiItem extends Equatable {
  final WifiType wifiType;
  final RadioID radioID;
  final String ssid;
  final String password;
  final WifiSecurityType securityType;
  final WifiWirelessMode wirelessMode;
  final WifiChannelWidth channelWidth;
  final int channel;
  final bool isBroadcast;
  final bool isEnabled;
  final int numOfDevices;

  const WifiItem({
    required this.wifiType,
    required this.radioID,
    required this.ssid,
    required this.password,
    required this.securityType,
    required this.wirelessMode,
    required this.channelWidth,
    required this.channel,
    required this.isBroadcast,
    required this.isEnabled,
    required this.numOfDevices,
  });

  WifiItem copyWith({
    WifiType? wifiType,
    RadioID? radioID,
    String? ssid,
    String? password,
    WifiSecurityType? securityType,
    WifiWirelessMode? wirelessMode,
    WifiChannelWidth? channelWidth,
    int? channel,
    bool? isBroadcast,
    bool? isEnabled,
    int? numOfDevices,
  }) {
    return WifiItem(
      wifiType: wifiType ?? this.wifiType,
      radioID: radioID ?? this.radioID,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      securityType: securityType ?? this.securityType,
      wirelessMode: wirelessMode ?? this.wirelessMode,
      channelWidth: channelWidth ?? this.channelWidth,
      channel: channel ?? this.channel,
      isBroadcast: isBroadcast ?? this.isBroadcast,
      isEnabled: isEnabled ?? this.isEnabled,
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
      numOfDevices,
    ];
  }
}

enum WifiType {
  main(displayTitle: 'MAIN'),
  guest(displayTitle: 'GUEST');

  const WifiType({required this.displayTitle});

  final String displayTitle;

  // List<WifiSettingOption> get settingOptions {
  //   List<WifiSettingOption> options = [
  //     WifiSettingOption.nameAndPassword,
  //   ];

  //   if (this == WifiType.main) {
  //     options.addAll([
  //       WifiSettingOption.securityType6G,
  //       WifiSettingOption.securityTypeBelow6G,
  //       WifiSettingOption.mode,
  //       WifiSettingOption.channelFinder
  //     ]);
  //   }

  //   return options;
  // }
}

// enum WifiSettingOption {
//   nameAndPassword(displayTitle: 'WiFi name and password'),
//   securityType(displayTitle: 'Security type'),
//   securityType6G(displayTitle: 'Security type (6GHz)'),
//   securityTypeBelow6G(displayTitle: 'Security type (5GHz, 2.4GHz)'),
//   mode(displayTitle: 'WiFi mode'),
//   channelFinder(displayTitle: 'Channel Finder');

//   const WifiSettingOption({required this.displayTitle});

//   final String displayTitle;
// }

enum RadioID {
  radio_24(value: 'RADIO_2.4GHz'),
  radio_5_1(value: 'RADIO_5GHz'),
  radio_5_2(value: 'RADIO_5GHz_2'),
  radio_6(value: 'RADIO_6GHz');

  const RadioID({
    required this.value,
  });

  final String value;

  static RadioID getByValue(String value) {
    return RadioID.values.firstWhere((item) => item.value == value);
  }
}

enum WifiSecurityType {
  open(
    value: 'None',
    displayTitle: 'Open',
  ),
  wep(
    value: 'WEP',
    displayTitle: 'WEP',
  ),
  wpaPersonal(
    value: 'WPA-Personal',
    displayTitle: 'WPA Personal',
  ),
  wpaEnterprise(
    value: 'WPA-Enterprise',
    displayTitle: 'WPA Enterprise',
  ),
  wpa2Personal(
    value: 'WPA2-Personal',
    displayTitle: 'WPA2 Personal',
  ),
  wpa2Enterprise(
    value: 'WPA2-Enterprise',
    displayTitle: 'WPA2 Enterprise',
  ),
  wpa1Or2MixedPersonal(
    value: 'WPA-Mixed-Personal',
    displayTitle: 'WPA/WPA2 Mixed Personal',
  ),
  wpa1Or2MixedEnterprise(
    value: 'WPA-Mixed-Enterprise',
    displayTitle: 'WPA/WPA2 Mixed Enterprise',
  ),
  wpa2Or3MixedPersonal(
    value: 'WPA2/WPA3-Mixed-Personal',
    displayTitle: 'WPA2/WPA3 Mixed Personal',
  ),
  wpa3Personal(
    value: 'WPA3-Personal',
    displayTitle: 'WPA3 Personal',
  ),
  wpa3Enterprise(
    value: 'WPA3-Enterprise',
    displayTitle: 'WPA3 Enterprise',
  ),
  enhancedOpenNone(
    value: 'Enhanced-Open+None',
    displayTitle: 'Open and Enhanced Open',
  ),
  enhancedOpenOnly(
    value: 'Enhanced-Open-Only',
    displayTitle: 'Enhanced Open Only',
  );

  const WifiSecurityType({
    required this.value,
    required this.displayTitle,
  });

  final String value;
  final String displayTitle;

  static WifiSecurityType getByValue(String value) {
    return WifiSecurityType.values.firstWhere((item) => item.value == value);
  }
}

enum WifiWirelessMode {
  a(
    value: '802.11a',
    displayTitle: '802.11a Only',
  ),
  b(
    value: '802.11b',
    displayTitle: '802.11b Only',
  ),
  g(
    value: '802.11g',
    displayTitle: '802.11g Only',
  ),
  n(
    value: '802.11n',
    displayTitle: '802.11n Only',
  ),
  ac(
    value: '802.11ac',
    displayTitle: '802.11ac Only',
  ),
  ax(
    value: '802.11ax',
    displayTitle: '802.11ax Only',
  ),
  an(
    value: '802.11an',
    displayTitle: '802.11a/n Only',
  ),
  bg(
    value: '802.11bg',
    displayTitle: '802.11b/g Only',
  ),
  bn(
    value: '802.11bn',
    displayTitle: '802.11b/n Only',
  ),
  gn(
    value: '802.11gn',
    displayTitle: '802.11g/n Only',
  ),
  anac(
    value: '802.11anac',
    displayTitle: '802.11a/n/ac Only',
  ),
  anacax(
    value: '802.11anacax',
    displayTitle: '802.11a/n/ac/ax Only',
  ),
  anacaxbe(
    value: '802.11anacaxbe',
    displayTitle: '802.11a/n/ac/ax/be Only',
  ),
  bgn(
    value: '802.11bgn',
    displayTitle: '802.11b/g/n Only',
  ),
  bgnac(
    value: '802.11bgnac',
    displayTitle: '802.11b/g/n/ac Only',
  ),
  bgnax(
    value: '802.11bgnax',
    displayTitle: '802.11b/g/n/ax Only',
  ),
  axbe(
    value: '802.11axbe',
    displayTitle: '802.11ax/be Only',
  ),
  mixed(
    value: '802.11mixed',
    displayTitle: 'Mixed',
  );

  const WifiWirelessMode({
    required this.value,
    required this.displayTitle,
  });

  final String value;
  final String displayTitle;

  static WifiWirelessMode getByValue(String value) {
    return WifiWirelessMode.values.firstWhere((item) => item.value == value);
  }
}

enum WifiChannelWidth {
  auto(
    value: 'Auto',
    displayTitle: 'Auto',
  ),
  wide20(
    value: 'Standard',
    displayTitle: '20 MHz Only',
  ),
  wide40(
    value: 'Wide',
    displayTitle: 'Up to 40 MHz',
  ),
  wide80(
    value: 'Wide80',
    displayTitle: 'Up to 80 MHz',
  ),
  wide160c(
    value: 'Wide160c',
    displayTitle: 'Contiguous 160 MHz',
  ),
  wide160nc(
    value: 'Wide160nc',
    displayTitle: 'Non-contiguous 160 MHz',
  );

  const WifiChannelWidth({
    required this.value,
    required this.displayTitle,
  });

  final String value;
  final String displayTitle;

  static WifiChannelWidth getByValue(String value) {
    return WifiChannelWidth.values.firstWhere((item) => item.value == value);
  }
}
