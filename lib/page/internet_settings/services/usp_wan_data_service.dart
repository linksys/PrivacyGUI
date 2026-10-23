import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/usp/services/active_ipv4_connection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/ipv6_address.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/wan_interface_path_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/generated/static_routing.g.dart';
import 'package:privacy_gui/generated/wan_ipv6addresses.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspWanDataServiceProvider = Provider<UspWanDataService>(
  (ref) {
    final usp = ref.watch(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspWanDataService(
      usp,
      autoIPoESupported:
          ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.autoIPoE),
    );
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
  /// The `addressingType` a bridged WAN reports, in the same display style as
  /// the other values (`DHCP`, `Static`, `PPPoE`, a tunnel type).
  static const bridgeAddressingType = 'Bridge';

  final UspClient _usp;
  final bool _autoIPoESupported;

  UspWanDataService(this._usp, {bool autoIPoESupported = false})
      : _autoIPoESupported = autoIPoESupported;

  /// Fetches WAN status + gateway + IPv6 addresses and returns a
  /// [WanStatusUIModel].
  Future<WanStatusUIModel> fetch() async {
    try {
      final active = await ActiveIpv4Connection.fetch(
        _usp,
        autoIPoESupported: _autoIPoESupported,
      );
      if (active != null) {
        return WanStatusUIModel(
          isUp: active.isUp,
          ipAddress: active.address,
          subnetMask: active.text('subnetMask'),
          addressingType: active.label,
          mtu: active.mtu,
          gateway: active.gateway,
          ipv6Enabled: active.isTunnel || active.ipv6.isNotEmpty,
          ipv6Addresses: preferGlobalIpv6First(active.ipv6),
        );
      }

      // Bridge next (#1597), on firmware without the native connection object:
      // `Device.IP.Interface.{wan}.Enable == false` is the only bridge signal.
      // The WAN IPv4Address row describes the WAN the router has stepped out
      // of — kept on FW 2.0.3, gone on FW 2.0.2 — so the WAN-side fields below
      // would report a mode the router is not in.
      final bridged = await _fetchBridgedStatus();
      if (bridged != null) return bridged;

      // Typed futures, awaited after Future.wait: a record `.wait` would wrap a
      // failure in a ParallelWaitError, which mapUspErrorToServiceError cannot
      // read.
      final statusFuture = WanStatus.fetch(_usp);
      final extraFuture = _fetchGatewayAndIpv6Addresses();
      await Future.wait([statusFuture, extraFuture]);
      final wanStatus = await statusFuture;
      final extra = await extraFuture;

      // A WAN with no IPv4Address row (WAN down; FW 2.0.2 in bridge mode) is a
      // down WAN with no address, not a failed read (#1615).
      final ipv4 = wanStatus.ipv4Addresses.firstOrNull;
      return WanStatusUIModel(
        isUp: ipv4 != null && wanStatus.status.toLowerCase() == 'up',
        ipAddress: ipv4?.ipAddress ?? '',
        subnetMask: ipv4?.subnetMask ?? '',
        addressingType: ipv4?.addressingType ?? '',
        mtu: wanStatus.maxMtuSize,
        gateway: extra.gateway,
        ipv6Enabled: wanStatus.ipv6Enabled,
        ipv6Addresses: extra.ipv6Addresses,
      );
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The WAN status of a bridged router, or null when the WAN is not bridged.
  ///
  /// In bridge mode the router's address is the one br-lan takes from the
  /// upstream DHCP server, so the IP and subnet are read from the `Alias == lan`
  /// interface. MTU, gateway and IPv6 still come from the WAN, as they do in
  /// every other mode.
  ///
  /// The WAN `Enable` is read directly rather than through `WanSettings`: that
  /// model requires `Enable`, while here an absent `Enable` is not a bridge
  /// reading and must fall through to the normal read.
  Future<WanStatusUIModel?> _fetchBridgedStatus() async {
    final aliases = await _usp.get(['Device.IP.Interface.*.Alias']);
    final wanPath = interfacePathsByAlias(aliases)[wanInterfaceAlias];
    if (wanPath == null) return null;

    final wanState = await _usp.get([
      '${wanPath}Enable',
      '${wanPath}MaxMTUSize',
      '${wanPath}IPv6Enable',
    ]);
    // Same rule as the Internet Settings page (`WanSettings.enable` feeding
    // `UspWanConnectionType.fromRawFields`): bridge is any present `Enable`
    // that is not true. An absent `Enable` is not a bridge reading, so the
    // normal path below reads the WAN and reports what it finds.
    if (!wanState.containsKey('${wanPath}Enable') ||
        _isTrue(wanState['${wanPath}Enable'])) {
      return null;
    }

    final lan = (await LanNetworkInfo.fetch(_usp)).ipv4Addresses.firstOrNull;
    final ipAddress = lan?.ipAddress ?? '';
    final extra = await _fetchGatewayAndIpv6Addresses();
    return WanStatusUIModel(
      isUp: ipAddress.isNotEmpty,
      ipAddress: ipAddress,
      subnetMask: lan?.subnetMask ?? '',
      addressingType: bridgeAddressingType,
      mtu: int.tryParse('${wanState['${wanPath}MaxMTUSize'] ?? ''}') ?? 0,
      gateway: extra.gateway,
      ipv6Enabled: _isTrue(wanState['${wanPath}IPv6Enable']),
      ipv6Addresses: extra.ipv6Addresses,
    );
  }

  /// The generated models' boolean parse, so both screens read `Enable` alike.
  static bool _isTrue(Object? v) => v == true || v == 'true' || v == '1';

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Fetches the default gateway and the WAN IPv6 addresses.
  ///
  /// Each is read on its own and falls back to empty on its own, so a gateway
  /// that cannot be resolved does not take the IPv6 addresses with it.
  Future<({String gateway, List<String> ipv6Addresses})>
      _fetchGatewayAndIpv6Addresses() async {
    final gateway = _fetchGateway();
    final ipv6Addresses = _fetchIpv6Addresses();
    return (gateway: await gateway, ipv6Addresses: await ipv6Addresses);
  }

  /// The default route's gateway on the WAN interface, or '' when there is
  /// none or it cannot be read.
  Future<String> _fetchGateway() async {
    try {
      final routingFuture = StaticRouting.fetch(_usp);
      final wanPathFuture = resolveWanInterfacePath(_usp);
      await Future.wait([routingFuture, wanPathFuture]);
      final routing = await routingFuture;
      final wanPath = await wanPathFuture;

      // Find the default route (dest 0.0.0.0) on the resolved WAN interface,
      // on any router. The route's Interface value may or may not carry a
      // trailing dot, so both sides are compared dot-terminated — a bare
      // `contains('Interface.2')` would also match Interface.20 / .21.
      final wanIface = ensureTrailingDot(wanPath);
      final routes = routing.items.expand((router) => router.forwardings);
      for (final route in routes) {
        if (route.destIpAddress == '0.0.0.0' &&
            ensureTrailingDot(route.interface_) == wanIface) {
          return route.gatewayIpAddress;
        }
      }
      return '';
    } catch (e) {
      logger.w('[USP][WanData]: Gateway fetch failed: $e');
      return '';
    }
  }

  /// The WAN IPv6 addresses, global first, or empty when they cannot be read.
  Future<List<String>> _fetchIpv6Addresses() async {
    try {
      final ipv6 = await WanIpv6Addresses.fetch(_usp);
      // TR-181 returns IPv6 addresses in instance order, which frequently puts
      // the link-local (fe80::/10) address first. The WAN widget shows a single
      // representative address (ipv6Addresses.first), which must prefer the
      // globally routable one. We keep every address (including link-local) and
      // only reorder so global unicast wins; the UI marks a link-local address
      // with a scope badge rather than hiding it, so a WAN with no global/ULA
      // prefix still shows its link-local address instead of nothing.
      // See linksys/PrivacyGUI#1128.
      return preferGlobalIpv6First(ipv6.items
          .map((addr) => addr.ipAddress)
          .where((ip) => ip.isNotEmpty)
          .toList());
    } catch (e) {
      logger.w('[USP][WanData]: IPv6 address fetch failed: $e');
      return const <String>[];
    }
  }
}
