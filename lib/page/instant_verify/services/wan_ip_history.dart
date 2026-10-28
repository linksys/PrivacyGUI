import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/models/wan_ip_comparison.dart';
import 'package:privacy_gui/page/instant_verify/providers/local_storage_stub.dart'
    if (dart.library.html) 'package:privacy_gui/page/instant_verify/providers/local_storage_web.dart';

final wanIpHistoryProvider = Provider<WanIpHistory>((ref) => WanIpHistory(
      read: getStoredValue,
      write: setStoredValue,
    ));

/// Keeps one IPv4 reference per router in this browser. A changed address never
/// silently replaces the reference: only the customer's explicit action does.
class WanIpHistory {
  final String? Function(String) read;
  final void Function(String, String) write;

  WanIpHistory({required this.read, required this.write});

  WanIpComparison observe({
    required String? routerMac,
    required String? currentAddress,
    required bool connected,
  }) {
    final key = _key(routerMac);
    final current = validAddress(currentAddress);
    if (!connected || key == null || current == null) {
      return const WanIpComparison();
    }
    try {
      final reference = validAddress(read(key));
      if (reference != null) {
        return WanIpComparison(
          status: reference == current
              ? WanIpStatus.unchanged
              : WanIpStatus.changed,
          currentAddress: current,
          referenceAddress: reference,
        );
      }
      write(key, current);
      // Storage can be disabled. Never claim to have saved a reference unless
      // the read-back confirms it, even when the platform writer swallows errors.
      if (read(key) == current) {
        return WanIpComparison(
          status: WanIpStatus.firstObservation,
          currentAddress: current,
          referenceAddress: current,
        );
      }
    } catch (_) {
      // History is optional; failed storage must not abort connection checks.
    }
    return WanIpComparison(currentAddress: current);
  }

  bool saveReference({
    required String? routerMac,
    required String? currentAddress,
    required bool connected,
  }) {
    final key = _key(routerMac);
    final current = validAddress(currentAddress);
    if (!connected || key == null || current == null) return false;
    try {
      write(key, current);
      return read(key) == current;
    } catch (_) {
      return false;
    }
  }

  static String? _key(String? routerMac) {
    final mac = routerMac?.replaceAll(RegExp('[:-]'), '').toLowerCase();
    if (mac == null ||
        !RegExp(r'^[0-9a-f]{12}$').hasMatch(mac) ||
        mac == '000000000000' ||
        mac == 'ffffffffffff') {
      return null;
    }
    return 'instant_test_wan_ipv4_reference_$mac';
  }

  /// JNAP's WAN ipAddress is IPv4. Disconnected, placeholder, loopback,
  /// link-local and multicast addresses cannot establish a usable reference.
  static String? validAddress(String? address) {
    if (address == null) return null;
    final parts = address.trim().split('.');
    if (parts.length != 4 ||
        parts.any((part) => !RegExp(r'^\d{1,3}$').hasMatch(part))) {
      return null;
    }
    final octets = parts.map(int.parse).toList();
    if (octets.any((octet) => octet > 255) ||
        octets.first == 0 ||
        octets.first == 127 ||
        octets.first >= 224 ||
        (octets[0] == 169 && octets[1] == 254)) {
      return null;
    }
    return octets.join('.');
  }
}
