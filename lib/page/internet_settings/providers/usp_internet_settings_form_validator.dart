import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

/// Whether the current edited form is valid for saving.
///
/// Derived from the notifier state — automatically recomputes when
/// the edited form changes.
final uspInternetFormValidProvider = Provider.autoDispose<bool>((ref) {
  final state = ref.watch(uspInternetSettingsProvider);
  if (state.status.isLoading) return false;
  if (!state.isEditing) return true;
  return validateForm(state.edited);
});

/// Validate the entire form based on connection type and field values.
bool validateForm(UspInternetSettingsForm form) {
  if (!_validateIpv4Fields(form)) return false;
  if (!_validateIpv6Fields(form)) return false;
  if (!_validateOptionalFields(form)) return false;
  return true;
}

bool _validateIpv4Fields(UspInternetSettingsForm form) {
  switch (form.connectionType) {
    case UspWanConnectionType.dhcp:
      return true;
    case UspWanConnectionType.staticIp:
      return _isValidIpv4(form.staticIpAddress) &&
          _isValidSubnetMask(form.subnetMask) &&
          _isValidIpv4(form.defaultGateway) &&
          _isValidIpv4(form.dnsServer1) &&
          (form.dnsServer2.isEmpty || _isValidIpv4(form.dnsServer2)) &&
          (form.dnsServer3.isEmpty || _isValidIpv4(form.dnsServer3));
    case UspWanConnectionType.pppoe:
      return form.pppUsername.isNotEmpty &&
          form.pppPassword.isNotEmpty &&
          (form.connectionTrigger != 'OnDemand' || form.idleDisconnectTime > 0);
    case UspWanConnectionType.bridge:
      return true;
  }
}

bool _validateIpv6Fields(UspInternetSettingsForm form) {
  if (!form.ipv6rdEnabled) return true;
  return isValidIpv6Cidr(form.ipv6rdPrefix) &&
      _isValidIpv4(form.ipv6rdBorderRelay) &&
      form.ipv6rdIpv4MaskLength >= 0 &&
      form.ipv6rdIpv4MaskLength <= 32;
}

/// Validate IPv6 prefix field - returns error message or null if valid.
String? validateIpv6rdPrefix(String value) {
  if (value.isEmpty) return 'Required';
  if (!isValidIpv6Cidr(value)) return 'Invalid IPv6 prefix format';
  return null;
}

/// Validate 6rd border relay field - returns error message or null if valid.
String? validateIpv6rdBorderRelay(String value) {
  if (value.isEmpty) return 'Required';
  if (!_isValidIpv4(value)) return 'Invalid IPv4 address';
  return null;
}

/// Validate 6rd prefix length field - returns error message or null if valid.
String? validateIpv6rdPrefixLength(int value) {
  if (value < 0 || value > 32) return 'Must be 0-32';
  return null;
}

bool _validateOptionalFields(UspInternetSettingsForm form) {
  // Bridge mode: MTU uses auto (0) — not user-configurable
  if (form.connectionType == UspWanConnectionType.bridge) {
    return true;
  }
  // MTU must be in valid range: 576 (IPv4 RFC 791 min) to max by protocol
  final mtuMax = switch (form.connectionType) {
    UspWanConnectionType.pppoe => 1492, // 1500 - 8 (PPP header)
    _ => 1500, // Ethernet standard (DHCP, Static)
  };
  if (form.mtu < 576 || form.mtu > mtuMax) return false;
  // MAC: empty = no clone, otherwise must be valid format
  if (form.wanMacAddress.isNotEmpty && !_isValidMac(form.wanMacAddress)) {
    return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Validators
// ---------------------------------------------------------------------------

final _ipAddressRule = IpAddressRule();

bool _isValidIpv4(String value) {
  if (value.isEmpty) return false;
  return _ipAddressRule.validate(value);
}

bool _isValidSubnetMask(String value) {
  if (!_isValidIpv4(value)) return false;
  // Convert to 32-bit integer and verify contiguous 1-bits
  final parts = value.split('.').map(int.parse).toList();
  final mask = (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3];
  if (mask == 0) return false;
  // A valid subnet mask has contiguous 1-bits followed by contiguous 0-bits
  final inverted = ~mask & 0xFFFFFFFF;
  return (inverted & (inverted + 1)) == 0;
}

final _macPattern = RegExp(
  r'^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$',
);

bool _isValidMac(String value) => _macPattern.hasMatch(value);

final _ipv6Rule = IPv6WithReservedRule();

/// Validate IPv6 CIDR notation (e.g. 2001:db8::/32).
/// Accepts compressed forms (::) and requires prefix length.
/// Rejects reserved addresses (loopback, multicast, deprecated).
bool isValidIpv6Cidr(String value) {
  if (value.isEmpty) return false;
  final parts = value.split('/');
  if (parts.length != 2) return false;

  final prefixLen = int.tryParse(parts[1]);
  if (prefixLen == null || prefixLen < 0 || prefixLen > 128) return false;

  return _ipv6Rule.validate(parts[0]);
}
