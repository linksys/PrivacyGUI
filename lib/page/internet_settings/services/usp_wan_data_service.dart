import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/wan_interface_path_provider.dart';
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
        resolveWanInterfacePath(_usp),
      ]);

      final routing = results[0] as StaticRouting;
      final ipv6 = results[1] as WanIpv6Addresses;
      final wanPath = results[2] as String; // e.g. 'Device.IP.Interface.2.'

      // Find the default route (dest 0.0.0.0) on the resolved WAN interface.
      // The route's Interface value may or may not carry a trailing dot, so
      // compare against the dot-less prefix to match exactly — a bare
      // `contains('Interface.2')` would also match Interface.20 / .21.
      final wanIfacePrefix = wanPath.endsWith('.')
          ? wanPath.substring(0, wanPath.length - 1)
          : wanPath;
      String gateway = '';
      for (final route in routing.items) {
        final iface = route.interface_.endsWith('.')
            ? route.interface_.substring(0, route.interface_.length - 1)
            : route.interface_;
        if (route.destIpAddress == '0.0.0.0' && iface == wanIfacePrefix) {
          gateway = route.gatewayIpAddress;
          break;
        }
      }

      // TR-181 returns IPv6 addresses in instance order, which frequently puts
      // the link-local (fe80::/10) address first. The WAN widget shows a single
      // representative address (ipv6Addresses.first), which must prefer the
      // globally routable one. We keep every address (including link-local) and
      // only reorder so global unicast wins; the UI marks a link-local address
      // with a scope badge rather than hiding it, so a WAN with no global/ULA
      // prefix still shows its link-local address instead of nothing.
      // See linksys/PrivacyGUI#1128.
      final ipv6Addresses = ipv6.items
          .map((addr) => addr.ipAddress)
          .where((ip) => ip.isNotEmpty)
          .toList();
      final orderedIpv6Addresses = preferGlobalIpv6First(ipv6Addresses);

      return (gateway: gateway, ipv6Addresses: orderedIpv6Addresses);
    } catch (e) {
      logger.w('[USP][WanData]: Gateway/IPv6 fetch failed: $e');
      return (gateway: '', ipv6Addresses: const <String>[]);
    }
  }
}
