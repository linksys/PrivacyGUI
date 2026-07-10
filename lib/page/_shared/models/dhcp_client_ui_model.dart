import 'package:equatable/equatable.dart';

/// Presentation Layer Model for a DHCP client lease.
///
/// - [leaseActive]: Whether the DHCP lease is valid (from TR-181 DHCPv4.Server.Pool.*.Client.*.Active)
/// - [isOnline]: Whether the device is currently connected (from TR-181 Hosts.Host.*.Active)
class DhcpClientUIModel extends Equatable {
  /// MAC address (normalized to uppercase).
  final String mac;
  final String ip;

  /// Whether the DHCP lease is active (not expired).
  /// This comes from `Device.DHCPv4.Server.Pool.*.Client.*.Active`.
  final bool leaseActive;

  /// Whether the device is currently online (connected to the network).
  /// This comes from `Device.Hosts.Host.*.Active` via join on MAC address.
  /// Null if no matching host entry found.
  final bool? isOnline;

  final String hostName;
  final DateTime? leaseExpiry;

  /// Creates a DHCP client UI model. MAC is normalized to uppercase.
  DhcpClientUIModel({
    required String mac,
    required this.ip,
    required this.leaseActive,
    this.isOnline,
    this.hostName = '',
    this.leaseExpiry,
  }) : mac = mac.toUpperCase();

  /// Human-readable lease status.
  ///
  /// TR-181 `LeaseTimeRemaining` records the last lease expiry timestamp.
  /// Active clients may have a past expiry if the lease auto-renewed.
  /// - Future expiry → remaining time (e.g. "2h 30m")
  /// - Past expiry + active → empty (renewed, no meaningful remaining)
  /// - Past expiry + inactive → "Expired"
  String get leaseTimeFormatted {
    if (leaseExpiry == null) return '';
    final remaining = leaseExpiry!.difference(DateTime.now());
    if (remaining.isNegative) {
      return leaseActive ? '' : 'Expired';
    }
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  /// Last lease expiry formatted as local datetime string (e.g. "2026-03-04 14:21").
  /// Returns empty if no expiry is available.
  String get leaseExpiryFormatted {
    if (leaseExpiry == null) return '';
    final local = leaseExpiry!.toLocal();
    final y = local.year.toString();
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  /// Display name — hostname if available, otherwise MAC.
  String get displayName => hostName.isNotEmpty ? hostName : mac;

  @override
  List<Object?> get props =>
      [mac, ip, leaseActive, isOnline, hostName, leaseExpiry];
}
