import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/usp/services/active_ipv4_connection.dart';
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
      // The WAN IPv4Address row is gone in that state and its last reading was
      // the pre-bridge DHCP one, so the WAN-side fields below would describe a
      // mode the router has left.
      final bridged = await _fetchBridgedStatus();
      if (bridged != null) return bridged;

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
    } on ServiceError {
      rethrow;
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
      // FAULT CODE, NOT A SUBSTRING. `9998` is the codegen's required-leaf failure
      // (`usp_error.dart`, source 3) and `parseUspError` already extracts it. An earlier
      // version of this matched `'Required fields missing'` in the message text — a
      // string owned by another repository's generator, which would drift silently the
      // next time that template is reworded, and would then make this tolerance
      // disappear without a failing test anywhere.
      //
      // The path is still read out of the message, because the code alone does not say
      // WHICH field was missing and only the address fields may be absent legitimately.
      final parsed = parseUspError(e);
      if (parsed?.faultCode != 9998) rethrow;

      // The instance is resolved from the error message rather than queried with a
      // wildcard. A wildcard read returns every interface, and this router has two with
      // one address each — so "any interface reports zero" would call the WAN down
      // because the LAN happened to have no address. Only the interface the failure was
      // actually about counts.
      //
      // Anchored on `Device.IP.Interface.` and requiring the `IPv4Address.1.` suffix, so
      // a 9998 about some other leaf on the same object cannot satisfy it. `.1.` rather
      // than `.\d+.`: the model reads address instance 1 only, so a missing `.2.` is not
      // a state this method is about.
      final instance = RegExp(r'(Device\.IP\.Interface\.\d+\.)IPv4Address\.1\.')
          .firstMatch(e.toString())
          ?.group(1);
      if (instance == null) rethrow;

      // Confirm with the device rather than trusting the error alone: if it reports
      // address entries, the fields should have been there and something else is wrong —
      // so the original error must stand.
      //
      // WRAPPED, because this confirmation can itself fail. Unguarded, a transport error
      // here would replace the original — which is both more accurate and the one a
      // triager needs. A failed confirmation is not a confirmation.
      //
      // `throw e`, NOT `rethrow`: inside this inner catch, `rethrow` rethrows
      // `confirmFailure` — the exact substitution this block exists to prevent. Caught by
      // a test; the first version of this guard had `rethrow` here and inverted its own
      // stated purpose.
      final Object? reported;
      try {
        final entries =
            await _usp.get(['${instance}IPv4AddressNumberOfEntries']);
        reported = entries['${instance}IPv4AddressNumberOfEntries'];
      } catch (confirmFailure) {
        logger.w(
            '[USP][WanData]: could not confirm '
            '${instance}IPv4AddressNumberOfEntries; surfacing the original error',
            error: confirmFailure);
        throw e;
      }

      // Parsed as a NUMBER, not compared as a string. The device's value arrives untyped
      // — `int`, `'0'`, and `'0 '` are all shapes it has been seen to use across
      // firmware — and a string comparison fails CLOSED, turning a down WAN back into a
      // fetch error. Anything unparseable is treated as "not confirmed zero" and rethrows.
      final count = int.tryParse(reported?.toString().trim() ?? '');
      if (count != 0) rethrow;

      logger.d('[USP][WanData]: ${instance}IPv4Address.1.* absent and '
          'IPv4AddressNumberOfEntries=0 — treating as WAN down, not an error');
      return null;
    }
  }

  /// The WAN status of a bridged router, or null when the WAN is not bridged.
  ///
  /// In bridge mode the router's address is the one br-lan takes from the
  /// upstream DHCP server, so the IP and subnet are read from the `Alias == lan`
  /// interface. MTU, gateway and IPv6 still come from the WAN, as they do in
  /// every other mode.
  ///
  /// Reads the paths directly instead of through a generated model:
  /// `WanStatus` / `LanNetworkInfo` move to the 0.18 list API with #1654, and
  /// neither exposes the WAN `Enable` today. Both interfaces are resolved by
  /// Alias, never by a fixed instance number.
  Future<WanStatusUIModel?> _fetchBridgedStatus() async {
    final aliases = await _usp.get(['Device.IP.Interface.*.Alias']);
    final wanPath = _interfacePathFor(aliases, 'wan');
    if (wanPath == null) return null;

    final wanState = await _usp.get([
      '${wanPath}Enable',
      '${wanPath}MaxMTUSize',
      '${wanPath}IPv6Enable',
    ]);
    if (!_isFalse(wanState['${wanPath}Enable'])) return null;

    final lanPath = _interfacePathFor(aliases, 'lan');
    var ipAddress = '';
    var subnetMask = '';
    if (lanPath != null) {
      final lan = await _usp.get([
        '${lanPath}IPv4Address.*.IPAddress',
        '${lanPath}IPv4Address.*.SubnetMask',
      ]);
      final row = _firstIpv4Row(lan, '${lanPath}IPv4Address.');
      if (row != null) {
        ipAddress = (lan['${row}IPAddress'] ?? '').toString();
        subnetMask = (lan['${row}SubnetMask'] ?? '').toString();
      }
    }

    final extra = await _fetchGatewayAndIpv6Addresses();
    return WanStatusUIModel(
      isUp: ipAddress.isNotEmpty,
      ipAddress: ipAddress,
      subnetMask: subnetMask,
      addressingType: bridgeAddressingType,
      mtu: int.tryParse('${wanState['${wanPath}MaxMTUSize'] ?? ''}') ?? 0,
      gateway: extra.gateway,
      ipv6Enabled: _isTrue(wanState['${wanPath}IPv6Enable']),
      ipv6Addresses: extra.ipv6Addresses,
    );
  }

  /// `Device.IP.Interface.{i}.` for the interface whose Alias is [alias].
  static String? _interfacePathFor(Map<String, dynamic> aliases, String alias) {
    for (final entry in aliases.entries) {
      if (entry.value != alias) continue;
      final match = RegExp(r'^(Device\.IP\.Interface\.\d+\.)Alias$')
          .firstMatch(entry.key);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// The lowest-numbered `IPv4Address.{i}.` row under [base], or null if none.
  static String? _firstIpv4Row(Map<String, dynamic> response, String base) {
    final ids = <int>{};
    for (final key in response.keys) {
      if (!key.startsWith(base)) continue;
      final id = int.tryParse(key.substring(base.length).split('.').first);
      if (id != null) ids.add(id);
    }
    if (ids.isEmpty) return null;
    return '$base${(ids.toList()..sort()).first}.';
  }

  static bool _isTrue(Object? v) => v == true || v == 'true' || v == '1';
  static bool _isFalse(Object? v) => v == false || v == 'false' || v == '0';

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
