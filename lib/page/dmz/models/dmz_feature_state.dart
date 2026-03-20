import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/dmz/models/dmz_settings.dart';
import 'package:privacy_gui/page/dmz/models/dmz_status.dart';

/// Composed FeatureState for the DMZ page.
class DmzFeatureState extends FeatureState<DmzSettings, DmzStatus> {
  const DmzFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory DmzFeatureState.initial() {
    return DmzFeatureState(
      settings: Preservable(
        original: DmzSettings.empty(),
        current: DmzSettings.empty(),
      ),
      status: const DmzStatus(isLoading: true),
    );
  }

  @override
  DmzFeatureState copyWith({
    Preservable<DmzSettings>? settings,
    DmzStatus? status,
  }) {
    return DmzFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
