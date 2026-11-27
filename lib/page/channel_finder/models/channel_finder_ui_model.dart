import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/utils/wifi_channel.dart';

/// Which part of a scan is running, for the progress text.
enum ChannelFinderScanStage {
  /// `NeighboringWiFiDiagnostic()`: listening for nearby networks.
  neighbors,

  /// `ChannelScanRequest()`, one radio after another: measuring how busy each
  /// channel is.
  channels,
}

/// One network the neighbour scan heard on a channel.
class ChannelNeighborUIModel extends Equatable {
  /// Network name; empty for a network that hides its name.
  final String ssid;

  /// MAC address of the network's access point.
  final String bssid;

  /// Signal strength as the router heard it, in dBm.
  final int signalDbm;

  const ChannelNeighborUIModel({
    required this.ssid,
    required this.bssid,
    required this.signalDbm,
  });

  @override
  List<Object?> get props => [ssid, bssid, signalDbm];
}

/// One channel of a band, as the two scans saw it (#1778).
class ChannelScanUIModel extends Equatable {
  final int channel;

  /// How busy the channel was, 0–255 where 255 is always busy; null when the
  /// channel scan did not measure this channel.
  ///
  /// Shown as reported. The firmware sends 10 for a channel it has no
  /// measurement for (a WFA certification workaround), and FW test image
  /// `2.0.4.26112521` sent 10 for a measured idle channel too, which
  /// linksys/targets#354 changes to 0 (#1778). A real reading can also be 10,
  /// so 10 is not taken to mean "unknown".
  final int? utilization;

  /// Whether the router's radio is on this channel now.
  final bool isInUse;

  /// The networks heard on this channel, strongest first.
  final List<ChannelNeighborUIModel> neighbors;

  const ChannelScanUIModel({
    required this.channel,
    required this.utilization,
    required this.isInUse,
    required this.neighbors,
  });

  /// [utilization] as a whole percentage, or null when unknown.
  int? get utilizationPercent => utilizationToPercent(utilization);

  /// Signal of the strongest network on this channel, or null when none.
  int? get strongestSignalDbm =>
      neighbors.isEmpty ? null : neighbors.first.signalDbm;

  @override
  List<Object?> get props => [channel, utilization, isInUse, neighbors];
}

/// One band's scan: every channel the radio may use there.
class ChannelBandScanUIModel extends Equatable {
  /// "2.4GHz", "5GHz" or "6GHz", as `Device.WiFi.Radio.{i}.OperatingFrequencyBand`.
  final String band;

  /// The channel the radio is on, or null when the router does not say.
  final int? channelInUse;

  /// The channels the radio may use, in channel order.
  final List<ChannelScanUIModel> channels;

  /// Whether the band's busyness was measured, and if not, why. The
  /// neighbours are there either way.
  final ChannelBandMeasurement measurement;

  const ChannelBandScanUIModel({
    required this.band,
    required this.channelInUse,
    required this.channels,
    this.measurement = ChannelBandMeasurement.measured,
  });

  /// [band] as an identifier slug: "2.4GHz" → "2-4ghz" (constitution
  /// Article XVI §16.3).
  String get identifierKey => band.toLowerCase().replaceAll('.', '-');

  /// [channel] of this band as an identifier slug: "5ghz-36". One expression,
  /// because the E2E identifier generator reads only `prefix-${expr}`.
  String channelIdentifierKey(ChannelScanUIModel channel) =>
      '$identifierKey-${channel.channel}';

  /// The row of the channel the radio is on, or null.
  ChannelScanUIModel? get inUse {
    for (final channel in channels) {
      if (channel.isInUse) return channel;
    }
    return null;
  }

  @override
  List<Object?> get props => [band, channelInUse, channels, measurement];
}

/// Whether one band's channel scan measured its channels (#1778).
enum ChannelBandMeasurement {
  /// The channel scan left a new result, and the busyness is from it.
  measured,

  /// The router did not measure the band: it refused the channel scan, or
  /// the radio is not one of the controller's DataElements radios. Scanning
  /// again is unlikely to help.
  refused,

  /// No result could be read: the stored results could not be read before
  /// the scan, or no new result arrived in time after it. Scanning again may
  /// help.
  unanswered,
}

/// The result of one Channel Finder scan.
class ChannelFinderResultUIModel extends Equatable {
  /// When the scan finished, by this device's clock.
  final DateTime scannedAt;

  /// One entry per radio that was scanned, 2.4 GHz first.
  final List<ChannelBandScanUIModel> bands;

  const ChannelFinderResultUIModel({
    required this.scannedAt,
    required this.bands,
  });

  @override
  List<Object?> get props => [scannedAt, bands];
}
