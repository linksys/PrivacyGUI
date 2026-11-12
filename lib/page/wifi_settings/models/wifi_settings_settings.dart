import 'package:equatable/equatable.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/validator_rules/_validator_rules.dart';

/// Quick Setup pending values for a single group (main or guest).
///
/// Initialised when Quick Setup mode is toggled ON:
///   - [ssid]         — pre-filled from the first band's current SSID.
///   - [password]     — always starts empty (TR-181 cannot return the passphrase).
///   - [securityMode] — pre-filled from the intersection of supported modes.
///
/// [isValid] must be `true` before the page-level Save button is enabled.
/// Validity is evaluated against [original] so that a password is only
/// required when the user typed one, or when the save would secure a network
/// that has no passphrase yet (see [isPasswordRequired]).
class WifiQuickSetupSettings extends Equatable {
  final bool isGuest;

  /// Whether all networks in this group are enabled.
  /// Initialised from the current server state (true if all bands are on).
  final bool enabled;

  final String ssid;

  /// Empty string = the user has not typed a password, so the router keeps
  /// the one it has. Blocks Save only when [isPasswordRequired].
  final String password;

  final String securityMode;

  /// Whether any network in this group is open on the router now — its own
  /// mode, not [securityMode], which is the first network's. Read-only, like
  /// [supportedSecurityModes]: set from the router, never edited.
  final bool hasOpenNetwork;

  /// Intersection of `supportedSecurityModes` across all networks in the group.
  /// Used to populate the security mode dropdown in [WifiQuickSetupCard].
  final List<String> supportedSecurityModes;

  const WifiQuickSetupSettings({
    required this.isGuest,
    required this.enabled,
    required this.ssid,
    required this.password,
    required this.securityMode,
    required this.hasOpenNetwork,
    required this.supportedSecurityModes,
  });

  /// True when the next Save must carry a passphrase the user types, and the
  /// resulting security mode is non-open.
  ///
  /// [original] is the server-side snapshot (pre-edit). A typed password is
  /// always sent, so it must be valid. A mode change alone needs none: the
  /// router keeps its passphrase across WPA modes (#1720, FW 2.0.4: a Set of
  /// `ModeEnabled` alone left the key as it was, and a client that knew it
  /// joined again on WPA3). The exception is a group with an open network,
  /// which has no passphrase the user knows — FW would restore an old key or
  /// make one up — so securing it asks for one.
  ///
  /// Toggling [enabled] or changing only the SSID name sends no security
  /// parameters, so it never requires a password.
  ///
  /// [original]'s own mode counts too, not only [hasOpenNetwork]: the flag is
  /// read once from the router, and a save whose read-back fails keeps what
  /// was written as the new [original], flag and all — so a group just saved
  /// as open still carries the flag from before.
  bool isPasswordRequired(WifiQuickSetupSettings? original) {
    if (_isOpenMode(securityMode)) return false;
    if (original == null) return true;
    final passwordChanged = password != original.password;
    final modeChanged = securityMode != original.securityMode;
    final hadNoKey =
        original.hasOpenNetwork || _isOpenMode(original.securityMode);
    return passwordChanged || (modeChanged && hadNoKey);
  }

  // 'OWE' is the TR-181 token for Enhanced Open (firmware only accepts 'OWE').
  static bool _isOpenMode(String mode) => mode == 'None' || mode == 'OWE';

  /// True when all required fields are filled and valid for the write that
  /// will actually be issued against firmware.
  bool isValid(WifiQuickSetupSettings? original) {
    if (ssid.trim().isEmpty) return false;
    if (!isPasswordRequired(original)) return true;
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
      hasOpenNetwork: hasOpenNetwork,
      supportedSecurityModes: supportedSecurityModes,
    );
  }

  @override
  List<Object?> get props => [
        isGuest,
        enabled,
        ssid,
        password,
        securityMode,
        hasOpenNetwork,
        supportedSecurityModes,
      ];
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
      quickSetupMain:
          clearQuickSetupMain ? null : (quickSetupMain ?? this.quickSetupMain),
      quickSetupGuest: clearQuickSetupGuest
          ? null
          : (quickSetupGuest ?? this.quickSetupGuest),
    );
  }

  @override
  List<Object?> get props =>
      [networks, quickSetupEnabled, quickSetupMain, quickSetupGuest];
}
