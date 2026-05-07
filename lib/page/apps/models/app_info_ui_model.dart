import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Whether the app is a system-bundled app or a user-installed (opkg) app.
enum AppCategory { system, user }

/// Presentation-layer model for a single router app.
///
/// Naming follows constitution Section 3.3.4 (class name ends with `UIModel`).
class AppInfoUIModel extends Equatable {
  final String name;
  final String description;
  final String link;
  final String version;
  final IconData iconData;
  final Color color;
  final AppCategory category;

  const AppInfoUIModel({
    required this.name,
    required this.description,
    required this.link,
    required this.version,
    required this.iconData,
    required this.color,
    required this.category,
  });

  @override
  List<Object?> get props => [name, link, version, category];
}
