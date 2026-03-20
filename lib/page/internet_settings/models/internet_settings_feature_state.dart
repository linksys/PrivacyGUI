import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

/// Composed FeatureState for the internet settings page.
///
/// Provides compatibility getters matching the old [UspInternetSettingsState]
/// interface so that section widgets need only a type name change.
class InternetSettingsFeatureState
    extends FeatureState<InternetSettingsSettings, InternetSettingsStatus> {
  const InternetSettingsFeatureState({
    required super.settings,
    required super.status,
  });

  /// Initial loading state before first fetch.
  factory InternetSettingsFeatureState.initial() {
    return InternetSettingsFeatureState(
      settings: Preservable(
        original: InternetSettingsSettings.empty(),
        current: InternetSettingsSettings.empty(),
      ),
      status: const InternetSettingsStatus(isLoading: true),
    );
  }

  // ---------------------------------------------------------------------------
  // Compatibility getters — match old UspInternetSettingsState interface
  // ---------------------------------------------------------------------------

  /// Read-only info (current MAC, PPP status, DHCPv6 DUID, etc.).
  InternetSettingsReadOnlyInfo get readOnlyInfo => status.readOnlyInfo;

  /// Form snapshot captured after fetch (baseline for dirty checking).
  UspInternetSettingsForm get original => settings.original.form;

  /// Actively-edited form — updated on every user interaction.
  UspInternetSettingsForm get edited => settings.current.form;

  /// Whether the user is in edit mode.
  bool get isEditing => status.isEditing;

  /// Current connection type from the edited form.
  UspWanConnectionType get connectionType => edited.connectionType;

  /// Whether the device is in bridge mode.
  bool get isBridgeMode => connectionType == UspWanConnectionType.bridge;

  // --- Read-only convenience getters ---
  String get currentMacAddress => readOnlyInfo.currentMacAddress;
  String get pppConnectionStatus => readOnlyInfo.pppConnectionStatus;
  String get dhcpv6Duid => readOnlyInfo.dhcpv6Duid;

  @override
  InternetSettingsFeatureState copyWith({
    Preservable<InternetSettingsSettings>? settings,
    InternetSettingsStatus? status,
  }) {
    return InternetSettingsFeatureState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, dynamic> toMap() => {};
}
