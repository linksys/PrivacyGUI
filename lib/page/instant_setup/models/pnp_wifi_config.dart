import 'package:equatable/equatable.dart';

/// WiFi configuration collected during PnP wizard.
///
/// All enabled bands share the same SSID/password in the simplified PnP flow.
/// Instance paths are retained for targeted updateMany() calls.
class PnpWifiConfig extends Equatable {
  final String ssid;
  final String password;

  /// Original values from router — to detect if user changed them.
  final String originalSsid;
  final String originalPassword;

  /// Per-band instance paths for batch update.
  final List<String> ssidInstancePaths;
  final List<String> accessPointInstancePaths;

  // ─── Guest WiFi ────────────────────────────────────────
  final bool guestEnabled;
  final String guestSsid;
  final String guestPassword;
  final bool originalGuestEnabled;
  final String originalGuestSsid;
  final String originalGuestPassword;
  final List<String> guestSsidInstancePaths;
  final List<String> guestAccessPointInstancePaths;

  const PnpWifiConfig({
    required this.ssid,
    required this.password,
    required this.originalSsid,
    required this.originalPassword,
    this.ssidInstancePaths = const [],
    this.accessPointInstancePaths = const [],
    this.guestEnabled = false,
    this.guestSsid = '',
    this.guestPassword = '',
    this.originalGuestEnabled = false,
    this.originalGuestSsid = '',
    this.originalGuestPassword = '',
    this.guestSsidInstancePaths = const [],
    this.guestAccessPointInstancePaths = const [],
  });

  bool get isSsidChanged => ssid != originalSsid;
  bool get isPasswordChanged => password != originalPassword;
  bool get isDirty => isSsidChanged || isPasswordChanged || isGuestDirty;

  bool get isGuestEnabledChanged => guestEnabled != originalGuestEnabled;
  bool get isGuestSsidChanged => guestSsid != originalGuestSsid;
  bool get isGuestPasswordChanged => guestPassword != originalGuestPassword;
  bool get isGuestDirty =>
      isGuestEnabledChanged || isGuestSsidChanged || isGuestPasswordChanged;

  /// Only main WiFi changes require reconnect (guest doesn't drop connection).
  bool get isMainDirty => isSsidChanged || isPasswordChanged;

  PnpWifiConfig copyWith({
    String? ssid,
    String? password,
    bool? guestEnabled,
    String? guestSsid,
    String? guestPassword,
  }) {
    return PnpWifiConfig(
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      originalSsid: originalSsid,
      originalPassword: originalPassword,
      ssidInstancePaths: ssidInstancePaths,
      accessPointInstancePaths: accessPointInstancePaths,
      guestEnabled: guestEnabled ?? this.guestEnabled,
      guestSsid: guestSsid ?? this.guestSsid,
      guestPassword: guestPassword ?? this.guestPassword,
      originalGuestEnabled: originalGuestEnabled,
      originalGuestSsid: originalGuestSsid,
      originalGuestPassword: originalGuestPassword,
      guestSsidInstancePaths: guestSsidInstancePaths,
      guestAccessPointInstancePaths: guestAccessPointInstancePaths,
    );
  }

  @override
  List<Object?> get props => [
        ssid,
        password,
        originalSsid,
        originalPassword,
        ssidInstancePaths,
        accessPointInstancePaths,
        guestEnabled,
        guestSsid,
        guestPassword,
        originalGuestEnabled,
        originalGuestSsid,
        originalGuestPassword,
        guestSsidInstancePaths,
        guestAccessPointInstancePaths,
      ];
}
