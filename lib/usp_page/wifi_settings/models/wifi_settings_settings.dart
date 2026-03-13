import 'package:equatable/equatable.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';

/// Quick Setup pending values for a single group (main or guest).
///
/// Initialised when Quick Setup mode is toggled ON:
///   - [ssid]         — pre-filled from the first band's current SSID.
///   - [password]     — always starts empty (TR-181 cannot return the passphrase).
///   - [securityMode] — pre-filled from the intersection of supported modes.
///
/// [isValid] must be `true` before the page-level Save button is enabled.
class WifiQuickSetupSettings extends Equatable {
  final bool isGuest;

  /// Whether all networks in this group are enabled.
  /// Initialised from the current server state (true if all bands are on).
  final bool enabled;

  final String ssid;

  /// Empty string = user has not yet entered a password (blocks Save).
  final String password;

  final String securityMode;

  /// Intersection of `supportedSecurityModes` across all networks in the group.
  /// Used to populate the security mode dropdown in [WifiQuickSetupCard].
  final List<String> supportedSecurityModes;

  const WifiQuickSetupSettings({
    required this.isGuest,
    required this.enabled,
    required this.ssid,
    required this.password,
    required this.securityMode,
    required this.supportedSecurityModes,
  });

  /// True when all required fields are filled and valid.
  bool get isValid {
    if (ssid.trim().isEmpty) return false;
    final isOpen = securityMode == 'None' ||
        securityMode == 'Enhanced-Open' ||
        securityMode.isEmpty;
    if (isOpen) return true;
    return password.isNotEmpty &&
        LengthRule(min: 8, max: 63).validate(password) &&
        WiFiPasswordRule(ignoreLength: true).validate(password);
  }

  WifiQuickSetupSettings copyWith({
    bool? enabled,
    String? ssid,
    String? password,
    String? securityMode,
  }) {
    return WifiQuickSetupSettings(
      isGuest: isGuest,
      enabled: enabled ?? this.enabled,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      securityMode: securityMode ?? this.securityMode,
      supportedSecurityModes: supportedSecurityModes,
    );
  }

  @override
  List<Object?> get props =>
      [isGuest, enabled, ssid, password, securityMode, supportedSecurityModes];
}

/// User-editable settings for the WiFi Settings page.
///
/// Used with [Preservable] to track dirty state:
///   - [original] — state as last fetched from the router.
///   - [current]  — state reflecting in-progress user edits.
///
/// [networks] holds one [WifiNetworkUIModel] per SSID; only writable fields
/// are modified by UI actions — read-only fields (band, possibleChannels, etc.)
/// remain unchanged unless a fetch replaces [original] ← [current].
class WifiSettingsSettings extends Equatable {
  /// One model per SSID, sorted by band (2.4 → 5 → 6 GHz), guest last.
  final List<WifiNetworkUIModel> networks;

  /// Whether Quick Setup mode is active.
  /// Excluded from the custom [isDirty] check in [UspWifiSettingsState] —
  /// it is a UI mode switch, not a data change by itself.
  final bool quickSetupEnabled;

  /// Quick Setup pending for main (non-guest) networks.
  /// Non-null only while Quick Setup is enabled and main networks exist.
  final WifiQuickSetupSettings? quickSetupMain;

  /// Quick Setup pending for guest networks.
  /// Non-null only while Quick Setup is enabled and guest networks exist.
  final WifiQuickSetupSettings? quickSetupGuest;

  const WifiSettingsSettings({
    required this.networks,
    required this.quickSetupEnabled,
    this.quickSetupMain,
    this.quickSetupGuest,
  });

  factory WifiSettingsSettings.empty() => const WifiSettingsSettings(
        networks: [],
        quickSetupEnabled: false,
      );

  WifiSettingsSettings copyWith({
    List<WifiNetworkUIModel>? networks,
    bool? quickSetupEnabled,
    WifiQuickSetupSettings? quickSetupMain,
    WifiQuickSetupSettings? quickSetupGuest,
    bool clearQuickSetupMain = false,
    bool clearQuickSetupGuest = false,
  }) {
    return WifiSettingsSettings(
      networks: networks ?? this.networks,
      quickSetupEnabled: quickSetupEnabled ?? this.quickSetupEnabled,
      quickSetupMain: clearQuickSetupMain
          ? null
          : (quickSetupMain ?? this.quickSetupMain),
      quickSetupGuest: clearQuickSetupGuest
          ? null
          : (quickSetupGuest ?? this.quickSetupGuest),
    );
  }

  @override
  List<Object?> get props =>
      [networks, quickSetupEnabled, quickSetupMain, quickSetupGuest];
}
