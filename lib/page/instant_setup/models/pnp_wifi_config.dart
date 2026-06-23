import 'package:equatable/equatable.dart';
import 'pnp_wifi_band.dart';

/// WiFi configuration collected during PnP wizard.
///
/// Supports two modes:
/// - **Unified mode**: All bands share the same SSID/password (legacy behavior).
///   Uses [ssid], [password], [ssidInstancePaths], [accessPointInstancePaths].
/// - **Split mode**: Each band has its own SSID/password.
///   Uses [mainBands] list with per-band configuration.
///
/// Mode is determined by [isSplitMode] which checks if bands have different SSIDs.
class PnpWifiConfig extends Equatable {
  // ─── Unified Mode Fields ───────────────────────────────────
  final String ssid;
  final String password;
  final String originalSsid;
  final String originalPassword;
  final List<String> ssidInstancePaths;
  final List<String> accessPointInstancePaths;

  // ─── Split Mode Fields ─────────────────────────────────────
  /// Per-band configuration for main WiFi (only used in split mode).
  final List<PnpWifiBand> mainBands;

  // ─── Guest WiFi Fields ─────────────────────────────────────
  final bool guestEnabled;
  final String guestSsid;
  final String guestPassword;
  final bool originalGuestEnabled;
  final String originalGuestSsid;
  final String originalGuestPassword;
  final List<String> guestSsidInstancePaths;
  final List<String> guestAccessPointInstancePaths;

  /// Per-band configuration for guest WiFi (only used in split mode).
  final List<PnpWifiBand> guestBands;

  const PnpWifiConfig({
    // Unified mode
    required this.ssid,
    required this.password,
    required this.originalSsid,
    required this.originalPassword,
    this.ssidInstancePaths = const [],
    this.accessPointInstancePaths = const [],
    // Split mode
    this.mainBands = const [],
    // Guest unified mode
    this.guestEnabled = false,
    this.guestSsid = '',
    this.guestPassword = '',
    this.originalGuestEnabled = false,
    this.originalGuestSsid = '',
    this.originalGuestPassword = '',
    this.guestSsidInstancePaths = const [],
    this.guestAccessPointInstancePaths = const [],
    // Guest split mode
    this.guestBands = const [],
  });

  // ─── Mode Detection ────────────────────────────────────────

  /// True if main WiFi bands have different SSIDs (split mode).
  bool get isSplitMode => mainBands.length > 1 && _hasDifferentSsids(mainBands);

  /// True if guest WiFi bands have different SSIDs (split mode).
  bool get isGuestSplitMode =>
      guestBands.length > 1 && _hasDifferentSsids(guestBands);

  bool _hasDifferentSsids(List<PnpWifiBand> bands) {
    if (bands.isEmpty) return false;
    final firstSsid = bands.first.originalSsid;
    return bands.any((b) => b.originalSsid != firstSsid);
  }

  // ─── Dirty Detection (Unified Mode) ────────────────────────

  bool get isSsidChanged => ssid != originalSsid;
  bool get isPasswordChanged => password != originalPassword;

  /// True if any main WiFi field changed (unified or split mode).
  bool get isMainDirty {
    if (isSplitMode) {
      return mainBands.any((b) => b.isDirty);
    }
    return isSsidChanged || isPasswordChanged;
  }

  // ─── Dirty Detection (Guest) ───────────────────────────────

  bool get isGuestEnabledChanged => guestEnabled != originalGuestEnabled;
  bool get isGuestSsidChanged => guestSsid != originalGuestSsid;
  bool get isGuestPasswordChanged => guestPassword != originalGuestPassword;

  /// True if any guest WiFi field changed (unified or split mode).
  bool get isGuestDirty {
    if (isGuestSplitMode) {
      return isGuestEnabledChanged || guestBands.any((b) => b.isDirty);
    }
    return isGuestEnabledChanged ||
        isGuestSsidChanged ||
        isGuestPasswordChanged;
  }

  /// True if anything changed (main or guest).
  bool get isDirty => isMainDirty || isGuestDirty;

  // ─── Copy With ─────────────────────────────────────────────

  PnpWifiConfig copyWith({
    // Unified mode
    String? ssid,
    String? password,
    // Split mode
    List<PnpWifiBand>? mainBands,
    // Guest unified mode
    bool? guestEnabled,
    String? guestSsid,
    String? guestPassword,
    // Guest split mode
    List<PnpWifiBand>? guestBands,
  }) {
    return PnpWifiConfig(
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      originalSsid: originalSsid,
      originalPassword: originalPassword,
      ssidInstancePaths: ssidInstancePaths,
      accessPointInstancePaths: accessPointInstancePaths,
      mainBands: mainBands ?? this.mainBands,
      guestEnabled: guestEnabled ?? this.guestEnabled,
      guestSsid: guestSsid ?? this.guestSsid,
      guestPassword: guestPassword ?? this.guestPassword,
      originalGuestEnabled: originalGuestEnabled,
      originalGuestSsid: originalGuestSsid,
      originalGuestPassword: originalGuestPassword,
      guestSsidInstancePaths: guestSsidInstancePaths,
      guestAccessPointInstancePaths: guestAccessPointInstancePaths,
      guestBands: guestBands ?? this.guestBands,
    );
  }

  /// Updates a specific band in [mainBands] by instance path.
  PnpWifiConfig updateMainBand(
    String ssidInstancePath, {
    String? ssid,
    String? password,
  }) {
    final updated = mainBands.map((b) {
      if (b.ssidInstancePath != ssidInstancePath) return b;
      return b.copyWith(ssid: ssid, password: password);
    }).toList();
    return copyWith(mainBands: updated);
  }

  /// Updates a specific band in [guestBands] by instance path.
  PnpWifiConfig updateGuestBand(
    String ssidInstancePath, {
    String? ssid,
    String? password,
  }) {
    final updated = guestBands.map((b) {
      if (b.ssidInstancePath != ssidInstancePath) return b;
      return b.copyWith(ssid: ssid, password: password);
    }).toList();
    return copyWith(guestBands: updated);
  }

  @override
  List<Object?> get props => [
        ssid,
        password,
        originalSsid,
        originalPassword,
        ssidInstancePaths,
        accessPointInstancePaths,
        mainBands,
        guestEnabled,
        guestSsid,
        guestPassword,
        originalGuestEnabled,
        originalGuestSsid,
        originalGuestPassword,
        guestSsidInstancePaths,
        guestAccessPointInstancePaths,
        guestBands,
      ];
}
