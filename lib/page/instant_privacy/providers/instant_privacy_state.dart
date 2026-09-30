import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';

/// FeatureState for the Instant Privacy page (Allow/Disabled).
///
/// Save-based via the Preservable framework, over the same shared
/// [MacFilterSettings] / [MacFilterStatus] the MAC Filter page uses — Instant
/// Privacy is that filter in Allow mode. Edits mutate `settings.current`; only
/// [UspInstantPrivacyNotifier.save] writes.
class UspInstantPrivacyState
    extends FeatureState<MacFilterSettings, MacFilterStatus> {
  const UspInstantPrivacyState(
      {required super.settings, required super.status});

  factory UspInstantPrivacyState.initial() {
    return UspInstantPrivacyState(
      settings: Preservable(
        original: MacFilterSettings.empty(),
        current: MacFilterSettings.empty(),
      ),
      status: const MacFilterStatus(isLoading: true),
    );
  }

  /// The devices currently connected — the source for the "allow only these"
  /// default and the add-device picker.
  List<MacFilterDeviceUIModel> get connectedDevices => status.connectedDevices;

  @override
  UspInstantPrivacyState copyWith({
    Preservable<MacFilterSettings>? settings,
    MacFilterStatus? status,
  }) {
    return UspInstantPrivacyState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
