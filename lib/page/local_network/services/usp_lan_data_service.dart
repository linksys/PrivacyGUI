import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
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

      // Issue #1129: keep every LAN IPv6 address (including link-local) and let
      // the UI mark a link-local (fe80::/10) address with a scope badge rather
      // than hiding it. Reorder so a globally routable address is preferred as
      // the representative value; when the interface holds only a link-local
      // address it is still shown, tagged as link-local. Ordering is shared with
      // the WAN path via `preferGlobalIpv6First`.
      final instances = resp.getInstances('Device.IP.Interface.1.IPv6Address.');
      final addresses = instances
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
