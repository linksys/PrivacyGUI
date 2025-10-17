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

  // Contract to ensure subclasses are copyable.
  FeatureState<TSettings, TStatus> copyWith({
    Preservable<TSettings>? settings,
    TStatus? status,
  });

  @override
  List<Object?> get props => [settings, status];
}
