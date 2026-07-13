import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation Layer Model for a WiFi radio with its access points.
class WifiRadioUIModel extends Equatable with DiagnosticLoggable {
  final String instancePath;
  final String band; // "2.4GHz", "5GHz", "6GHz"
  final bool enable;
  final int transmitPower; // -1 means max
  final int maxBitRate; // Mbps
  final int channel;
  final bool autoChannelEnable;
  final String channelBandwidth;
  final String supportedStandards;

  /// Manually-selectable channels for this radio's band, sorted ascending.
  ///
  /// Sourced from `Device.WiFi.Radio.{i}.PossibleChannels` during the
  /// dashboard data fetch ([UspWifiDataService.fetch]), so the edit-channel
  /// dialog can render its dropdown synchronously with no per-dialog fetch.
  /// Empty when the band exposes no manual channels.
  ///
  /// NOTE: this list is RAW — it is NOT DFS-filtered. On the dashboard path,
  /// DFS (IEEE 802.11h) channels are hidden at display time in
  /// [WifiChannelDialog] via `filterDfsChannels` keyed off [isDfsEnabled]. (The
  /// WiFi Settings path pre-filters instead, in
  /// `UspWifiSettingsService.buildWifiNetworks`, before building bandwidth
  /// maps.) Any new consumer needing DFS-off filtering must call
  /// `filterDfsChannels` itself.
  final List<int> possibleChannels;

  /// Per-radio DFS (IEEE 802.11h) enabled state, from
  /// `Device.WiFi.Radio.{i}.IEEE80211hEnabled`. When false, 5 GHz DFS channels
  /// must be hidden from the channel dropdown.
  final bool isDfsEnabled;

  /// Access points grouped under this radio.
  final List<WifiAccessPointUIModel> accessPoints;

  const WifiRadioUIModel({
    required this.instancePath,
    required this.band,
    required this.enable,
    required this.transmitPower,
    required this.maxBitRate,
    required this.channel,
    required this.autoChannelEnable,
    required this.channelBandwidth,
    required this.supportedStandards,
    this.possibleChannels = const [],
    this.isDfsEnabled = false,
    this.accessPoints = const [],
  });

  /// Tx power display: "Max" if -1, otherwise "X%".
  int get txPowerPercent =>
      transmitPower == -1 ? 100 : transmitPower.clamp(0, 100);

  String get txPowerDisplay => transmitPower == -1 ? 'Max' : '$txPowerPercent%';

  /// Channel display: "6 (Auto)" or "6".
  String get channelDisplay => '$channel${autoChannelEnable ? ' (Auto)' : ''}';

  /// Bit rate normalized to 0–100 scale based on band max.
  double get bitRateNormalized {
    final maxForBand = band.contains('6')
        ? 9600
        : band.contains('5')
            ? 4800
            : 600;
    return (maxBitRate / maxForBand * 100).clamp(0, 100).toDouble();
  }

  @override
  String get diagnosticName => 'WifiRadioUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'instancePath': instancePath,
        'band': band,
        'enable': enable,
        'transmitPower': transmitPower,
        'maxBitRate': maxBitRate,
        'channel': channel,
        'autoChannelEnable': autoChannelEnable,
        'channelBandwidth': channelBandwidth,
        'supportedStandards': supportedStandards,
        'possibleChannels': possibleChannels,
        'isDfsEnabled': isDfsEnabled,
        'accessPoints': accessPoints,
      };
}

/// Presentation Layer Model for a WiFi access point.
class WifiAccessPointUIModel extends Equatable with DiagnosticLoggable {
  final bool enable;
  final String ssidName; // Resolved from SSID reference
  final String securityMode;
  final String encryptionMode;
  final bool isGuest;

  /// TR-181 instance path of the AccessPoint (e.g. Device.WiFi.AccessPoint.2.).
  /// Needed by the Dashboard per-network toggle to mutate AccessPoint.Enable.
  final String accessPointInstancePath;

  /// TR-181 instance path of the SSID this AP serves (e.g. Device.WiFi.SSID.2.).
  /// Needed by the Dashboard per-network toggle to mutate SSID.Enable.
  final String ssidInstancePath;

  const WifiAccessPointUIModel({
    required this.enable,
    required this.ssidName,
    required this.securityMode,
    required this.encryptionMode,
    this.isGuest = false,
    this.accessPointInstancePath = '',
    this.ssidInstancePath = '',
  });

  @override
  String get diagnosticName => 'WifiAccessPointUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'enable': enable,
        'ssidName': ssidName,
        'securityMode': securityMode,
        'encryptionMode': encryptionMode,
        'isGuest': isGuest,
        'accessPointInstancePath': accessPointInstancePath,
        'ssidInstancePath': ssidInstancePath,
      };
}
