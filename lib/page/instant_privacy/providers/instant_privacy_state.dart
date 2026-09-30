import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_settings.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_status.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

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

  /// On only in `Allow` — Instant Privacy's own mode. `Deny` is MAC Filter's and
  /// reads as off here.
  bool get isEnabled => settings.current.mode == MacFilterMode.allow;

  /// The allow list, or nothing when the device is not in `Allow`: in `Deny` the
  /// device list is MAC Filter's block list, and showing it here would present
  /// blocked devices as the allowed ones.
  List<String> get allowedMacs =>
      isEnabled ? settings.current.macs : const <String>[];

  /// Whether the device is in MAC Filter's mode as last read, which turning
  /// Instant Privacy on would override. Read off `original` — the applied mode,
  /// not an edit on this page.
  bool get isOtherFilterOn => settings.original.mode == MacFilterMode.deny;

  /// Whether the device as last read is in `Allow` — the menu badge's source,
  /// which reports what is applied rather than an unsaved edit.
  bool get isAppliedOn => settings.original.mode == MacFilterMode.allow;

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
