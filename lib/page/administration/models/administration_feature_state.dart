import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/administration/models/administration_settings.dart';
import 'package:privacy_gui/page/administration/models/administration_status.dart';

/// Composed FeatureState for the Administration page.
class AdministrationFeatureState
    extends FeatureState<AdministrationSettings, AdministrationStatus> {
  const AdministrationFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory AdministrationFeatureState.initial() {
    return AdministrationFeatureState(
      settings: Preservable(
        original: const AdministrationSettings.empty(),
        current: const AdministrationSettings.empty(),
      ),
      status: const AdministrationStatus.loading(),
    );
  }

  @override
  AdministrationFeatureState copyWith({
    Preservable<AdministrationSettings>? settings,
    AdministrationStatus? status,
  }) {
    return AdministrationFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'upnpEnabled': settings.current.upnpEnabled,
        'isDirty': isDirty,
        'isLoading': status.isLoading,
      };
}
