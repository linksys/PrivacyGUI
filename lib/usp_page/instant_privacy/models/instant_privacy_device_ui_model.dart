import 'package:equatable/equatable.dart';

/// Presentation layer model for a device in the Instant Privacy device list.
///
/// Used for both the "connected devices" list (when feature is OFF)
/// and the "allowed devices" list (when feature is ON).
/// Implements [Equatable] per Constitution Article XI.
class InstantPrivacyDeviceUIModel extends Equatable {
  /// Normalized uppercase colon-separated MAC address (e.g. AA:BB:CC:DD:EE:FF).
  final String mac;

  /// Display name: hostname if available, otherwise falls back to [mac].
  final String displayName;

  const InstantPrivacyDeviceUIModel({
    required this.mac,
    required this.displayName,
  });

  @override
  List<Object?> get props => [mac, displayName];

  Map<String, dynamic> toMap() => {
        'mac': mac,
        'displayName': displayName,
      };

  Map<String, dynamic> toJson() => toMap();

  factory InstantPrivacyDeviceUIModel.fromMap(Map<String, dynamic> map) {
    return InstantPrivacyDeviceUIModel(
      mac: map['mac'] as String,
      displayName: map['displayName'] as String,
    );
  }

  factory InstantPrivacyDeviceUIModel.fromJson(Map<String, dynamic> json) =>
      InstantPrivacyDeviceUIModel.fromMap(json);
}
