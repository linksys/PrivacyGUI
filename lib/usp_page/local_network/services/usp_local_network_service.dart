import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/local_network/models/local_network_ui_model.dart';
import 'package:privacy_gui/utils.dart';

final uspLocalNetworkServiceProvider = Provider<UspLocalNetworkService>(
  (ref) => UspLocalNetworkService(ref.read(uspServiceProvider)!),
);

/// Service layer for Local Network — encapsulates codegen CRUD + transform + validation.
///
/// Uses [NetworkUtils] from `lib/utils.dart` for IP calculations.
class UspLocalNetworkService {
  final UspService _usp;

  UspLocalNetworkService(this._usp);

  static final _hostNameRegex =
      RegExp(r'^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$');

  // ─── CRUD ──────────────────────────────────────────────────

  /// Save changed LAN settings. Only sends fields that differ from original.
  Future<void> save({
    required LocalNetworkUIModel original,
    required LocalNetworkUIModel pending,
  }) async {
    await LanNetworkInfo.save(
      _usp,
      ipAddress:
          original.ipAddress != pending.ipAddress ? pending.ipAddress : null,
      subnetMask:
          original.subnetMask != pending.subnetMask ? pending.subnetMask : null,
      hostName:
          original.hostName != pending.hostName ? pending.hostName : null,
      dhcpEnabled: original.dhcpEnabled != pending.dhcpEnabled
          ? pending.dhcpEnabled
          : null,
      minAddress:
          original.minAddress != pending.minAddress ? pending.minAddress : null,
      maxAddress:
          original.maxAddress != pending.maxAddress ? pending.maxAddress : null,
      leaseTime: original.leaseTimeMinutes != pending.leaseTimeMinutes
          ? pending.leaseTimeMinutes * 60
          : null,
      dnsServers: _dnsChanged(original, pending)
          ? joinDnsServers(
              pending.dnsServer1, pending.dnsServer2, pending.dnsServer3)
          : null,
    );
  }

  static bool _dnsChanged(LocalNetworkUIModel o, LocalNetworkUIModel p) {
    return o.dnsServer1 != p.dnsServer1 ||
        o.dnsServer2 != p.dnsServer2 ||
        o.dnsServer3 != p.dnsServer3;
  }

  // ─── Transform ──────────────────────────────────────────────

  /// Convert codegen [LanNetworkInfo] → [LocalNetworkUIModel].
  LocalNetworkUIModel buildUIModel(LanNetworkInfo data) {
    final dnsParts = data.dnsServers.split(',').map((s) => s.trim()).toList();
    return LocalNetworkUIModel(
      hostName: data.hostName,
      ipAddress: data.ipAddress,
      subnetMask: data.subnetMask,
      dhcpEnabled: data.dhcpEnabled,
      minAddress: data.minAddress,
      maxAddress: data.maxAddress,
      leaseTimeMinutes: (data.leaseTime / 60).round(),
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
