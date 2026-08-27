import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart'
    show ruleIdentifierKey;

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

  /// Stable, kebab-case key for E2E `identifier` hooks (e.g.
  /// `apps-open-<key>`). Derived from the app name ("My App" → "my-app");
  /// falls back to "unnamed" so it is always non-empty — never a positional
  /// grid index, which would re-import the `.nth()` reorder trap.
  String get identifierKey => ruleIdentifierKey(name, null);
}
