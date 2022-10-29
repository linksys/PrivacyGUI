import 'package:equatable/equatable.dart';

class IPv6AutomaticSettings extends Equatable {
  final bool isIPv6AutomaticEnabled;
  final String? ipv6rdTunnelMode;
  final IPv6rdTunnelSettings? iPv6rdTunnelSettings;

  @override
  List<Object?> get props => [
        isIPv6AutomaticEnabled,
        ipv6rdTunnelMode,
        iPv6rdTunnelSettings,
      ];

  const IPv6AutomaticSettings({
    required this.isIPv6AutomaticEnabled,
    this.ipv6rdTunnelMode,
    this.iPv6rdTunnelSettings,
  });

  IPv6AutomaticSettings copyWith({
    bool? isIPv6AutomaticEnabled,
    String? ipv6rdTunnelMode,
    IPv6rdTunnelSettings? iPv6rdTunnelSettings,
  }) {
    return IPv6AutomaticSettings(
      isIPv6AutomaticEnabled:
          isIPv6AutomaticEnabled ?? this.isIPv6AutomaticEnabled,
      ipv6rdTunnelMode: ipv6rdTunnelMode ?? this.ipv6rdTunnelMode,
      iPv6rdTunnelSettings: iPv6rdTunnelSettings ?? this.iPv6rdTunnelSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isIPv6AutomaticEnabled': isIPv6AutomaticEnabled,
      'ipv6rdTunnelMode': ipv6rdTunnelMode,
      'iPv6rdTunnelSettings': iPv6rdTunnelSettings,
    };
  }

  factory IPv6AutomaticSettings.fromJson(Map<String, dynamic> json) {
    return IPv6AutomaticSettings(
      isIPv6AutomaticEnabled: json['isIPv6AutomaticEnabled'],
      ipv6rdTunnelMode: json['ipv6rdTunnelMode'],
      iPv6rdTunnelSettings: json['ipv6rdTunnelSettings'] == null
          ? null
          : IPv6rdTunnelSettings.fromJson(
              json['ipv6rdTunnelSettings'],
            ),
    );
  }
}

class IPv6rdTunnelSettings extends Equatable {
  final String prefix;
  final int prefixLength;
  final String borderRelay;
  final int borderRelayPrefixLength;

  @override
  List<Object?> get props => [
        prefix,
        prefixLength,
        borderRelay,
        borderRelayPrefixLength,
      ];

  const IPv6rdTunnelSettings({
    required this.prefix,
    required this.prefixLength,
    required this.borderRelay,
    required this.borderRelayPrefixLength,
  });

  IPv6rdTunnelSettings copyWith({
    String? prefix,
    int? prefixLength,
    String? borderRelay,
    int? borderRelayPrefixLength,
  }) {
    return IPv6rdTunnelSettings(
      prefix: prefix ?? this.prefix,
      prefixLength: prefixLength ?? this.prefixLength,
      borderRelay: borderRelay ?? this.borderRelay,
      borderRelayPrefixLength:
          borderRelayPrefixLength ?? this.borderRelayPrefixLength,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prefix': prefix,
      'prefixLength': prefixLength,
      'borderRelay': borderRelay,
      'borderRelayPrefixLength': borderRelayPrefixLength,
    };
  }

  factory IPv6rdTunnelSettings.fromJson(Map<String, dynamic> json) {
    return IPv6rdTunnelSettings(
      prefix: json['prefix'],
      prefixLength: json['prefixLength'],
      borderRelay: json['borderRelay'],
      borderRelayPrefixLength: json['borderRelayPrefixLength'],
    );
  }
}
