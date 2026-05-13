import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_settings.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_status.dart';

/// Composed FeatureState for the Instant Safety page.
class InstantSafetyFeatureState
    extends FeatureState<InstantSafetySettings, InstantSafetyStatus> {
  const InstantSafetyFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory InstantSafetyFeatureState.initial() {
    return InstantSafetyFeatureState(
      settings: Preservable(
        original: InstantSafetySettings.empty(),
        current: InstantSafetySettings.empty(),
      ),
      status: const InstantSafetyStatus(isLoading: true),
    );
  }

  @override
  InstantSafetyFeatureState copyWith({
    Preservable<InstantSafetySettings>? settings,
    InstantSafetyStatus? status,
  }) {
    return InstantSafetyFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
