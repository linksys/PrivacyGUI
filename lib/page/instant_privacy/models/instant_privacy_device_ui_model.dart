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

  /// Whether [mac] is a locally-administered (private/randomized) address.
  ///
  /// Devices using a private WiFi address rotate their MAC, so whitelisting
  /// the current value risks locking the device out after it rotates. The UI
  /// surfaces a warning for these before enabling the feature.
  final bool isPrivateMac;

  /// Current LAN address, or empty when firmware reports none.
  ///
  /// Carried for the Add-device search only: it is what makes the field's
  /// "search by name, MAC, or IP" hint true. A device is identified by its [mac]
  /// — a DHCP lease can hand the same host a different address tomorrow, so
  /// nothing looks a device up by this one — but it is still part of [props],
  /// because a renewed lease has to reach the suggestion that renders it.
  ///
  /// Deliberately absent from the allowed-devices list, whose rows are stored
  /// MACs rather than hosts currently seen on the network.
  final String ipAddress;

  const InstantPrivacyDeviceUIModel({
    required this.mac,
    required this.displayName,
    this.isPrivateMac = false,
    this.ipAddress = '',
  });

  @override
  List<Object?> get props => [mac, displayName, isPrivateMac, ipAddress];
}
