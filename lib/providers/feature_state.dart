import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'preservable.dart';

/// An abstract base class for feature states that separates
/// preservable settings from transient status.
///
/// [TSettings] is the type for user-configurable data.
/// [TStatus] is the type for read-only system status data.
abstract class FeatureState<TSettings extends Equatable, TStatus extends Equatable> extends Equatable {
  final Preservable<TSettings> settings;
  final TStatus status;

  const FeatureState({required this.settings, required this.status});

  /// Checks if the settings have been modified.
  bool get isDirty => settings.isDirty;

  /// Creates a copy of this state but with the given fields replaced with the new values.
  FeatureState<TSettings, TStatus> copyWith({
    Preservable<TSettings>? settings,
    TStatus? status,
  });

  /// Converts this object to a map.
  Map<String, dynamic> toMap();

  /// Converts this object to a JSON string.
  String toJson() => json.encode(toMap());

  @override
  List<Object?> get props => [settings, status];
}