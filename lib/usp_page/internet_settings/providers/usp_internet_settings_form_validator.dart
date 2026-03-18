import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/usp_page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/usp_page/internet_settings/providers/usp_internet_settings_notifier.dart';

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
          (form.connectionTrigger != 'OnDemand' ||
              form.idleDisconnectTime > 0) &&
          (form.connectionTrigger != 'AlwaysOn' || form.lcpEchoInterval >= 0);
    case UspWanConnectionType.bridge:
      return true;
  }
}

bool _validateIpv6Fields(UspInternetSettingsForm form) {
  if (!form.ipv6rdEnabled) return true;
  return form.ipv6rdPrefix.isNotEmpty &&
      form.ipv6rdBorderRelay.isNotEmpty &&
      form.ipv6rdIpv4MaskLength >= 0 &&
      form.ipv6rdIpv4MaskLength <= 32;
}

bool _validateOptionalFields(UspInternetSettingsForm form) {
  // MTU: 0 = auto, otherwise must be in valid range
  if (form.mtu != 0 && (form.mtu < 576 || form.mtu > 1500)) return false;
  // MAC: empty = no clone, otherwise must be valid format
  if (form.wanMacAddress.isNotEmpty && !_isValidMac(form.wanMacAddress)) {
    return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Validators
// ---------------------------------------------------------------------------

final _ipv4Pattern = RegExp(
  r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
);

bool _isValidIpv4(String value) {
  if (value.isEmpty) return false;
  final match = _ipv4Pattern.firstMatch(value);
  if (match == null) return false;
  for (int i = 1; i <= 4; i++) {
    final octet = int.tryParse(match.group(i)!) ?? -1;
    if (octet < 0 || octet > 255) return false;
  }
  return true;
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
