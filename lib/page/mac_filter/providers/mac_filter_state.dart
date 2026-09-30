import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

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

  /// On only in `Deny` — MAC Filter's own mode. `Allow` is Instant Privacy's and
  /// reads as off here.
  bool get isEnabled => settings.current.mode == MacFilterMode.deny;

  /// The block list, or nothing when the device is not in `Deny`: in `Allow` the
  /// device list is Instant Privacy's allow list, and showing it here would
  /// present the devices let in as the blocked ones.
  List<String> get blockedMacs =>
      isEnabled ? settings.current.macs : const <String>[];

  /// Whether the device is in Instant Privacy's mode as last read, which turning
  /// MAC Filter on would override. Read off `original` — the applied mode.
  bool get isOtherFilterOn => settings.original.mode == MacFilterMode.allow;

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
