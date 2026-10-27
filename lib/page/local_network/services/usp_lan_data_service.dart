import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/lan_dhcp_pool.g.dart';
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

  /// Fetches LAN info, the LAN DHCP pool and the LAN IPv6 addresses, and
  /// returns a [LanInfoUIModel].
  Future<LanInfoUIModel> fetch() async {
    final LanNetworkInfo lan;
    final LanDhcpPool pool;
    final List<String> ipv6Addresses;
    try {
      final results = await Future.wait([
        LanNetworkInfo.fetch(_usp),
        LanDhcpPool.fetch(_usp),
      ]);
      lan = results[0] as LanNetworkInfo;
      pool = results[1] as LanDhcpPool;
      ipv6Addresses = await _fetchLanIpv6Addresses(lan.instancePath);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    // The interface's first address row is the router's LAN address; a LAN
    // with no row reads as no address.
    final ipv4 = lan.ipv4Addresses.firstOrNull;
    return LanInfoUIModel(
      hostName: lan.hostName,
      ipAddress: ipv4?.ipAddress ?? '',
      subnetMask: ipv4?.subnetMask ?? '',
      dhcpEnabled: pool.dhcpEnabled,
      minAddress: pool.minAddress,
      maxAddress: pool.maxAddress,
      leaseTimeMinutes: (pool.leaseTime / 60).round(),
      dnsServers: pool.dnsServers,
      ipv6Enabled: lan.ipv6Enabled,
      ipv6Addresses: ipv6Addresses,
    );
  }

  /// Fetches the IPv6 addresses of the LAN interface at [lanPath].
  Future<List<String>> _fetchLanIpv6Addresses(String lanPath) async {
    final table = '${lanPath}IPv6Address.';
    try {
      final resp = await _usp.get([table]).timeout(const Duration(seconds: 20));

      // Issue #1129: keep every LAN IPv6 address (including link-local) and let
      // the UI mark a link-local (fe80::/10) address with a scope badge rather
      // than hiding it. Reorder so a globally routable address is preferred as
      // the representative value; when the interface holds only a link-local
      // address it is still shown, tagged as link-local. Ordering is shared with
      // the WAN path via `preferGlobalIpv6First`.
      final addresses = resp
          .getInstances(table)
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty)
          .toList();
      return preferGlobalIpv6First(addresses);
    } catch (e) {
      logger.w('[USP][LanData]: IPv6 addresses fetch failed: $e');
      return const <String>[];
    }
  }
}
