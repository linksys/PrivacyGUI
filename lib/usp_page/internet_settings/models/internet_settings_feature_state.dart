import 'package:privacy_gui/generated/ipv6settings.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
import 'package:privacy_gui/usp_page/_framework/feature_state.dart';
import 'package:privacy_gui/usp_page/_framework/preservable.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';

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

  /// Raw fetched WAN settings for read-only display.
  WanSettings get wanSettings => status.rawWan!;

  /// Raw fetched IPv6 settings for read-only display.
  Ipv6Settings get ipv6Settings => status.rawIpv6!;

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
  String get currentMacAddress => wanSettings.currentMacAddress;
  String get pppConnectionStatus => wanSettings.pppConnectionStatus;
  String get dhcpv6Duid => ipv6Settings.dhcpv6Duid;

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
