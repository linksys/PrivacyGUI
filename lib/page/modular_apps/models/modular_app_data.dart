import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_color.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_icon.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_type.dart';

///        {
///            "description": "The 1st App",
///            "name": "Test App 1",
///            "version": "0.0.2",
///            "color": "cyanAccent",
///            "link": "10.0.0.103/test-app/",
///            "icon": "account-tree"
///        }
class ModularAppData extends Equatable {
  final String description;
  final String name;
  final String version;
  final ModularAppColor color;
  final String link;
  final ModularAppIcon icon;
  final ModularAppType type;

  const ModularAppData({
    required this.description,
    required this.name,
    required this.version,
    required this.color,
    required this.link,
    required this.icon,
    required this.type,
  });

  ModularAppData copyWith({
    String? description,
    String? name,
    String? version,
    ModularAppColor? color,
    String? link,
    ModularAppIcon? icon,
    ModularAppType? type,
  }) {
    return ModularAppData(
      description: description ?? this.description,
      name: name ?? this.name,
      version: version ?? this.version,
      color: color ?? this.color,
      link: link ?? this.link,
      icon: icon ?? this.icon,
      type: type ?? this.type,
    );
  }

  factory ModularAppData.fromMap(Map<String, dynamic> map) {
    return ModularAppData(
      description: map['description'],
      name: map['name'],
      version: map['version'],
      color: ModularAppColor.fromString(map['color'])!,
      link: map['link'],
      icon: ModularAppIcon.fromString(map['icon'])!,
      type: ModularAppType.values
              .firstWhereOrNull((e) => e.toValue() == map['type']) ??
          ModularAppType.app,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'name': name,
      'version': version,
      'color': color.value,
      'link': link,
      'icon': icon.value,
      'type': type.toValue(),
    };
  }

  factory ModularAppData.fromJson(String source) =>
      ModularAppData.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ModularAppData(description: $description, name: $name, version: $version, color: $color, link: $link, icon: $icon)';

  @override
  List<Object?> get props => [
        description,
        name,
        version,
        color,
        link,
        icon,
        type,
      ];
}