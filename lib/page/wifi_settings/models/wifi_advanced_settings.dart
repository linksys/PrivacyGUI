import 'package:equatable/equatable.dart';

/// User-editable WiFi Advanced settings.
///
/// Contains per-radio IEEE 802.11h (DFS + TPC) enabled state.
class WifiAdvancedSettings extends Equatable {
  /// Map of radio instance path → desired IEEE80211h enabled state.
  /// Keyed by "Device.WiFi.Radio.{i}." (with trailing dot).
  final Map<String, bool> ieee80211hByRadio;

  const WifiAdvancedSettings({
    required this.ieee80211hByRadio,
  });

  const WifiAdvancedSettings.empty() : ieee80211hByRadio = const {};

  /// True when ALL reporting radios have DFS enabled.
  bool get isDfsEnabled =>
      ieee80211hByRadio.isNotEmpty && ieee80211hByRadio.values.every((v) => v);

  WifiAdvancedSettings copyWith({
    Map<String, bool>? ieee80211hByRadio,
  }) {
    return WifiAdvancedSettings(
      ieee80211hByRadio: ieee80211hByRadio ?? this.ieee80211hByRadio,
    );
  }

  @override
  List<Object?> get props => [ieee80211hByRadio];
}
