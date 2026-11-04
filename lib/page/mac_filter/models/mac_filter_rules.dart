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

  /// The accepted spellings of one MAC, each 12 hex digits in either case:
  /// pairs separated by `:` or `-`, bare (`AABBCCDDEEFF`, #1737), or groups of
  /// four separated by `.` (`aabb.ccdd.eeff`, #1737).
  static final _macForms = [
    RegExp(r'^([0-9A-Fa-f]{2}[:\-]){5}[0-9A-Fa-f]{2}$'),
    RegExp(r'^[0-9A-Fa-f]{12}$'),
    RegExp(r'^[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}\.[0-9A-Fa-f]{4}$'),
  ];

  static final _separators = RegExp(r'[:\-.]');

  /// What part of a MAC can be typed as: hex digits and the separators above.
  static final _macFragment = RegExp(r'^[0-9A-Fa-f:\-.]+$');
  static final _nonHex = RegExp(r'[^0-9A-Fa-f]');

  /// A dotted-decimal IPv4 address or the start of one: `192.`, `192.168`,
  /// `192.168.1.16`. Every group has at most three decimal digits, while the
  /// dotted MAC spelling groups four hex digits, so the two never overlap once
  /// a `.` is typed.
  static final _ipShaped = RegExp(r'^\d{1,3}(\.\d{0,3}){1,3}$');

  /// Whether [mac] is one MAC in an accepted spelling. Surrounding whitespace is
  /// ignored.
  static bool validateMac(String mac) {
    final value = mac.trim();
    return _macForms.any((form) => form.hasMatch(value));
  }

  /// Uppercase colon-separated canonical form, `AA:BB:CC:DD:EE:FF`, of any
  /// spelling [validateMac] accepts.
  ///
  /// Precondition: passes [validateMac]. Anything else is only trimmed,
  /// upper-cased and has `-` turned into `:`, as it always was, so a caller that
  /// passes a malformed value through still sees its own text.
  static String normalizeMac(String mac) {
    final value = mac.trim().toUpperCase();
    if (!validateMac(value)) return value.replaceAll('-', ':');
    final hex = value.replaceAll(_separators, '');
    return [for (var i = 0; i < 12; i += 2) hex.substring(i, i + 2)].join(':');
  }

  /// Whether [query], typed as part of a MAC in any accepted spelling, is found
  /// in [mac]: separators and case are ignored on both sides, so `aabb`,
  /// `aa-bb` and `AABB.CC` all find `AA:BB:CC:DD:EE:FF` (#1737).
  ///
  /// False for a query with anything but hex digits and separators in it. A
  /// name such as `Pixel` reduced to its hex digits is `e`, which most MACs
  /// contain.
  ///
  /// Also false for a query shaped like an IP address (`192.168`): it is an IP
  /// search, and IP search stays as it was (#1737 AC6). Read as digits it would
  /// find any MAC containing `192168`.
  static bool macContains(String mac, String query) {
    if (!_macFragment.hasMatch(query)) return false;
    if (_ipShaped.hasMatch(query)) return false;
    final digits = query.replaceAll(_nonHex, '').toLowerCase();
    return digits.isNotEmpty &&
        mac.replaceAll(_nonHex, '').toLowerCase().contains(digits);
  }
}
