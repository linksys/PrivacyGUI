import 'package:equatable/equatable.dart';

import 'objects.dart';

///
///       {
///         "id": "17735",
///         "risk": [{
///           "level": 3
///         }],
///         "category": [{
///           "id": 23
///         }],
///         "application": [{
///           "id": 17735
///         }],
///         "protocols": "1.TCP, 9.HTTP",
///         "vendor": "Facebook",
///         "technology": "1.Browser-Based",
///         "behavior": "all",
///         "popularity": "4",
///         "exclusion": [],
///         "parameters": [],
///         "action": "block",
///         "log": "enable",
///         "log-packet": "disable",
///         "rate-count": "0",
///         "rate-duration": "60",
///         "rate-mode": "continuous",
///         "rate-track": "none",
///         "session-ttl": "0",
///         "shaper": "",
///         "shaper-reverse": "",
///         "per-ip-shaper": "",
///         "quarantine": "none",
///         "quarantine-expiry": "5m",
///         "quarantine-log": "enable"
///       }
///
class FCNApplication extends Equatable {
  final String id;
  final List<FCNLevelObject> risk;
  final List<FCNIdObject> category;
  final List<FCNIdObject> application;
  final String protocols;
  final String vendor;
  final String technology;
  final String behavior;
  final String popularity;
  final List<String> exclusion;
  final List<String> parameters;
  final String action;
  final String log;
  final String logPacket;
  final String rateCount;
  final String rateDuration;
  final String rateMode;
  final String rateTrack;
  final String sessionTTL;
  final String shaper;
  final String shaperReverse;
  final String perIpShaper;
  final String quarantine;
  final String quarantineExpiry;
  final String quarantineLog;

  @override
  List<Object?> get props => [
        id,
        risk,
        category,
        application,
        protocols,
        vendor,
        technology,
        behavior,
        popularity,
      ];

  const FCNApplication({
    required this.id,
    required this.risk,
    required this.category,
    required this.application,
    required this.protocols,
    required this.vendor,
    required this.technology,
    required this.behavior,
    required this.popularity,
    this.exclusion = const [],
    this.parameters = const [],
    required this.action,
    this.log = 'enabled',
    this.logPacket = 'disabled',
    this.rateCount = '0',
    this.rateDuration = '60',
    this.rateMode = 'continuous',
    this.rateTrack = 'none',
    this.sessionTTL = '0',
    this.shaper = '',
    this.shaperReverse = '',
    this.perIpShaper = '',
    this.quarantine = 'none',
    this.quarantineExpiry = '5m',
    this.quarantineLog = 'enable',
  });

  FCNApplication copyWith({
    String? id,
    List<FCNLevelObject>? risk,
    List<FCNIdObject>? category,
    List<FCNIdObject>? application,
    String? protocols,
    String? vendor,
    String? technology,
    String? behavior,
    String? popularity,
    List<String>? exclusion,
    List<String>? parameters,
    String? action,
    String? log,
    String? logPacket,
    String? rateCount,
    String? rateDuration,
    String? rateMode,
    String? rateTrack,
    String? sessionTTL,
    String? shaper,
    String? shaperReverse,
    String? perIpShaper,
    String? quarantine,
    String? quarantineExpiry,
    String? quarantineLog,
  }) {
    return FCNApplication(
      id: id ?? this.id,
      risk: risk ?? this.risk,
      category: category ?? this.category,
      application: application ?? this.application,
      protocols: protocols ?? this.protocols,
      vendor: vendor ?? this.vendor,
      technology: technology ?? this.technology,
      behavior: behavior ?? this.behavior,
      popularity: popularity ?? this.popularity,
      exclusion: exclusion ?? this.exclusion,
      parameters: parameters ?? this.parameters,
      action: action ?? this.action,
      log: log ?? this.log,
      logPacket: logPacket ?? this.logPacket,
      rateCount: rateCount ?? this.rateCount,
      rateDuration: rateDuration ?? this.rateDuration,
      rateMode: rateMode ?? this.rateMode,
      rateTrack: rateTrack ?? this.rateTrack,
      sessionTTL: sessionTTL ?? this.sessionTTL,
      shaper: shaper ?? this.shaper,
      shaperReverse: shaperReverse ?? this.shaperReverse,
      perIpShaper: perIpShaper ?? this.perIpShaper,
      quarantine: quarantine ?? this.quarantine,
      quarantineExpiry: quarantineExpiry ?? this.quarantineExpiry,
      quarantineLog: quarantineLog ?? this.quarantineLog,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'risk': risk,
      'category': category,
      'application': application,
      'protocols': protocols,
      'vendor': vendor,
      'technology': technology,
      'behavior': behavior,
      'popularity': popularity,
      'exclusion': exclusion,
      'parameters': parameters,
      'action': action,
      'log': log,
      'log-packet': logPacket,
      'rate-count': rateCount,
      'rate-duration': rateDuration,
      'rate-mode': rateMode,
      'rate-track': rateTrack,
      'session-ttl': sessionTTL,
      'shaper': shaper,
      'shaper-reverse': shaperReverse,
      'per-ip-shaper': perIpShaper,
      'quarantine': quarantine,
      'quarantine-expiry': quarantineExpiry,
      'quarantine-log': quarantineLog,
    };
  }

  factory FCNApplication.fromJson(Map<String, dynamic> json) {
    return FCNApplication(
      id: json['id'],
      risk: List.from(json['risk'])
          .map((e) => FCNLevelObject.fromJson(e))
          .toList(),
      category: List.from(json['category'])
          .map((e) => FCNIdObject.fromJson(e))
          .toList(),
      application: List.from(json['application'])
          .map((e) => FCNIdObject.fromJson(e))
          .toList(),
      protocols: json['protocols'],
      vendor: json['vendor'],
      technology: json['technology'],
      behavior: json['behavior'],
      popularity: json['popularity'],
      exclusion: List.from(json['exclusion']),
      parameters: List.from(json['parameters']),
      action: json['action'],
      log: json['log'],
      logPacket: json['log-packet'],
      rateCount: json['rate-count'],
      rateDuration: json['rate-duration'],
      rateMode: json['rate-mode'],
      rateTrack: json['rate-track'],
      sessionTTL: json['session-ttl'],
      shaper: json['shaper'],
      shaperReverse: json['shaper-reverse'],
      perIpShaper: json['per-ip-shaper'],
      quarantine: json['quarantine'],
      quarantineExpiry: json['quarantine-expiry'],
      quarantineLog: json['quarantine-log'],
    );
  }
}
