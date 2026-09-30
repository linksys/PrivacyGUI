import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';

// Re-export so existing importers of the UI model keep working.
export 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';

/// Composed FeatureState for the MAC Filter page (Deny/Disabled).
///
/// Save-based via the Preservable framework: edits mutate `settings.current`
/// and only [UspMacFilterNotifier.save] writes to the device.
class MacFilterState extends FeatureState<MacFilterSettings, MacFilterStatus> {
  const MacFilterState({required super.settings, required super.status});

  factory MacFilterState.initial() {
    return MacFilterState(
      settings: Preservable(
        original: MacFilterSettings.empty(),
        current: MacFilterSettings.empty(),
      ),
      status: const MacFilterStatus(isLoading: true),
    );
  }

  /// The connected devices available for the picker (read-only, from status).
  List<MacFilterDeviceUIModel> get connectedDevices => status.connectedDevices;

  @override
  MacFilterState copyWith({
    Preservable<MacFilterSettings>? settings,
    MacFilterStatus? status,
  }) {
    return MacFilterState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
