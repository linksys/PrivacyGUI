import 'package:equatable/equatable.dart';
import 'package:linksys_app/core/jnap/models/guest_radio_settings.dart';
import 'package:linksys_app/core/jnap/models/radio_info.dart';
import 'package:linksys_app/core/utils/logger.dart';

class WifiSettingState extends Equatable {
  final WifiListItem selectedWifiItem;

  const WifiSettingState({
    this.selectedWifiItem = const WifiListItem(
        wifiType: WifiType.main,
        ssid: '',
        password: '',
        securityType: WifiSecurityType.wpa2Wpa3Mixed,
        mode: WifiMode.mixed,
        isWifiEnabled: false,
        numOfDevices: 0,
        signal: 0),
  });

  WifiSettingState copyWith({
    WifiListItem? selectedWifiItem,
  }) {
    return WifiSettingState(
      selectedWifiItem: selectedWifiItem ?? this.selectedWifiItem,
    );
  }

  @override
  List<Object?> get props => [
        selectedWifiItem,
      ];
}

class WifiListItem extends Equatable {
  final WifiType wifiType;
  final String ssid;
  final String password;
  final WifiSecurityType securityType;
  final WifiSecurityType? security6GType;
  final WifiMode mode;
  final String? band;
  final bool isWifiEnabled;
  final int numOfDevices;
  final int signal;

  const WifiListItem({
    required this.wifiType,
    required this.ssid,
    required this.password,
    required this.securityType,
    this.security6GType,
    required this.mode,
    this.band,
    required this.isWifiEnabled,
    required this.numOfDevices,
    required this.signal,
  });

  @override
  List<Object?> get props => [
        wifiType,
        ssid,
        password,
        securityType,
        security6GType,
        mode,
        band,
        isWifiEnabled,
        numOfDevices,
        signal,
      ];

  WifiListItem copyWith({
    WifiType? wifiType,
    String? ssid,
    String? password,
    WifiSecurityType? securityType,
    WifiSecurityType? security6GType,
    WifiMode? mode,
    String? band,
    bool? isWifiEnabled,
    int? numOfDevices,
    int? signal,
  }) {
    return WifiListItem(
      wifiType: wifiType ?? this.wifiType,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      securityType: securityType ?? this.securityType,
      security6GType: security6GType ?? this.security6GType,
      mode: mode ?? this.mode,
      band: band ?? this.band,
      isWifiEnabled: isWifiEnabled ?? this.isWifiEnabled,
      numOfDevices: numOfDevices ?? this.numOfDevices,
      signal: signal ?? this.signal,
    );
  }

  static WifiSecurityType convertToWifiSecurityType(String security) {
    switch (security) {
      case 'Enhanced-Open+None':
        return WifiSecurityType.openAndEnhancedOpen;
      case 'Enhanced-Open-Only':
        return WifiSecurityType.enhancedOpen;
      case 'None':
        return WifiSecurityType.open;
      case 'WPA2-Personal':
        return WifiSecurityType.wpa2;
      case 'WPA2/WPA3-Mixed-Personal':
        return WifiSecurityType.wpa2Wpa3Mixed;
      case 'WPA3-Personal':
        return WifiSecurityType.wpa3;
      default:
        logger.d('ERROR: convertToWifiSecurityType: security = $security');
        return WifiSecurityType.open;
    }
  }

  static WifiMode convertToWifiMode(String wifiMode) {
    switch (wifiMode) {
      case '802.11bg':
        return WifiMode.bg;
      case '802.11bgn':
        return WifiMode.bgn;
      case '802.11mixed':
        return WifiMode.mixed;
      default:
        logger.d('ERROR: convertToWifiMode: wifiMode = $wifiMode');
        return WifiMode.mixed;
    }
  }
}

enum WifiType {
  main(displayTitle: 'MAIN'),
  guest(displayTitle: 'GUEST');

  const WifiType({required this.displayTitle});

  final String displayTitle;

  List<WifiSettingOption> get settingOptions {
    List<WifiSettingOption> options = [
      WifiSettingOption.nameAndPassword,
    ];

    if (this == WifiType.main) {
      options.addAll([
        WifiSettingOption.securityType6G,
        WifiSettingOption.securityTypeBelow6G,
        WifiSettingOption.mode,
      ]);
    }

    return options;
  }
}

enum WifiSettingOption {
  nameAndPassword(displayTitle: 'WiFi name and password'),
  securityType(displayTitle: 'Security type'),
  securityType6G(displayTitle: 'Security type (6GHz)'),
  securityTypeBelow6G(displayTitle: 'Security type (5GHz, 2.4GHz)'),
  mode(displayTitle: 'WiFi mode');

  const WifiSettingOption({required this.displayTitle});

  final String displayTitle;
}

enum WifiSecurityType {
  wpa2(
    displayTitle: 'WPA2 Personal',
    value: 'WPA2-Personal',
  ),
  wpa3(
    displayTitle: 'WPA3 Personal',
    value: 'WPA3-Personal',
  ),
  wpa2Wpa3Mixed(
    displayTitle: 'WPA2/WPA3 Mixed Personal',
    value: 'WPA2/WPA3-Mixed-Personal',
  ),
  enhancedOpen(
    displayTitle: 'Enhanced Open Only',
    value: 'Enhanced-Open-Only',
  ),
  openAndEnhancedOpen(
    displayTitle: 'Open and Enhanced Open',
    value: 'Enhanced-Open+None',
  ),
  open(
    displayTitle: 'Open',
    value: 'None',
  );

  const WifiSecurityType({
    required this.displayTitle,
    required this.value,
  });

  final String displayTitle;
  final String value;

  static List<WifiSecurityType> get allTypes {
    return [
      WifiSecurityType.wpa2,
      WifiSecurityType.wpa3,
      WifiSecurityType.wpa2Wpa3Mixed,
      WifiSecurityType.enhancedOpen,
      WifiSecurityType.openAndEnhancedOpen,
      WifiSecurityType.open,
    ];
  }
}

enum WifiMode {
  mixed(value: 'Mixed'),
  bg(value: 'bg'),
  bgn(value: 'bgn');

  const WifiMode({required this.value});

  final String value;

  static List<WifiMode> get allModes {
    return [
      WifiMode.mixed,
      WifiMode.bg,
      WifiMode.bgn,
    ];
  }
}
