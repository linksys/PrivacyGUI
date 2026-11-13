import 'package:equatable/equatable.dart';

import 'pnp_wifi_band.dart';

/// The main Wi-Fi, as the PnP wizard's Wi-Fi step edits it (#1511 P4).
///
/// One of the two drafts `PnpWifiConfig` was split into — the other is
/// [PnpGuestWifiSettings]. Holds no "original" values: the step's draft keeps
/// this object twice, as the router had it and as edited, in a `Preservable`.
///
/// Two shapes, and [splitMode] says which one the router has:
/// - **unified**: every band shares [ssid] and [password], written to every
///   path in [ssidInstancePaths] and [accessPointInstancePaths];
/// - **split**: each band in [bands] has its own name and password (e.g. Du ISP
///   routers).
class PnpMainWifiSettings extends Equatable {
  const PnpMainWifiSettings({
    required this.ssid,
    required this.password,
    this.ssidInstancePaths = const [],
    this.accessPointInstancePaths = const [],
    this.bands = const [],
    this.splitMode = false,
  });

  /// The unified name — the first enabled main SSID when the router was read.
  final String ssid;

  /// The unified password.
  final String password;

  final List<String> ssidInstancePaths;
  final List<String> accessPointInstancePaths;

  /// One per main band, sorted 2.4 < 5 < 6. Present in both shapes; edited only
  /// in split mode.
  final List<PnpWifiBand> bands;

  /// Whether the router had a different name on each band when it was read.
  ///
  /// Decided once, by the read, and never by an edit: a user who types the same
  /// name into every band of a split network is still editing a split network.
  final bool splitMode;

  PnpMainWifiSettings copyWith({String? ssid, String? password}) =>
      PnpMainWifiSettings(
        ssid: ssid ?? this.ssid,
        password: password ?? this.password,
        ssidInstancePaths: ssidInstancePaths,
        accessPointInstancePaths: accessPointInstancePaths,
        bands: bands,
        splitMode: splitMode,
      );

  /// This network with the band at [ssidInstancePath] edited.
  PnpMainWifiSettings withBand(
    String ssidInstancePath, {
    String? ssid,
    String? password,
  }) =>
      PnpMainWifiSettings(
        ssid: this.ssid,
        password: this.password,
        ssidInstancePaths: ssidInstancePaths,
        accessPointInstancePaths: accessPointInstancePaths,
        bands: _editBand(bands, ssidInstancePath, ssid, password),
        splitMode: splitMode,
      );

  @override
  List<Object?> get props => [
        ssid,
        password,
        ssidInstancePaths,
        accessPointInstancePaths,
        bands,
        splitMode,
      ];
}

/// The guest Wi-Fi, as the PnP wizard's guest step edits it (#1511 P4).
///
/// The same two shapes as [PnpMainWifiSettings], plus [enabled]. A router with
/// no guest SSID has none of these, and then no guest step.
class PnpGuestWifiSettings extends Equatable {
  const PnpGuestWifiSettings({
    required this.enabled,
    required this.ssid,
    required this.password,
    this.ssidInstancePaths = const [],
    this.accessPointInstancePaths = const [],
    this.bands = const [],
    this.splitMode = false,
  });

  final bool enabled;
  final String ssid;
  final String password;
  final List<String> ssidInstancePaths;
  final List<String> accessPointInstancePaths;
  final List<PnpWifiBand> bands;

  /// See [PnpMainWifiSettings.splitMode].
  final bool splitMode;

  PnpGuestWifiSettings copyWith({
    bool? enabled,
    String? ssid,
    String? password,
  }) =>
      PnpGuestWifiSettings(
        enabled: enabled ?? this.enabled,
        ssid: ssid ?? this.ssid,
        password: password ?? this.password,
        ssidInstancePaths: ssidInstancePaths,
        accessPointInstancePaths: accessPointInstancePaths,
        bands: bands,
        splitMode: splitMode,
      );

  /// This network with the band at [ssidInstancePath] edited.
  PnpGuestWifiSettings withBand(
    String ssidInstancePath, {
    String? ssid,
    String? password,
  }) =>
      PnpGuestWifiSettings(
        enabled: enabled,
        ssid: this.ssid,
        password: this.password,
        ssidInstancePaths: ssidInstancePaths,
        accessPointInstancePaths: accessPointInstancePaths,
        bands: _editBand(bands, ssidInstancePath, ssid, password),
        splitMode: splitMode,
      );

  @override
  List<Object?> get props => [
        enabled,
        ssid,
        password,
        ssidInstancePaths,
        accessPointInstancePaths,
        bands,
        splitMode,
      ];
}

/// The router's Wi-Fi as the wizard read it when it started: what the setting
/// steps' drafts begin from, and what decides whether there is a guest step.
class PnpWizardData extends Equatable {
  const PnpWizardData({required this.main, this.guest});

  final PnpMainWifiSettings main;

  /// `null` when the router has no guest SSID.
  final PnpGuestWifiSettings? guest;

  @override
  List<Object?> get props => [main, guest];
}

List<PnpWifiBand> _editBand(
  List<PnpWifiBand> bands,
  String ssidInstancePath,
  String? ssid,
  String? password,
) =>
    [
      for (final b in bands)
        b.ssidInstancePath == ssidInstancePath
            ? b.copyWith(ssid: ssid, password: password)
            : b,
    ];
