import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspWanDataServiceProvider = Provider<UspWanDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }
    return UspWanDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching WAN status data.
///
/// Owns codegen calls, gateway/IPv6 query, and WAN UI model building
/// for [wanDataProvider].
class UspWanDataService {
  final UspClient _usp;

  UspWanDataService(this._usp);

  /// Fetches WAN status + gateway + IPv6 addresses and returns a
  /// [WanStatusUIModel].
  Future<WanStatusUIModel> fetch() async {
    try {
      final results = await Future.wait([
        WanStatus.fetch(_usp),
        _fetchGatewayAndIpv6Addresses(),
      ]);

      final wanStatus = results[0] as WanStatus;
      final extra =
          results[1] as ({String gateway, List<String> ipv6Addresses});

      return WanStatusUIModel(
        isUp: wanStatus.status.toLowerCase() == 'up',
        ipAddress: wanStatus.ipAddress,
        subnetMask: wanStatus.subnetMask,
        addressingType: wanStatus.addressingType,
        mtu: wanStatus.maxMtuSize,
        gateway: extra.gateway,
        ipv6Enabled: wanStatus.ipv6Enabled,
        ipv6Addresses: extra.ipv6Addresses,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Fetches default gateway IP and IPv6 addresses in a single USP request.
  ///
  /// Combines the routing table scan (for gateway) and IPv6Address
  /// multi-instance query to minimize throttler slot usage.
  Future<({String gateway, List<String> ipv6Addresses})>
      _fetchGatewayAndIpv6Addresses() async {
    try {
      final resp = await _usp.get([
        'Device.Routing.Router.1.IPv4Forwarding.*.DestIPAddress',
        'Device.Routing.Router.1.IPv4Forwarding.*.GatewayIPAddress',
        'Device.Routing.Router.1.IPv4Forwarding.*.Interface',
        'Device.IP.Interface.2.IPv6Address.',
      ]).timeout(const Duration(seconds: 20));

      // Parse gateway from routing table
      String gateway = '';
      const basePath = 'Device.Routing.Router.1.IPv4Forwarding.';
      final ids = <String>{};
      for (final key in resp.keys) {
        if (key.startsWith(basePath)) {
          final rest = key.substring(basePath.length);
          final dot = rest.indexOf('.');
          if (dot > 0) ids.add(rest.substring(0, dot));
        }
      }
      for (final id in ids) {
        final prefix = '$basePath$id.';
        final dest = resp['${prefix}DestIPAddress']?.toString() ?? '';
        final gw = resp['${prefix}GatewayIPAddress']?.toString() ?? '';
        final iface = resp['${prefix}Interface']?.toString() ?? '';
        if (dest == '0.0.0.0' && iface.contains('Interface.2')) {
          gateway = gw;
          break;
        }
      }

      // Parse IPv6 addresses
      final instances = resp.getInstances('Device.IP.Interface.2.IPv6Address.');
      final List<String> ipv6Addresses = instances
          .map((i) => i.getString('IPAddress'))
          .where((ip) => ip.isNotEmpty)
          .toList();

      return (gateway: gateway, ipv6Addresses: ipv6Addresses);
    } catch (e) {
      logger.w('[USP][WanData] Gateway/IPv6 fetch failed: $e');
      return (gateway: '', ipv6Addresses: const <String>[]);
    }
  }
}
