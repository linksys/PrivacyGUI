import 'package:equatable/equatable.dart';

/// UI model representing a single WiFi network (SSID + AccessPoint + Radio combined).
///
/// Created by [UspWifiSettingsService] by cross-referencing:
///   - Device.WiFi.SSID.{i}          → ssid, enable, ssidAdvertisementEnabled
///   - Device.WiFi.AccessPoint.{i}   → securityMode, keyPassphrase, macAddressControlEnabled
///   - Device.WiFi.Radio.{i}         → band, channel, channelBandwidth, autoChannelEnable
class WifiNetworkUIModel extends Equatable {
  /// SSID instance path (e.g. "Device.WiFi.SSID.1.") — used for mutations
  final String ssidInstancePath;

  /// AccessPoint instance path (e.g. "Device.WiFi.AccessPoint.1.") — used for mutations
  final String? accessPointInstancePath;

  /// Radio instance path (e.g. "Device.WiFi.Radio.1.") — used for mutations
  final String? radioInstancePath;

  final String ssid;
  final bool enabled;
  final bool ssidAdvertisementEnabled;

  /// Security mode string (e.g. "WPA2-Personal", "WPA3-Personal", "None")
  final String securityMode;

  /// Passphrase — empty string if open security
  final String keyPassphrase;

  /// Whether MAC address control (allow-list) is enabled on this AP
  final bool macAddressControlEnabled;

  /// Frequency band (e.g. "2.4GHz", "5GHz", "6GHz")
  final String band;

  /// Current channel number (0 = auto)
  final int channel;

  /// Channel bandwidth (e.g. "Auto", "20MHz", "40MHz", "80MHz", "160MHz")
  final String channelBandwidth;

  /// Whether automatic channel selection is enabled
  final bool autoChannelEnable;

  const WifiNetworkUIModel({
    required this.ssidInstancePath,
    this.accessPointInstancePath,
    this.radioInstancePath,
    required this.ssid,
    required this.enabled,
    required this.ssidAdvertisementEnabled,
    required this.securityMode,
    required this.keyPassphrase,
    required this.macAddressControlEnabled,
    required this.band,
    required this.channel,
    required this.channelBandwidth,
    required this.autoChannelEnable,
  });

  /// Display name for the band tab/header
  String get bandDisplayName {
    if (band.contains('6')) return '6 GHz';
    if (band.contains('5')) return '5 GHz';
    if (band.contains('2.4')) return '2.4 GHz';
    return band.isNotEmpty ? band : 'Unknown';
  }

  /// True if this network uses an open (no password) security mode
  bool get isOpenSecurity =>
      securityMode == 'None' ||
      securityMode.isEmpty ||
      securityMode == 'Enhanced-Open-Only';

  /// Channel display string ("Auto" if autoChannelEnable, else the channel number)
  String get channelDisplay => autoChannelEnable ? 'Auto' : channel.toString();

  WifiNetworkUIModel copyWith({
    String? ssidInstancePath,
    String? accessPointInstancePath,
    String? radioInstancePath,
    String? ssid,
    bool? enabled,
    bool? ssidAdvertisementEnabled,
    String? securityMode,
    String? keyPassphrase,
    bool? macAddressControlEnabled,
    String? band,
    int? channel,
    String? channelBandwidth,
    bool? autoChannelEnable,
  }) {
    return WifiNetworkUIModel(
      ssidInstancePath: ssidInstancePath ?? this.ssidInstancePath,
      accessPointInstancePath:
          accessPointInstancePath ?? this.accessPointInstancePath,
      radioInstancePath: radioInstancePath ?? this.radioInstancePath,
      ssid: ssid ?? this.ssid,
      enabled: enabled ?? this.enabled,
      ssidAdvertisementEnabled:
          ssidAdvertisementEnabled ?? this.ssidAdvertisementEnabled,
      securityMode: securityMode ?? this.securityMode,
      keyPassphrase: keyPassphrase ?? this.keyPassphrase,
      macAddressControlEnabled:
          macAddressControlEnabled ?? this.macAddressControlEnabled,
      band: band ?? this.band,
      channel: channel ?? this.channel,
      channelBandwidth: channelBandwidth ?? this.channelBandwidth,
      autoChannelEnable: autoChannelEnable ?? this.autoChannelEnable,
    );
  }

  @override
  List<Object?> get props => [
        ssidInstancePath,
        accessPointInstancePath,
        radioInstancePath,
        ssid,
        enabled,
        ssidAdvertisementEnabled,
        securityMode,
        keyPassphrase,
        macAddressControlEnabled,
        band,
        channel,
        channelBandwidth,
        autoChannelEnable,
      ];

  Map<String, dynamic> toMap() => {
        'ssidInstancePath': ssidInstancePath,
        'accessPointInstancePath': accessPointInstancePath,
        'radioInstancePath': radioInstancePath,
        'ssid': ssid,
        'enabled': enabled,
        'ssidAdvertisementEnabled': ssidAdvertisementEnabled,
        'securityMode': securityMode,
        'keyPassphrase': keyPassphrase,
        'macAddressControlEnabled': macAddressControlEnabled,
        'band': band,
        'channel': channel,
        'channelBandwidth': channelBandwidth,
        'autoChannelEnable': autoChannelEnable,
      };

  Map<String, dynamic> toJson() => toMap();

  factory WifiNetworkUIModel.fromMap(Map<String, dynamic> map) =>
      WifiNetworkUIModel(
        ssidInstancePath: map['ssidInstancePath'] as String,
        accessPointInstancePath: map['accessPointInstancePath'] as String?,
        radioInstancePath: map['radioInstancePath'] as String?,
        ssid: map['ssid'] as String? ?? '',
        enabled: map['enabled'] as bool? ?? false,
        ssidAdvertisementEnabled:
            map['ssidAdvertisementEnabled'] as bool? ?? true,
        securityMode: map['securityMode'] as String? ?? '',
        keyPassphrase: map['keyPassphrase'] as String? ?? '',
        macAddressControlEnabled:
            map['macAddressControlEnabled'] as bool? ?? false,
        band: map['band'] as String? ?? '',
        channel: map['channel'] as int? ?? 0,
        channelBandwidth: map['channelBandwidth'] as String? ?? '',
        autoChannelEnable: map['autoChannelEnable'] as bool? ?? true,
      );

  factory WifiNetworkUIModel.fromJson(Map<String, dynamic> json) =>
      WifiNetworkUIModel.fromMap(json);
}
