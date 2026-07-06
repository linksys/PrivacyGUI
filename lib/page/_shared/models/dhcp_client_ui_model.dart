import 'package:equatable/equatable.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

/// Presentation Layer Model for an active DHCP client lease.
class DhcpClientUIModel extends Equatable with DiagnosticLoggable {
  final String mac;
  final String ip;
  final bool active;
  final String hostName;
  final DateTime? leaseExpiry;

  const DhcpClientUIModel({
    required this.mac,
    required this.ip,
    required this.active,
    this.hostName = '',
    this.leaseExpiry,
  });

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
      return active ? '' : 'Expired';
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
  String get diagnosticName => 'DhcpClientUIModel';

  @override
  Map<String, Object?> get namedProps => {
        'mac': mac,
        'ip': ip,
        'active': active,
        'hostName': hostName,
        'leaseExpiry': leaseExpiry,
      };
}
