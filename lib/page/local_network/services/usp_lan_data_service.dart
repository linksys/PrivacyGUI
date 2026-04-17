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
          message: 'USP service not available');
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
          .where((ip) => ip.isNotEmpty)
          .toList();
    } catch (e) {
      logger.w('[USP][LanData] IPv6 addresses fetch failed: $e');
      return const <String>[];
    }
  }
}
