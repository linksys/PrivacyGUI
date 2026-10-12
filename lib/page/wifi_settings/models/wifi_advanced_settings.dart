import 'package:equatable/equatable.dart';

/// User-editable WiFi Advanced settings.
///
/// Contains per-radio IEEE 802.11h (DFS + TPC) enabled state and the two
/// network-wide mesh steering switches.
class WifiAdvancedSettings extends Equatable {
  /// Map of radio instance path → desired IEEE80211h enabled state.
  /// Keyed by "Device.WiFi.Radio.{i}." (with trailing dot).
  final Map<String, bool> ieee80211hByRadio;

  /// `Device.X_LINKSYS_Mesh.ClientSteeringEnabled` (#1661).
  final bool clientSteering;

  /// `Device.X_LINKSYS_Mesh.NodeSteeringEnabled` (#1661).
  final bool nodeSteering;

  const WifiAdvancedSettings({
    required this.ieee80211hByRadio,
    this.clientSteering = false,
    this.nodeSteering = false,
  });

  const WifiAdvancedSettings.empty()
      : ieee80211hByRadio = const {},
        clientSteering = false,
        nodeSteering = false;

  /// True when ALL reporting radios have DFS enabled.
  bool get isDfsEnabled =>
      ieee80211hByRadio.isNotEmpty && ieee80211hByRadio.values.every((v) => v);

  WifiAdvancedSettings copyWith({
    Map<String, bool>? ieee80211hByRadio,
    bool? clientSteering,
    bool? nodeSteering,
  }) {
    return WifiAdvancedSettings(
      ieee80211hByRadio: ieee80211hByRadio ?? this.ieee80211hByRadio,
      clientSteering: clientSteering ?? this.clientSteering,
      nodeSteering: nodeSteering ?? this.nodeSteering,
    );
  }

  @override
  List<Object?> get props => [ieee80211hByRadio, clientSteering, nodeSteering];
}
