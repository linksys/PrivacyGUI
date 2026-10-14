/// What a MAC filter list must satisfy before it is written.
///
/// The firmware answers an over-limit or malformed list with only a generic 7012
/// and silently de-duplicates (linksys/PrivacyGUI#1612), so these checks run
/// client-side: in the service before a write, and in the views that cap the
/// list or validate a typed MAC.
///
/// A class rather than top-level functions because `normalizeMac` is also the
/// name of a different helper in topology.
abstract final class MacFilterRules {
  /// Firmware default (linksys/FWDEV#194); not exposed as a data-model path.
  static const int maxAddresses = 64;

  static final _macRegExp = RegExp(
    r'^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$',
  );

  static bool validateMac(String mac) => _macRegExp.hasMatch(mac.trim());

  /// Uppercase colon-separated canonical form. Precondition: passes [validateMac].
  static String normalizeMac(String mac) =>
      mac.trim().toUpperCase().replaceAll('-', ':');
}
