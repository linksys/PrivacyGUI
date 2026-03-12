import 'package:equatable/equatable.dart';

/// State for the WiFi Advanced tab.
///
/// [ieee80211hByRadio] — `Device.WiFi.Radio.{i}.IEEE80211hEnabled`, keyed by
///   radio instance path (e.g. "Device.WiFi.Radio.1.").
///   Only contains radios that reported a value; empty means not supported.
class UspWifiAdvancedState extends Equatable {
  final Map<String, bool> ieee80211hByRadio;

  const UspWifiAdvancedState({
    required this.ieee80211hByRadio,
  });

  /// True when ALL reporting radios have IEEE80211h enabled.
  /// False when any radio has it disabled, or when no radios report it.
  bool get isDfsEnabled =>
      ieee80211hByRadio.isNotEmpty &&
      ieee80211hByRadio.values.every((v) => v);

  UspWifiAdvancedState copyWith({
    Map<String, bool>? ieee80211hByRadio,
  }) {
    return UspWifiAdvancedState(
      ieee80211hByRadio: ieee80211hByRadio ?? this.ieee80211hByRadio,
    );
  }

  @override
  List<Object?> get props => [ieee80211hByRadio];

  Map<String, dynamic> toMap() => {
        'ieee80211hByRadio': ieee80211hByRadio,
      };

  Map<String, dynamic> toJson() => toMap();
}
