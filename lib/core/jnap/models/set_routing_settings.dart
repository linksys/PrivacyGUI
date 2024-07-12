import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/jnap/models/get_routing_settings.dart';

class SetRoutingSettings extends Equatable {
  final bool isNATEnabled;
  final bool isDynamicRoutingEnabled;
  final List<NamedStaticRouteEntry> entries;

  const SetRoutingSettings({
    required this.isNATEnabled,
    required this.isDynamicRoutingEnabled,
    required this.entries,
  });

  SetRoutingSettings copyWith({
    bool? isNATEnabled,
    bool? isDynamicRoutingEnabled,
    List<NamedStaticRouteEntry>? entries,
  }) {
    return SetRoutingSettings(
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

  factory SetRoutingSettings.fromMap(Map<String, dynamic> map) {
    return SetRoutingSettings(
      isNATEnabled: map['isNATEnabled'] as bool,
      isDynamicRoutingEnabled: map['isDynamicRoutingEnabled'] as bool,
      entries: List<NamedStaticRouteEntry>.from(
        (map['entries'] as List<int>).map<NamedStaticRouteEntry>(
          (x) => NamedStaticRouteEntry.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SetRoutingSettings.fromJson(String source) =>
      SetRoutingSettings.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  bool get stringify => true;

  @override
  List<Object> get props => [
        isNATEnabled,
        isDynamicRoutingEnabled,
        entries,
      ];
}
