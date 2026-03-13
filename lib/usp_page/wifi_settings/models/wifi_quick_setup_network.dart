import 'package:equatable/equatable.dart';

/// Aggregated WiFi network model for Quick Setup mode.
///
/// Represents all main networks (or all guest networks) as a single
/// editable unit. Mutations fan out to all [ssidInstancePaths] /
/// [apInstancePaths] via `updateMany`.
class WifiQuickSetupNetwork extends Equatable {
  /// Whether this group represents guest networks.
  final bool isGuest;

  /// Display SSID — taken from the first network in the group.
  final String ssid;

  /// Display security mode — taken from the first network in the group.
  final String securityMode;

  /// Passphrase — taken from the first network in the group.
  /// Always rendered as bullet dots in the UI.
  final String keyPassphrase;

  /// Intersection of `supportedSecurityModes` across all networks in the group.
  /// Ordering follows the first network's list.
  final List<String> supportedSecurityModes;

  /// SSID instance paths for all networks in the group.
  final List<String> ssidInstancePaths;

  /// AccessPoint instance paths for all networks in the group
  /// (only those that have a matched AP).
  final List<String> apInstancePaths;

  const WifiQuickSetupNetwork({
    required this.isGuest,
    required this.ssid,
    required this.securityMode,
    required this.keyPassphrase,
    required this.supportedSecurityModes,
    required this.ssidInstancePaths,
    required this.apInstancePaths,
  });

  @override
  List<Object?> get props => [
        isGuest,
        ssid,
        securityMode,
        keyPassphrase,
        supportedSecurityModes,
        ssidInstancePaths,
        apInstancePaths,
      ];
}
