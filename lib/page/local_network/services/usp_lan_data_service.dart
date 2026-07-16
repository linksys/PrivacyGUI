import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspLanDataServiceProvider = Provider<UspLanDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspLanDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching LAN network info.
///
/// Owns codegen calls and error mapping for [lanDataProvider].
class UspLanDataService {
  final UspClient _usp;

  UspLanDataService(this._usp);

  /// Fetches LAN info + IPv6 addresses and returns a [LanInfoUIModel].
  Future<LanInfoUIModel> fetch() async {
    final List<Object> results;
    try {
      results = await Future.wait([
        LanNetworkInfo.fetch(_usp),
        _fetchLanIpv6Addresses(),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final lanInfo = results[0] as LanNetworkInfo;
    final ipv6Addresses = results[1] as List<String>;

    return LanInfoUIModel(
      hostName: lanInfo.hostName,
      ipAddress: lanInfo.ipAddress,
      subnetMask: lanInfo.subnetMask,
      dhcpEnabled: lanInfo.dhcpEnabled,
      minAddress: lanInfo.minAddress,
      maxAddress: lanInfo.maxAddress,
      leaseTimeMinutes: (lanInfo.leaseTime / 60).round(),
      dnsServers: lanInfo.dnsServers,
      ipv6Enabled: lanInfo.ipv6Enabled,
      ipv6Addresses: ipv6Addresses,
    );
  }

  /// Fetches IPv6 addresses for LAN (Interface.1) via multi-instance query.
  Future<List<String>> _fetchLanIpv6Addresses() async {
    try {
      final resp = await _usp.get([
        'Device.IP.Interface.1.IPv6Address.',
      ]).timeout(const Duration(seconds: 20));

      final instances = resp.getInstances('Device.IP.Interface.1.IPv6Address.');
      return instances
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty && !_isLinkLocalIpv6(ip))
          .toList();
    } catch (e) {
      logger.w('[USP][LanData]: IPv6 addresses fetch failed: $e');
      return const <String>[];
    }
  }

  /// Returns true if [ip] is an IPv6 link-local address (`fe80::/10`).
  ///
  /// Issue #1129: when the LAN interface holds only a link-local address
  /// (scope link, e.g. `fe80::7612:13ff:fe21:5394`) and no global/ULA prefix,
  /// the widget must render empty rather than the link-local address, since a
  /// link-local address is only valid on a single link and is not a meaningful
  /// LAN IPv6 address. The `fe80::/10` block covers any address whose first
  /// hextet, masked with `0xffc0`, equals `0xfe80` (i.e. `fe80`–`febf`).
  static bool _isLinkLocalIpv6(String ip) {
    // Drop any zone index (e.g. "fe80::1%eth0") before parsing.
    final addr = ip.split('%').first.trim();
    final firstHextet = addr.split(':').first;
    if (firstHextet.isEmpty) return false;
    final value = int.tryParse(firstHextet, radix: 16);
    if (value == null) return false;
    return (value & 0xffc0) == 0xfe80;
  }
}
