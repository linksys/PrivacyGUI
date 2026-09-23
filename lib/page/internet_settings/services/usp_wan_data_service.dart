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
        _fetchWanStatusTolerantOfNoAddress(),
        _fetchGatewayAndIpv6Addresses(),
      ]);

      final wanStatus = results[0] as WanStatus?;
      final extra =
          results[1] as ({String gateway, List<String> ipv6Addresses});

      // A down WAN has no address instance at all, so there is no WanStatus to read
      // fields off. That is a valid state, not a failure — see the helper below.
      if (wanStatus == null) {
        return WanStatusUIModel(
          isUp: false,
          ipAddress: '',
          subnetMask: '',
          addressingType: '',
          mtu: 0,
          gateway: extra.gateway,
          ipv6Enabled: false,
          ipv6Addresses: extra.ipv6Addresses,
        );
      }

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

  /// `WanStatus.fetch` but returning `null` instead of throwing when the device has no
  /// IPv4 address instance.
  ///
  /// WHY THIS IS THE SERVICE LAYER'S JOB — linksys/PrivacyGUI#1615.
  ///
  /// **A WAN with no address is a normal device state, not an error.** Measured on
  /// FW 2.0.2.26091803 with the interface taken down:
  ///
  /// ```
  /// Device.IP.Interface.2.Status                     => Dormant
  /// Device.IP.Interface.2.IPv4AddressNumberOfEntries => 0
  /// Device.IP.Interface.2.IPv4Address.1.IPAddress    => (the parameter does not exist)
  /// ```
  ///
  /// The generated `WanStatus._fromResponse` treats `IPv4Address.1.IPAddress`,
  /// `.SubnetMask` and `.AddressingType` as REQUIRED and throws when they are absent. So
  /// every refresh triggered while the WAN is down fails — which is precisely the refresh
  /// a user most needs, because it is the one that would tell the UI to stop showing an
  /// address that no longer exists.
  ///
  /// **Why here and not in the codegen.** The generated file comes from yaml in
  /// `linksys/usp_framework`, so relaxing the requirement there is a cross-repository
  /// change affecting every consumer of that model. And it would be the wrong place even
  /// if it were cheap: the codegen's job is to report faithfully what the device returned,
  /// and "these three parameters were absent" IS what it returned. Deciding that absence
  /// means "no address" rather than "broken response" is a **domain** judgement, and the
  /// service layer is where this project puts device-reality-to-UI-model translation
  /// (constitution Article VI).
  ///
  /// **Why it is narrow.** Only the specific validation error about missing IPv4 address
  /// fields is swallowed, and only when the device also reports zero address entries —
  /// the device's own confirmation that there is nothing to read. Anything else
  /// propagates, so a genuine transport failure, an auth error or a different missing
  /// field still surfaces as a `ServiceError` rather than being rendered as "the WAN is
  /// down".
  Future<WanStatus?> _fetchWanStatusTolerantOfNoAddress() async {
    try {
      return await WanStatus.fetch(_usp);
    } catch (e) {
      final message = e.toString();
      final looksLikeMissingAddress =
          message.contains('Required fields missing') &&
              message.contains('IPv4Address.1.');
      if (!looksLikeMissingAddress) rethrow;

      // Confirm with the device rather than trusting the error string alone: if it
      // reports address entries, the fields should have been there and something else is
      // wrong — so let the original error stand.
      //
      // The instance is resolved from the error message rather than queried with a
      // wildcard. A wildcard read returns every interface, and this router has two with
      // one address each — so "any interface reports zero" would call the WAN down
      // because the LAN happened to have no address. Only the interface the failure was
      // actually about counts.
      final instance = RegExp(r'(Device\.IP\.Interface\.\d+\.)IPv4Address\.1\.')
          .firstMatch(message)
          ?.group(1);
      if (instance == null) rethrow;

      final entries = await _usp.get(['${instance}IPv4AddressNumberOfEntries']);
      final reported = entries['${instance}IPv4AddressNumberOfEntries'];
      if (reported?.toString() != '0') rethrow;

      logger.d('[USP][WanData]: ${instance}IPv4Address.1.* absent and '
          'IPv4AddressNumberOfEntries=0 — treating as WAN down, not an error');
      return null;
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
