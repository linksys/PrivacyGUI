import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/generated/wan_ipv6addresses.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspWanDataServiceProvider = Provider<UspWanDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
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

  /// Fetches default gateway IP and IPv6 addresses via codegen APIs.
  Future<({String gateway, List<String> ipv6Addresses})>
      _fetchGatewayAndIpv6Addresses() async {
    try {
      final results = await Future.wait([
        StaticRouting.fetch(_usp),
        WanIpv6Addresses.fetch(_usp),
      ]);

      final routing = results[0] as StaticRouting;
      final ipv6 = results[1] as WanIpv6Addresses;

      // Find default route (dest 0.0.0.0) on WAN interface (Interface.2)
      String gateway = '';
      for (final route in routing.items) {
        if (route.destIpAddress == '0.0.0.0' &&
            route.interface_.contains('Interface.2')) {
          gateway = route.gatewayIpAddress;
          break;
        }
      }

      final ipv6Addresses = ipv6.items
          .map((addr) => addr.ipAddress)
          .where((ip) => ip.isNotEmpty)
          .toList();

      // TR-181 returns IPv6 addresses in instance order, which frequently puts
      // the link-local (fe80::/10) address first. The WAN widget shows a single
      // representative address (ipv6Addresses.first), which must be the globally
      // routable one — not the link-local. Reorder so global unicast wins.
      // See linksys/PrivacyGUI#1128.
      final orderedIpv6Addresses = preferGlobalIpv6First(ipv6Addresses);

      return (gateway: gateway, ipv6Addresses: orderedIpv6Addresses);
    } catch (e) {
      logger.w('[USP][WanData]: Gateway/IPv6 fetch failed: $e');
      return (gateway: '', ipv6Addresses: const <String>[]);
    }
  }
}
