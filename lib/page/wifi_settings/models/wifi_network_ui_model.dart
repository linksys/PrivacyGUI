import 'package:equatable/equatable.dart';

/// UI model representing a single WiFi network (SSID + AccessPoint + Radio combined).
///
/// Created by [UspWifiSettingsService] by cross-referencing:
///   - Device.WiFi.SSID.{i}          → ssid, enable, ssidAdvertisementEnabled
///   - Device.WiFi.AccessPoint.{i}   → securityMode, keyPassphrase
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

  /// Security modes supported by this AP (from Security.ModesSupported).
  /// Used to populate the security mode dropdown.
  final List<String> supportedSecurityModes;

  /// Security mode string (e.g. "WPA2-Personal", "WPA3-Personal", "None")
  final String securityMode;

  /// Passphrase — empty string if open security
  final String keyPassphrase;

  /// Whether this network is a guest network.
  ///
  /// Detected via SSID naming convention (contains "guest", case-insensitive).
  // TODO(vendor-ext): Replace with Device.WiFi.SSID.{i}.X_LINKSYS_COM_IsGuest
  //   once firmware support is confirmed.
  final bool isGuest;

  /// Frequency band (e.g. "2.4GHz", "5GHz", "6GHz")
  final String band;

  /// Current channel number (0 = auto)
  final int channel;

  /// Channel bandwidth (e.g. "Auto", "20MHz", "40MHz", "80MHz", "160MHz")
  final String channelBandwidth;

  /// Whether automatic channel selection is enabled
  final bool autoChannelEnable;

  /// Available channel numbers from Device.WiFi.Radio.{i}.PossibleChannels.
  /// Empty list means the router did not return this data.
  final List<int> possibleChannels;

  /// Currently active WiFi standards (Device.WiFi.Radio.{i}.OperatingStandards).
  /// e.g. "a,n,ac,ax" — writable.
  final String operatingStandards;

  /// All standards this radio supports (Device.WiFi.Radio.{i}.SupportedStandards).
  /// e.g. "a,n,ac,ax" — read-only, used to derive available options.
  final String supportedStandards;

  /// Supported channel bandwidths from Device.WiFi.Radio.{i}.SupportedOperatingChannelBandwidths.
  /// e.g. ['Auto', '20MHz', '40MHz', '80MHz']. Empty list = firmware didn't provide data.
  final List<String> supportedBandwidths;

  /// Channels available for each bandwidth, computed from possibleChannels
  /// using IEEE 802.11 bonding rules.
  /// Key = bandwidth string ("Auto", "20MHz", "40MHz", etc.)
  /// Value = sorted list of valid primary channel numbers.
  /// Empty map = bonding data not computed (fallback to possibleChannels).
  final Map<String, List<int>> availableChannelsPerBandwidth;

  const WifiNetworkUIModel({
    required this.ssidInstancePath,
    this.accessPointInstancePath,
    this.radioInstancePath,
    required this.ssid,
    required this.enabled,
    required this.ssidAdvertisementEnabled,
    required this.supportedSecurityModes,
    required this.securityMode,
    required this.keyPassphrase,
    required this.isGuest,
    required this.band,
    required this.channel,
    required this.channelBandwidth,
    required this.autoChannelEnable,
    required this.possibleChannels,
    required this.operatingStandards,
    required this.supportedStandards,
    this.supportedBandwidths = const [],
    this.availableChannelsPerBandwidth = const {},
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
      securityMode == 'Enhanced-Open';

  /// Channel display string ("Auto" if autoChannelEnable, else the channel number)
  String get channelDisplay => autoChannelEnable ? 'Auto' : channel.toString();

  WifiNetworkUIModel copyWith({
    String? ssidInstancePath,
    String? accessPointInstancePath,
    String? radioInstancePath,
    String? ssid,
    bool? enabled,
    bool? ssidAdvertisementEnabled,
    List<String>? supportedSecurityModes,
    String? securityMode,
    String? keyPassphrase,
    bool? isGuest,
    String? band,
    int? channel,
    String? channelBandwidth,
    bool? autoChannelEnable,
    List<int>? possibleChannels,
    String? operatingStandards,
    String? supportedStandards,
    List<String>? supportedBandwidths,
    Map<String, List<int>>? availableChannelsPerBandwidth,
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
      supportedSecurityModes:
          supportedSecurityModes ?? this.supportedSecurityModes,
      securityMode: securityMode ?? this.securityMode,
      keyPassphrase: keyPassphrase ?? this.keyPassphrase,
      isGuest: isGuest ?? this.isGuest,
      band: band ?? this.band,
      channel: channel ?? this.channel,
      channelBandwidth: channelBandwidth ?? this.channelBandwidth,
      autoChannelEnable: autoChannelEnable ?? this.autoChannelEnable,
      possibleChannels: possibleChannels ?? this.possibleChannels,
      operatingStandards: operatingStandards ?? this.operatingStandards,
      supportedStandards: supportedStandards ?? this.supportedStandards,
      supportedBandwidths: supportedBandwidths ?? this.supportedBandwidths,
      availableChannelsPerBandwidth:
          availableChannelsPerBandwidth ?? this.availableChannelsPerBandwidth,
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
        supportedSecurityModes,
        securityMode,
        keyPassphrase,
        isGuest,
        band,
        channel,
        channelBandwidth,
        autoChannelEnable,
        possibleChannels,
        operatingStandards,
        supportedStandards,
        supportedBandwidths,
        availableChannelsPerBandwidth,
      ];

  Map<String, dynamic> toMap() => {
        'ssidInstancePath': ssidInstancePath,
        'accessPointInstancePath': accessPointInstancePath,
        'radioInstancePath': radioInstancePath,
        'ssid': ssid,
        'enabled': enabled,
        'ssidAdvertisementEnabled': ssidAdvertisementEnabled,
        'supportedSecurityModes': supportedSecurityModes,
        'securityMode': securityMode,
        'keyPassphrase': keyPassphrase,
        'isGuest': isGuest,
        'band': band,
        'channel': channel,
        'channelBandwidth': channelBandwidth,
        'autoChannelEnable': autoChannelEnable,
        'possibleChannels': possibleChannels,
        'operatingStandards': operatingStandards,
        'supportedStandards': supportedStandards,
        'supportedBandwidths': supportedBandwidths,
        'availableChannelsPerBandwidth': availableChannelsPerBandwidth,
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
        supportedSecurityModes:
            (map['supportedSecurityModes'] as List?)?.cast<String>() ?? [],
        securityMode: map['securityMode'] as String? ?? '',
        keyPassphrase: map['keyPassphrase'] as String? ?? '',
        isGuest: map['isGuest'] as bool? ?? false,
        band: map['band'] as String? ?? '',
        channel: map['channel'] as int? ?? 0,
        channelBandwidth: map['channelBandwidth'] as String? ?? '',
        autoChannelEnable: map['autoChannelEnable'] as bool? ?? true,
        possibleChannels: (map['possibleChannels'] as List?)?.cast<int>() ?? [],
        operatingStandards: map['operatingStandards'] as String? ?? '',
        supportedStandards: map['supportedStandards'] as String? ?? '',
        supportedBandwidths:
            (map['supportedBandwidths'] as List?)?.cast<String>() ?? [],
        availableChannelsPerBandwidth:
            (map['availableChannelsPerBandwidth'] as Map?)?.map(
                  (k, v) => MapEntry(k as String, (v as List).cast<int>()),
                ) ??
                {},
      );

  factory WifiNetworkUIModel.fromJson(Map<String, dynamic> json) =>
      WifiNetworkUIModel.fromMap(json);
}
