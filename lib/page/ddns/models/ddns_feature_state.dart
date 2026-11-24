import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/ddns/models/ddns_rules.dart';
import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/page/ddns/models/ddns_status.dart';

/// Composed FeatureState for the DDNS page.
class DdnsFeatureState extends FeatureState<DdnsSettings, DdnsStatus> {
  const DdnsFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory DdnsFeatureState.initial() {
    return DdnsFeatureState(
      settings: Preservable(
        original: const DdnsSettings.empty(),
        current: const DdnsSettings.empty(),
      ),
      status: const DdnsStatus(isLoading: true),
    );
  }

  /// Whether Save is allowed: the settings differ from the router's, no save
  /// is running, and every field passes its check.
  ///
  /// Decided from the settings rather than from [DdnsStatus.fieldErrors],
  /// which only updates when a field loses focus, so a value typed and saved
  /// without leaving the field is checked too.
  bool get canSave =>
      isDirty &&
      !status.isSaving &&
      invalidDdnsFields(settings.current).isEmpty;

  @override
  DdnsFeatureState copyWith({
    Preservable<DdnsSettings>? settings,
    DdnsStatus? status,
  }) {
    return DdnsFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
