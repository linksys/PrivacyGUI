import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/util/network_utils.dart';
import 'package:privacy_gui/validator_rules/rules.dart';

/// Error keys returned by the `validate…` field checks below. The View maps
/// each to a localized string.
class WanFieldErrors {
  static const required = 'required';
  static const invalidIp = 'invalidIp';
  static const reservedIp = 'reservedIp';
  static const outOfRange = 'outOfRange';
  static const tooLong = 'tooLong';
  static const invalidMask = 'invalidMask';
  static const invalidGateway = 'invalidGateway';
}

/// The fields [validateStaticIpv4] reports on.
class StaticIpv4Field {
  static const ipAddress = 'ipAddress';
  static const subnetMask = 'subnetMask';
  static const gateway = 'gateway';
  static const dns1 = 'dns1';
  static const dns2 = 'dns2';
  static const dns3 = 'dns3';
}

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
  // IPoE has its own mode-specific native validation and owns IPv6/MTU.
  if (form.connectionType == UspWanConnectionType.ipoe) return true;
  if (!_validateIpv4Fields(form)) return false;
  if (form.connectionType.isPppBased && !_validatePppFields(form)) {
    return false;
  }
  if (!_validateIpv6Fields(form)) return false;
  if (!_validateOptionalFields(form)) return false;
  return true;
}

bool _validatePppFields(UspInternetSettingsForm form) {
  if (validatePppCredential(form.pppUsername) != null ||
      validatePppCredential(form.pppPassword) != null) {
    return false;
  }
  if (form.connectionTrigger == 'OnDemand') {
    return validateIdleMinutes(form.idleDisconnectTime) == null;
  }
  return validateKeepAliveInterval(form.lcpEchoInterval) == null;
}

/// The PPP user name or password: required, at most 255 characters.
String? validatePppCredential(String value) {
  if (value.isEmpty) return WanFieldErrors.required;
  if (value.length > kPppCredentialMaxLength) return WanFieldErrors.tooLong;
  return null;
}

/// The On Demand idle time, in minutes.
String? validateIdleMinutes(int minutes) =>
    minutes < kPppIdleMinutesMin || minutes > kPppIdleMinutesMax
        ? WanFieldErrors.outOfRange
        : null;

/// The Keep Alive "reconnect after" interval, in seconds.
String? validateKeepAliveInterval(int seconds) =>
    seconds < kPppKeepAliveSecondsMin || seconds > kPppKeepAliveSecondsMax
        ? WanFieldErrors.outOfRange
        : null;

bool _validateIpv4Fields(UspInternetSettingsForm form) {
  switch (form.connectionType) {
    case UspWanConnectionType.ipoe:
    case UspWanConnectionType.dhcp:
      return true;
    case UspWanConnectionType.staticIp:
      return validateStaticIpv4(
        ipAddress: form.staticIpAddress,
        subnetMask: form.subnetMask,
        gateway: form.defaultGateway,
        dns1: form.dnsServer1,
        dns2: form.dnsServer2,
        dns3: form.dnsServer3,
      ).isEmpty;
    case UspWanConnectionType.pppoe:
      return true;
    case UspWanConnectionType.pptp:
      return validateTunnelServer(form.serverAddress) == null &&
          (!form.underlayStatic || validateUnderlay(form).isEmpty);
    case UspWanConnectionType.l2tp:
      return validateTunnelServer(form.serverAddress) == null;
    case UspWanConnectionType.bridge:
      return true;
  }
}

