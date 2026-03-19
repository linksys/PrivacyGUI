import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Real-time device distribution snapshot — computed from DeviceUIModel list.
class DeviceDistribution extends Equatable {
  final int wifiCount;
  final int wiredCount;
  final int onlineCount;
  final int offlineCount;

  /// Band breakdown: "2.4GHz" → count, "5GHz" → count, "Wired" → count.
  final Map<String, int> bandDistribution;

  /// Signal level (0–3) → count of WiFi devices at that level.
  final Map<int, int> signalLevelDistribution;

  /// Band label → average signalQuality (0.0–1.0) for radar chart.
  final Map<String, double> bandSignalQuality;

  const DeviceDistribution({
    this.wifiCount = 0,
    this.wiredCount = 0,
    this.onlineCount = 0,
    this.offlineCount = 0,
    this.bandDistribution = const {},
    this.signalLevelDistribution = const {},
    this.bandSignalQuality = const {},
  });

  int get totalCount => onlineCount + offlineCount;

  @override
  List<Object?> get props => [
        wifiCount,
        wiredCount,
        onlineCount,
        offlineCount,
        bandDistribution,
        signalLevelDistribution,
        bandSignalQuality,
      ];
}

/// Hourly aggregate for stacked column + heatmap charts.
class HourlyAggregate extends Equatable {
  /// The start of the hour (minutes/seconds truncated).
  final DateTime hour;

  /// WiFi device count (last snapshot in this hour).
  final int wifiCount;

  /// Wired device count (last snapshot in this hour).
  final int wiredCount;

  /// MACs that were active at any point during this hour.
  final Set<String> activeMacs;

  const HourlyAggregate({
    required this.hour,
    this.wifiCount = 0,
    this.wiredCount = 0,
    this.activeMacs = const {},
  });

  int get totalCount => wifiCount + wiredCount;

  Map<String, dynamic> toJson() => {
        'hour': hour.toIso8601String(),
        'wifiCount': wifiCount,
        'wiredCount': wiredCount,
        'activeMacs': activeMacs.toList(),
      };

  factory HourlyAggregate.fromJson(Map<String, dynamic> json) {
    return HourlyAggregate(
      hour: DateTime.parse(json['hour'] as String),
      wifiCount: json['wifiCount'] as int? ?? 0,
      wiredCount: json['wiredCount'] as int? ?? 0,
      activeMacs: Set<String>.from(json['activeMacs'] as List? ?? []),
    );
  }

  @override
  List<Object?> get props => [hour, wifiCount, wiredCount, activeMacs];
}

/// Complete device analytics state.
class DeviceAnalyticsState extends Equatable {
  /// Current real-time distribution (null before first dashboard load).
  final DeviceDistribution? current;

  /// Hourly aggregates — rolling 24-hour window.
  final List<HourlyAggregate> hourlyHistory;

  /// All MACs ever seen in hourly history (for heatmap Y-axis).
  final Set<String> allKnownMacs;

  /// MAC → display name mapping for heatmap labels.
  final Map<String, String> macDisplayNames;

  static const int maxHours = 24;

  const DeviceAnalyticsState({
    this.current,
    this.hourlyHistory = const [],
    this.allKnownMacs = const {},
    this.macDisplayNames = const {},
  });

  DeviceAnalyticsState copyWith({
    DeviceDistribution? Function()? current,
    List<HourlyAggregate>? hourlyHistory,
    Set<String>? allKnownMacs,
    Map<String, String>? macDisplayNames,
  }) {
    return DeviceAnalyticsState(
      current: current != null ? current() : this.current,
      hourlyHistory: hourlyHistory ?? this.hourlyHistory,
      allKnownMacs: allKnownMacs ?? this.allKnownMacs,
      macDisplayNames: macDisplayNames ?? this.macDisplayNames,
    );
  }

  /// Serialize hourly history + known MACs for SharedPreferences persistence.
  String toJsonString() {
    return jsonEncode({
      'hourlyHistory': hourlyHistory.map((h) => h.toJson()).toList(),
      'allKnownMacs': allKnownMacs.toList(),
      'macDisplayNames': macDisplayNames,
    });
  }

  /// Restore hourly history from SharedPreferences JSON.
  static DeviceAnalyticsState fromJsonString(String json) {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final historyList = (map['hourlyHistory'] as List?)
            ?.map((e) => HourlyAggregate.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final macs = Set<String>.from(map['allKnownMacs'] as List? ?? []);
    final names = Map<String, String>.from(
      map['macDisplayNames'] as Map? ?? {},
    );
    return DeviceAnalyticsState(
      hourlyHistory: historyList,
      allKnownMacs: macs,
      macDisplayNames: names,
    );
  }

  @override
  List<Object?> get props => [
        current,
        hourlyHistory.length,
        hourlyHistory.isEmpty ? null : hourlyHistory.last.hour,
        allKnownMacs.length,
      ];
}
