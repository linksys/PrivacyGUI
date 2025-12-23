import 'dart:convert';

import 'package:equatable/equatable.dart';

/// A data model representing the speed test results formatted for display in the UI.
class SpeedTestUIModel extends Equatable {
  /// The formatted download speed value (e.g., "89.5").
  final String downloadSpeed;

  /// The unit for the download speed (e.g., "Mbps").
  final String downloadUnit;

  /// The formatted upload speed value (e.g., "45.2").
  final String uploadSpeed;

  /// The unit for the upload speed (e.g., "Mbps").
  final String uploadUnit;

  /// The latency (ping) in milliseconds.
  final String latency;

  /// The formatted timestamp of when the test was completed.
  final String timestamp;

  /// The ID of the server used for the speed test.
  final String serverId;

  /// The timestamp as a Unix epoch in milliseconds.
  final int? timestampEpoch;

  /// The raw upload bandwidth in Kbps.
  final int? uploadBandwidthKbps;

  /// The raw download bandwidth in Kbps.
  final int? downloadBandwidthKbps;

  const SpeedTestUIModel({
    required this.downloadSpeed,
    required this.downloadUnit,
    required this.uploadSpeed,
    required this.uploadUnit,
    required this.latency,
    required this.timestamp,
    required this.serverId,
    this.timestampEpoch,
    this.uploadBandwidthKbps,
    this.downloadBandwidthKbps,
  });

  @override
  List<Object?> get props => [
        downloadSpeed,
        downloadUnit,
        uploadSpeed,
        uploadUnit,
        latency,
        timestamp,
        serverId,
        timestampEpoch,
        uploadBandwidthKbps,
        downloadBandwidthKbps,
      ];

  Map<String, dynamic> toMap() {
    return {
      'downloadSpeed': downloadSpeed,
      'downloadUnit': downloadUnit,
      'uploadSpeed': uploadSpeed,
      'uploadUnit': uploadUnit,
      'latency': latency,
      'timestamp': timestamp,
      'serverId': serverId,
      'timestampEpoch': timestampEpoch,
      'uploadBandwidthKbps': uploadBandwidthKbps,
      'downloadBandwidthKbps': downloadBandwidthKbps,
    };
  }

  factory SpeedTestUIModel.fromMap(Map<String, dynamic> map) {
    return SpeedTestUIModel(
      downloadSpeed: map['downloadSpeed'] ?? '--',
      downloadUnit: map['downloadUnit'] ?? 'Mbps',
      uploadSpeed: map['uploadSpeed'] ?? '--',
      uploadUnit: map['uploadUnit'] ?? 'Mbps',
      latency: map['latency'] ?? '--',
      timestamp: map['timestamp'] ?? '--',
      serverId: map['serverId'] ?? '--',
      timestampEpoch: map['timestampEpoch'],
      uploadBandwidthKbps: map['uploadBandwidthKbps'],
      downloadBandwidthKbps: map['downloadBandwidthKbps'],
    );
  }

  String toJson() => json.encode(toMap());

  factory SpeedTestUIModel.fromJson(String source) =>
      SpeedTestUIModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Creates an empty model with default placeholder values.
  factory SpeedTestUIModel.empty() {
    return const SpeedTestUIModel(
      downloadSpeed: '--',
      downloadUnit: 'Mbps',
      uploadSpeed: '--',
      uploadUnit: 'Mbps',
      latency: '--',
      timestamp: '--',
      serverId: '--',
      timestampEpoch: null,
      uploadBandwidthKbps: null,
      downloadBandwidthKbps: null,
    );
  }
}