/// A static IPv4 address set, checked as 1.0 and the firmware check it: the
/// Static WAN (feed_usp#55 netmngr 036) and the PPTP static underlay (039).
/// Returns each failing [StaticIpv4Field] with its [WanFieldErrors] key; empty
/// when all pass.
///
/// The IP is not reserved and is a host in its subnet; the mask is contiguous,
/// /8 to /31; the gateway is set, not reserved, not the IP, and a host in the
/// IP's subnet; DNS 1 is set; no DNS server is reserved. A /31 has no network
/// or broadcast address, so both of its addresses are hosts.
Map<String, String> validateStaticIpv4({
  required String ipAddress,
  required String subnetMask,
  required String gateway,
  required String dns1,
  required String dns2,
  required String dns3,
}) {
  final errors = <String, String>{};
  final ipError = _validateAddress(ipAddress, required: true);
  if (ipError != null) errors[StaticIpv4Field.ipAddress] = ipError;
  final prefix = _prefixLength(subnetMask);
  if (prefix == null || prefix < 8 || prefix > 31) {
    errors[StaticIpv4Field.subnetMask] = WanFieldErrors.invalidMask;
  }
  final subnetKnown = ipError == null && prefix != null;
  if (subnetKnown && !_isHostIn(ipAddress, ipAddress, prefix)) {
    errors[StaticIpv4Field.ipAddress] = WanFieldErrors.invalidIp;
  }
  final gatewayError = _validateAddress(gateway, required: true);
  if (gatewayError != null) {
    errors[StaticIpv4Field.gateway] = gatewayError;
  } else if (subnetKnown &&
      (gateway == ipAddress || !_isHostIn(gateway, ipAddress, prefix))) {
    errors[StaticIpv4Field.gateway] = WanFieldErrors.invalidGateway;
  }
  for (final (field, value, required) in [
    (StaticIpv4Field.dns1, dns1, true),
    (StaticIpv4Field.dns2, dns2, false),
    (StaticIpv4Field.dns3, dns3, false),
  ]) {
    final error = _validateAddress(value, required: required);
    if (error != null) errors[field] = error;
  }
  return errors;
}

/// [validateStaticIpv4] on the PPTP static underlay fields.
Map<String, String> validateUnderlay(UspInternetSettingsForm form) =>
    validateStaticIpv4(
      ipAddress: form.underlayIpAddress,
      subnetMask: form.underlaySubnetMask,
      gateway: form.underlayGateway,
      dns1: form.underlayDns1,
      dns2: form.underlayDns2,
      dns3: form.underlayDns3,
    );

/// One IPv4 address: [required] or empty, valid, not reserved.
String? _validateAddress(String value, {required bool required}) {
  if (value.isEmpty) return required ? WanFieldErrors.required : null;
  if (!_isValidIpv4(value)) return WanFieldErrors.invalidIp;
  if (_isReservedIpv4(value)) return WanFieldErrors.reservedIp;
  return null;
}

/// The prefix length of a dotted, contiguous mask, or null when it is not one.
int? _prefixLength(String mask) {
  if (!_isValidSubnetMask(mask)) return null;
  final n = NetworkUtils.ipToNum(mask);
  var length = 0;
  while (length < 32 && (n & (0x80000000 >> length)) != 0) {
    length++;
  }
  return length;
}

/// Whether [value] is in [ipAddress]'s /[prefix] subnet and is neither its
/// network nor its broadcast address (netmngr `wan___is_host_in`).
bool _isHostIn(String value, String ipAddress, int prefix) {
  final mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
  final network = NetworkUtils.ipToNum(ipAddress) & mask;
  final v = NetworkUtils.ipToNum(value);
  if ((v & mask) != network) return false;
  return prefix >= 31 ||
      (v != network && v != (network | (~mask & 0xFFFFFFFF)));
}

/// The PPTP / L2TP server: an IPv4 address that is not reserved, as 1.0 and
/// the firmware check it (feed_usp#55 netmngr 036, "Invalid server").
String? validateTunnelServer(String value) =>
    _validateAddress(value, required: true);

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
  // Bridge mode: MTU is not user-configurable — the WAN port joins br-lan, so
  // the service sends neither MaxMTUSize nor X_LINKSYS_MTUMode.
  if (form.connectionType == UspWanConnectionType.bridge) {
    return true;
  }
  // Auto mode: the device picks the MTU, so [form.mtu] is a device-reported
  // display value rather than something the user must get into range.
  if (!form.mtuAuto) {
    // Range is owned by [UspWanConnectionType] (single source of truth, shared
    // with the notifier's clamp on type switch and the view's error text).
    if (form.mtu < form.connectionType.mtuMin ||
        form.mtu > form.connectionType.mtuMax) {
      return false;
    }
  }
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

/// 1.0's util.isReservedAddress, which the firmware applies to every WAN
/// address it checks: 0/8, 127/8, 169.254/16, 224/4 and 240/4. [value] must be
/// a valid IPv4 address.
bool _isReservedIpv4(String value) {
  final n = NetworkUtils.ipToNum(value);
  return (n >> 24) == 0 ||
      (n >> 24) == 127 ||
      (n >> 16) == 0xA9FE ||
      (n >> 28) >= 0xE;
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
