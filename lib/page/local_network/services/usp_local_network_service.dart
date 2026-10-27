import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/lan_dhcp_pool.g.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/util/network_utils.dart';

final uspLocalNetworkServiceProvider = Provider<UspLocalNetworkService>(
  (ref) => UspLocalNetworkService(ref.read(uspClientProvider)!),
);

/// Service layer for Local Network — encapsulates codegen CRUD + transform + validation.
///
/// Uses [NetworkUtils] from `lib/utils.dart` for IP calculations.
class UspLocalNetworkService {
  final UspClient _usp;

  UspLocalNetworkService(this._usp);

  static final _hostNameRegex =
      RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$');

  // ─── CRUD ──────────────────────────────────────────────────

  /// Time budget for a SET that changes the router IP. Changing the LAN IP
  /// makes the firmware drop the connection carrying the SET response, so the
  /// response can never arrive — bound the wait instead of hanging.
  static const _ipChangeSetTimeout = Duration(seconds: 4);

  /// Save changed LAN settings. Only sends fields that differ from original.
  ///
  /// When the router IP address changes, the SET is terminal-by-design: the
  /// firmware applies the new IP and drops the connection carrying the SET
  /// response, so a timeout / transport error on an IP-changing SET is the
  /// expected signature of success (the SET was received and applied before the
  /// disconnect). Any fault the router actively returns BEFORE the disconnect —
  /// a validation/resource/partial/complete failure — still propagates, so a
  /// genuine config failure is never hidden. When the IP does not change, the
  /// response is awaited normally and every error surfaces.
  Future<void> save({
    required LocalNetworkUIModel original,
    required LocalNetworkUIModel pending,
  }) async {
    final ipAddressChanged = original.ipAddress != pending.ipAddress;
    // Read the rows to write before the SET, outside its handling below: a
    // read that fails sent nothing, so it is a failure even on an IP change.
    final Map<String, dynamic> params;
    try {
      params = await _saveParams(original, pending);
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
    if (params.isEmpty) return;
    try {
      // One SET for the host name, the LAN address and the DHCP pool. They
      // belong to three USP services, so allowPartial is required (an atomic
      // cross-service SET is refused with 7005, #1039). And it must be one SET:
      // an IP change drops the connection, so a SET sent after it never
      // arrives.
      final updateFuture = _usp.set(params, allowPartial: true);

      // On an IP change the response rides a connection the firmware is about
      // to drop; bound the wait so we don't hang on a reply that can't arrive.
      final result = ipAddressChanged
          ? await updateFuture.timeout(_ipChangeSetTimeout)
          : await updateFuture;

      _handleSetResult(result);
    } on TimeoutException {
      // No response within the budget: the firmware applied the new IP and
      // dropped the connection, so the SET_RESP can never arrive. This is only
      // reachable when the IP changed (the timeout is applied only then).
      logger.i('[USP][Network][LAN]: IP-change SET timed out after '
          '${_ipChangeSetTimeout.inSeconds}s — treating as success '
          '(firmware dropped the connection applying the new IP)');
    } catch (e) {
      // A fault the router actively returned (ServiceError from
      // _handleSetResult) means the connection was alive and the config was
      // rejected → propagate, even on an IP change.
      if (e is ServiceError) rethrow;
      // Transport / connectivity errors are raw (non-ServiceError). On an IP
      // change they are the disconnect signature = success; otherwise they are
      // a genuine failure.
      final mapped = mapUspErrorToServiceError(e);
      if (ipAddressChanged &&
          (mapped is NetworkError || mapped is ConnectivityError)) {
        logger.i('[USP][Network][LAN]: IP-change SET hit a transport error '
            '— treating as success (firmware dropped the connection)');
        return;
      }
      throw mapped;
    }
  }

  /// The SET params of a save: only the fields that differ, each on its row.
  ///
  /// The LAN interface and the LAN pool are read first to find the rows: the
  /// interface's first `IPv4Address` row, and the pool whose Alias is
  /// `dhcp-lan`. Only the reads a change needs are made.
  Future<Map<String, dynamic>> _saveParams(
    LocalNetworkUIModel original,
    LocalNetworkUIModel pending,
  ) async {
    String? changed(String Function(LocalNetworkUIModel m) f) =>
        f(original) != f(pending) ? f(pending) : null;
    final ipAddress = changed((m) => m.ipAddress);
    final subnetMask = changed((m) => m.subnetMask);
    final dhcpEnabled = original.dhcpEnabled != pending.dhcpEnabled
        ? pending.dhcpEnabled
        : null;
    final minAddress = changed((m) => m.minAddress);
    final maxAddress = changed((m) => m.maxAddress);
    final leaseTime = original.leaseTimeMinutes != pending.leaseTimeMinutes
        ? pending.leaseTimeMinutes * 60
        : null;
    final dnsServers = _dnsChanged(original, pending)
        ? joinDnsServers(
            pending.dnsServer1, pending.dnsServer2, pending.dnsServer3)
        : null;

    final addressChanged = ipAddress != null || subnetMask != null;
    final poolChanged = dhcpEnabled != null ||
        minAddress != null ||
        maxAddress != null ||
        leaseTime != null ||
        dnsServers != null;

    final addressRow = addressChanged
        ? (await LanNetworkInfo.fetch(_usp)).ipv4Addresses.firstOrNull
        : null;
    if (addressChanged && addressRow == null) {
      throw const ResourceNotFoundError(
          detail: 'LAN IPv4Address row is absent; nothing to write');
    }
    final pool = poolChanged ? await LanDhcpPool.fetch(_usp) : null;

    return {
      ...LanNetworkInfo.updateParams(hostName: changed((m) => m.hostName)),
      if (addressRow != null)
        ...LanNetworkInfo.updateIpv4AddressesParams([
          LanIpv4AddressUpdate(
            instancePath: addressRow.instancePath,
            ipAddress: ipAddress,
            subnetMask: subnetMask,
          ),
        ]),
      if (pool != null)
        ...LanDhcpPool.updateParams(
          pool.instancePath,
          dhcpEnabled: dhcpEnabled,
          minAddress: minAddress,
          maxAddress: maxAddress,
          leaseTime: leaseTime,
          dnsServers: dnsServers,
        ),
    };
  }

  /// Parse a SET result and throw the appropriate [ServiceError] on failure.
  void _handleSetResult(Map<String, dynamic> result) {
    final parsed = UspResultParser.parseSetResult(result);
    switch (parsed) {
      case UspSuccess():
        break;
      case UspPartialSuccess(
          :final errorSummary,
          :final successes,
          :final failures
        ):
        throw UspPartialFailureError(
          summary: 'Local network update partial failure: $errorSummary',
          successPaths: successes.map((s) => s.requestedPath).toList(),
          failures: failures,
        );
      case UspFailure(:final errorSummary, :final errors):
        throw UspCompleteFailureError(
          summary: 'Local network update failed: $errorSummary',
          failures: errors,
        );
    }
  }

  static bool _dnsChanged(LocalNetworkUIModel o, LocalNetworkUIModel p) {
    return o.dnsServer1 != p.dnsServer1 ||
        o.dnsServer2 != p.dnsServer2 ||
        o.dnsServer3 != p.dnsServer3;
  }

  // ─── Transform ──────────────────────────────────────────────

  /// Convert codegen [LanNetworkInfo] + [LanDhcpPool] → [LocalNetworkUIModel].
  LocalNetworkUIModel buildUIModel(LanNetworkInfo lan, LanDhcpPool pool) {
    final ipv4 = lan.ipv4Addresses.firstOrNull;
    final dnsParts = pool.dnsServers.split(',').map((s) => s.trim()).toList();
    return LocalNetworkUIModel(
      hostName: lan.hostName,
      ipAddress: ipv4?.ipAddress ?? '',
      subnetMask: ipv4?.subnetMask ?? '',
      dhcpEnabled: pool.dhcpEnabled,
      minAddress: pool.minAddress,
      maxAddress: pool.maxAddress,
      leaseTimeMinutes: (pool.leaseTime / 60).round(),
      dnsServer1: dnsParts.isNotEmpty ? dnsParts[0] : '',
      dnsServer2: dnsParts.length > 1 ? dnsParts[1] : '',
      dnsServer3: dnsParts.length > 2 ? dnsParts[2] : '',
    );
  }

  /// Merge 3 DNS UI fields → comma-separated string for codegen save().
  String joinDnsServers(String d1, String d2, String d3) {
    return [d1, d2, d3].where((s) => s.trim().isNotEmpty).join(',');
  }

  // ─── Field Validation ───────────────────────────────────────

  String? validateHostName(String name) {
    if (name.isEmpty) return 'Hostname is required';
    if (name.length > 15) return 'Hostname must be 15 characters or less';
    if (!_hostNameRegex.hasMatch(name)) {
      return 'Only letters, numbers, and hyphens allowed';
    }
    return null;
  }

  String? validateIpAddress(String ip) {
    if (ip.isEmpty) return 'IP address is required';
    if (!NetworkUtils.isValidIpAddress(ip)) return 'Invalid IP address';
    if (ip == '0.0.0.0' || ip == '255.255.255.255') {
      return 'Reserved address';
    }
    return null;
  }

  String? validateSubnetMask(String mask) {
    if (mask.isEmpty) return 'Subnet mask is required';
    try {
      if (!NetworkUtils.isValidSubnetMask(mask)) {
        return 'Invalid subnet mask';
      }
    } catch (_) {
      return 'Invalid subnet mask';
    }
    return null;
  }

  String? validateLeaseTime(int minutes) {
    if (minutes < 1 || minutes > 525600) {
      return 'Must be 1–525600 minutes';
    }
    return null;
  }

  String? validateDns(String ip) {
    if (ip.trim().isEmpty) return null; // optional
    if (!NetworkUtils.isValidIpAddress(ip)) return 'Invalid DNS address';
    return null;
  }

  // ─── DHCP Defaults ─────────────────────────────────────────

  static const _defaultLeaseTimeMinutes = 720; // 12 hours
  static const _defaultPoolSize = 150;
  static const _defaultPoolOffset = 100;

  /// Compute sensible DHCP defaults when the user enables DHCP and the pool
  /// fields are empty. Returns the model unchanged if defaults are not needed.
  LocalNetworkUIModel applyDhcpDefaults(LocalNetworkUIModel model) {
    final needPool = model.minAddress.isEmpty || model.maxAddress.isEmpty;
    final needLease = model.leaseTimeMinutes < 1;

    if (!needPool && !needLease) return model;

    var result = model;

    if (needPool &&
        NetworkUtils.isValidIpAddress(model.ipAddress) &&
        model.subnetMask.isNotEmpty) {
      final pool = _computeDefaultPool(model.ipAddress, model.subnetMask);
      if (pool != null) {
        result = result.copyWith(
          minAddress: model.minAddress.isEmpty ? pool.$1 : null,
          maxAddress: model.maxAddress.isEmpty ? pool.$2 : null,
        );
      }
    }

    if (needLease) {
      result = result.copyWith(leaseTimeMinutes: _defaultLeaseTimeMinutes);
    }

    return result;
  }

  (String, String)? _computeDefaultPool(String routerIp, String subnetMask) {
    try {
      final routerNum = NetworkUtils.ipToNum(routerIp);
      final maskNum = NetworkUtils.ipToNum(subnetMask);
      final networkNum = routerNum & maskNum;
      final broadcastNum = networkNum | (~maskNum & 0xFFFFFFFF);
      final lastUsable = broadcastNum - 1;
      final usableCount = lastUsable - networkNum - 1;
      if (usableCount < 2) return null;

      final offset = usableCount > 200
          ? _defaultPoolOffset
          : (usableCount ~/ 4).clamp(2, _defaultPoolOffset);
      final poolSize = (usableCount > 100 ? _defaultPoolSize : usableCount ~/ 2)
          .clamp(1, _defaultPoolSize);

      var startNum = networkNum + offset;
      var endNum = startNum + poolSize - 1;

      // Shift past router IP if it falls within the pool
      if (routerNum >= startNum && routerNum <= endNum) {
        startNum = routerNum + 1;
        endNum = startNum + poolSize - 1;
      }

      if (endNum > lastUsable) endNum = lastUsable;
      if (startNum > endNum) return null;

      return (NetworkUtils.numToIp(startNum), NetworkUtils.numToIp(endNum));
    } catch (_) {
      return null;
    }
  }

  // ─── Prefix Lock ───────────────────────────────────────────

  /// How many octets to lock based on subnet mask.
  ///
  /// e.g. 255.255.255.0 (/24) → 3, 255.255.0.0 (/16) → 2.
  /// Returns 0 if the mask is invalid.
  int lockedOctetCount(String subnetMask) {
    try {
      final prefix = NetworkUtils.subnetMaskToPrefixLength(subnetMask);
      return prefix ~/ 8; // only lock fully-covered octets
    } catch (_) {
      return 0;
    }
  }

  /// Extract the network prefix from router IP based on locked octet count.
  ///
  /// e.g. routerIp='192.168.1.1', lockedOctets=3 → '192.168.1'
  String ipPrefix(String ip, int lockedOctets) {
    if (lockedOctets <= 0) return '';
    final parts = ip.split('.');
    if (parts.length != 4) return '';
    return parts.take(lockedOctets).join('.');
  }

  /// Replace locked prefix octets of [ip] with those from [routerIp].
  ///
  /// e.g. syncPrefix('10.0.0.100', '192.168.1.1', 3) → '192.168.1.100'
  String syncPrefix(String ip, String routerIp, int lockedOctets) {
    if (lockedOctets <= 0 || ip.isEmpty) return ip;
    final ipParts = ip.split('.');
    final routerParts = routerIp.split('.');
    if (ipParts.length != 4 || routerParts.length != 4) return ip;
    for (var i = 0; i < lockedOctets && i < 4; i++) {
      ipParts[i] = routerParts[i];
    }
    return ipParts.join('.');
  }

  // ─── Cascade Validation ─────────────────────────────────────

  /// Validate the entire pending model and return per-field errors.
  ///
  /// Cascade rules ensure pool range is always consistent with
  /// router IP and subnet mask.
  Map<String, String?> validateAll(LocalNetworkUIModel model) {
    final errors = <String, String?>{};

    // 1. Independent field validation
    errors['hostName'] = validateHostName(model.hostName);
    errors['ipAddress'] = validateIpAddress(model.ipAddress);
    errors['subnetMask'] = validateSubnetMask(model.subnetMask);

    // 2. DHCP fields — only validate when enabled
    if (model.dhcpEnabled) {
      errors['leaseTime'] = validateLeaseTime(model.leaseTimeMinutes);
      errors['dnsServer1'] = validateDns(model.dnsServer1);
      errors['dnsServer2'] = validateDns(model.dnsServer2);
      errors['dnsServer3'] = validateDns(model.dnsServer3);

      // 3. Cascade: pool range depends on router IP + subnet
      if (errors['ipAddress'] == null && errors['subnetMask'] == null) {
        errors.addAll(_validatePoolRange(
          routerIp: model.ipAddress,
          subnetMask: model.subnetMask,
          minAddress: model.minAddress,
          maxAddress: model.maxAddress,
        ));
      }
    }

    return errors;
  }

  /// Pool range cascade validation.
  ///
  /// Checks:
  /// - minAddress/maxAddress are valid IPv4 in same subnet
  /// - minAddress < maxAddress (numeric comparison)
  /// - Pool does not contain router IP
  Map<String, String?> _validatePoolRange({
    required String routerIp,
    required String subnetMask,
    required String minAddress,
    required String maxAddress,
  }) {
    final errors = <String, String?>{};

    // Min address
    final minError = _validatePoolAddress(
      ip: minAddress,
      routerIp: routerIp,
      subnetMask: subnetMask,
    );
    if (minError != null) {
      errors['minAddress'] = minError;
    }

    // Max address
    final maxError = _validatePoolAddress(
      ip: maxAddress,
      routerIp: routerIp,
      subnetMask: subnetMask,
    );
    if (maxError != null) {
      errors['maxAddress'] = maxError;
    }

    // Cross-field validation (only when both addresses are individually valid)
    if (errors['minAddress'] == null && errors['maxAddress'] == null) {
      final minNum = NetworkUtils.ipToNum(minAddress);
      final maxNum = NetworkUtils.ipToNum(maxAddress);

      if (minNum >= maxNum) {
        errors['maxAddress'] = 'Must be after pool start';
      }

      // Router IP within pool range
      if (NetworkUtils.isRouterIPInDHCPRange(
          routerIp, minAddress, maxAddress)) {
        errors['minAddress'] = 'Pool range includes router IP';
      }
    }

    return errors;
  }

  /// Validate a single pool address against router IP and subnet.
  String? _validatePoolAddress({
    required String ip,
    required String routerIp,
    required String subnetMask,
  }) {
    if (ip.isEmpty) return 'IP address is required';
    if (!NetworkUtils.isValidIpAddress(ip)) return 'Invalid IP address';
    if (ip == routerIp) return 'Cannot be router IP';

    try {
      final ipPrefix = NetworkUtils.getIpPrefix(ip, subnetMask);
      final routerPrefix = NetworkUtils.getIpPrefix(routerIp, subnetMask);
      if (ipPrefix != routerPrefix) return 'Not in same subnet as router';
    } catch (_) {
      return 'Invalid address for subnet';
    }

    return null;
  }
}
