import 'dart:convert';

import 'package:equatable/equatable.dart';

/// UI model for a single static route entry (presentation layer)
///
/// This model isolates the presentation layer from JNAP data models.
/// It contains route configuration in user-friendly terms.
class StaticRouteEntryUIModel extends Equatable {
  /// Route description or name (max 32 characters)
  final String name;

  /// Destination network IP address (IPv4)
  final String destinationIP;

  /// Subnet mask for the destination network (IPv4)
  final String subnetMask;

  /// Gateway IP address for this route (IPv4)
  final String gateway;

  /// Network interface for this route (e.g., 'LAN' or 'Internet')
  final String interface;

  const StaticRouteEntryUIModel({
    required this.name,
    required this.destinationIP,
    required this.subnetMask,
    required this.gateway,
    required this.interface,
  });

  @override
  List<Object?> get props =>
      [name, destinationIP, subnetMask, gateway, interface];

  StaticRouteEntryUIModel copyWith({
    String? name,
    String? destinationIP,
    String? subnetMask,
    String? gateway,
    String? interface,
  }) {
    return StaticRouteEntryUIModel(
      name: name ?? this.name,
      destinationIP: destinationIP ?? this.destinationIP,
      subnetMask: subnetMask ?? this.subnetMask,
      gateway: gateway ?? this.gateway,
      interface: interface ?? this.interface,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'destinationIP': destinationIP,
      'subnetMask': subnetMask,
      'gateway': gateway,
      'interface': interface,
    };
  }

  factory StaticRouteEntryUIModel.fromMap(Map<String, dynamic> map) {
    return StaticRouteEntryUIModel(
      name: map['name'] as String? ?? '',
      destinationIP: map['destinationIP'] as String? ?? '',
      subnetMask: map['subnetMask'] as String? ?? '',
      gateway: map['gateway'] as String? ?? '',
      interface: map['interface'] as String? ?? 'LAN',
    );
  }

  String toJson() => json.encode(toMap());

  factory StaticRouteEntryUIModel.fromJson(String source) =>
      StaticRouteEntryUIModel.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

/// UI model for static routing settings (presentation layer)
///
/// This model isolates the presentation layer from JNAP data models.
/// It contains routing configuration in user-friendly terms.
class StaticRoutingUISettings extends Equatable {
  /// Whether NAT (Network Address Translation) is enabled
  final bool isNATEnabled;

  /// Whether dynamic routing is enabled
  final bool isDynamicRoutingEnabled;

  /// List of static route entries
  final List<StaticRouteEntryUIModel> entries;

  const StaticRoutingUISettings({
    required this.isNATEnabled,
    required this.isDynamicRoutingEnabled,
    required this.entries,
  });

  @override
  List<Object?> get props => [isNATEnabled, isDynamicRoutingEnabled, entries];

  StaticRoutingUISettings copyWith({
    bool? isNATEnabled,
    bool? isDynamicRoutingEnabled,
    List<StaticRouteEntryUIModel>? entries,
  }) {
    return StaticRoutingUISettings(
      isNATEnabled: isNATEnabled ?? this.isNATEnabled,
      isDynamicRoutingEnabled:
          isDynamicRoutingEnabled ?? this.isDynamicRoutingEnabled,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isNATEnabled': isNATEnabled,
      'isDynamicRoutingEnabled': isDynamicRoutingEnabled,
      'entries': entries.map((x) => x.toMap()).toList(),
    };
  }

  factory StaticRoutingUISettings.fromMap(Map<String, dynamic> map) {
    return StaticRoutingUISettings(
      isNATEnabled: map['isNATEnabled'] as bool? ?? false,
      isDynamicRoutingEnabled: map['isDynamicRoutingEnabled'] as bool? ?? false,
      entries: List<StaticRouteEntryUIModel>.from(
        map['entries']?.map<StaticRouteEntryUIModel>(
              (x) => StaticRouteEntryUIModel.fromMap(x as Map<String, dynamic>),
            ) ??
            [],
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory StaticRoutingUISettings.fromJson(String source) =>
      StaticRoutingUISettings.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
