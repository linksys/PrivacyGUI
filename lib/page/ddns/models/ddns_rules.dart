import 'dart:convert';

import 'package:privacy_gui/page/ddns/models/ddns_settings.dart';
import 'package:privacy_gui/util/network_utils.dart';

/// The checks LinksysWRT 1.0 made on the DDNS form, and the address rule of
/// the router's updater, as pure functions shared by the page and its tests.
///
/// The FLWRT setters check only lengths (linksys/FWDEV#191 implementation doc
/// §8.1), so these checks are what keeps a save from writing a value 1.0
/// refused. Every save from the page then applies in full: a wrong password or
/// a host name the provider does not know is not a save error, and the status
/// reports it after the save.

/// The longest user name or password the page sends, in UTF-8 bytes: the
/// `ddnsmngr` setters refuse a value over 256 (linksys/FWDEV#191
/// implementation doc §8.1).
const int kDdnsCredentialMaxBytes = 256;

/// One host name label: a letter or digit, then at most 61 letters, digits or
/// `-`, ending in a letter or digit. All-digit labels are allowed.
const String _label = r'[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?';

/// 1.0's host name rule (`util.isValidHostName`), spelled as the router's
/// updater spells it (`ddns_valid_hostname`, feed_usp patch 9000).
final RegExp _hostnamePattern = RegExp('^$_label(\\.$_label)*\$');

/// The form fields 1.0 checked.
enum DdnsField { username, password, hostname }

/// Whether [value] is a host name 1.0 accepted: 1 to 255 characters, labels of
/// 1 to 63 letters, digits and `-` that neither start nor end with `-`,
/// separated by single dots. A single label passes; an empty label (a leading,
/// trailing or doubled dot), `_` and spaces do not.
///
/// The router's updater applies the same rule to whatever is stored, and
/// reports a name that fails it as Invalid host name without sending it.
bool isValidDdnsHostname(String value) =>
    value.isNotEmpty && value.length <= 255 && _hostnamePattern.hasMatch(value);

/// Whether [value] is a user name or password 1.0 accepted: not empty, and no
/// longer than the router stores.
///
/// The limit is counted in UTF-8 bytes, the stricter reading of the setter's
/// 256: whether it counts bytes or characters has not been measured, and
/// counting bytes can only refuse here what the setter might refuse mid-save.
/// A non-Latin value of more than 256 bytes but at most 256 characters is
/// refused here even if the router would take it.
bool isValidDdnsCredential(String value) =>
    value.isNotEmpty && utf8.encode(value).length <= kDdnsCredentialMaxBytes;

/// The fields of [settings] that fail 1.0's checks; empty when it can be
/// saved.
///
/// "Disabled" checks nothing, because it writes only `Enable`. The password may
/// be left empty while the account is the one the router holds
/// ([DdnsSettings.canKeepStoredPassword]): an empty password is not sent, so
/// the stored one is kept.
Set<DdnsField> invalidDdnsFields(DdnsSettings settings) {
  if (!settings.isEnabled) return const {};
  final keepsStoredPassword =
      settings.password.isEmpty && settings.canKeepStoredPassword;
  return {
    if (!isValidDdnsCredential(settings.username)) DdnsField.username,
    if (!keepsStoredPassword && !isValidDdnsCredential(settings.password))
      DdnsField.password,
    if (!isValidDdnsHostname(settings.hostname)) DdnsField.hostname,
  };
}

/// Whether [address] is an IPv4 address the router's updater will not publish
/// because it is private: `0.0.0.0/8`, `10.0.0.0/8`, `100.64.0.0/10`,
/// `127.0.0.0/8`, `169.254.0.0/16`, `172.16.0.0/12` and `192.168.0.0/16`.
///
/// The ranges are ddns-scripts' `send_update` check, which the router runs as
/// shipped (`upd_privateip` 0). A client behind such an address reads
/// `Error` + `CONNECTION_ERROR`, which the page shows as Failed; this is what
/// lets it say why. Anything that is not an IPv4 address is not private.
bool isPrivateIpv4Address(String address) {
  if (!NetworkUtils.isValidIpAddress(address)) return false;
  final octets = address.split('.').map(int.parse).toList();
  final first = octets[0];
  final second = octets[1];
  return first == 0 ||
      first == 10 ||
      (first == 100 && second >= 64 && second <= 127) ||
      first == 127 ||
      (first == 169 && second == 254) ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168);
}
