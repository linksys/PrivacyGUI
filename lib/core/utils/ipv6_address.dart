/// IPv6 address classification and ordering utilities.
///
/// Routers commonly expose several IPv6 addresses per interface (e.g. a
/// link-local `fe80::/10`, a Unique Local Address `fc00::/7`, and one or more
/// global unicast `2000::/3` addresses). The USP data model returns these in
/// TR-181 instance order, which is *not* preference order — the link-local
/// address is frequently instance 1. When the UI needs a single
/// "representative" address (e.g. the WAN IPv6 shown on the dashboard Network
/// Status widget), it must be the globally routable one, not the link-local.
///
/// This helper classifies addresses by their high-order bytes (mirroring the
/// scheme used by [Ipv6Rule] in `validator_rules/rules.dart`) and provides an
/// ordering that surfaces global unicast addresses first.
library;

import 'package:privacy_gui/core/utils/ipv6_ranges.dart';

/// IPv6 address scope categories, ordered by display preference
/// (lower [preference] wins).
enum Ipv6Scope {
  /// Global unicast (`2000::/3`) — routable on the public internet.
  global(0),

  /// Unique Local Address (`fc00::/7`) — routable within a site/organization.
  uniqueLocal(1),

  /// Link-local (`fe80::/10`) — only valid on the local link, not routable.
  linkLocal(2),

  /// Anything else (loopback, unspecified, multicast, unparseable, …).
  other(3);

  const Ipv6Scope(this.preference);

  /// Sort key — lower values are preferred for display.
  final int preference;
}

/// Classifies an IPv6 [address] string into an [Ipv6Scope].
///
/// Only the first two bytes are needed to distinguish global / ULA /
/// link-local, so a full parse is avoided. Returns [Ipv6Scope.other] for
/// addresses that cannot be classified (empty, IPv4, malformed).
Ipv6Scope classifyIpv6Scope(String address) {
  final bytes = _firstTwoBytes(address);
  if (bytes == null) return Ipv6Scope.other;

  final firstByte = bytes[0];
  final secondByte = bytes[1];

  // Deprecated / reserved ranges that fall inside 2000::/3 by first byte must
  // be excluded before the global-unicast test, matching IPv6WithReservedRule:
  //   * 3FFE::/16 — 6bone deprecated testing network (RFC 3701).
  //   * 5F00::/12 and 6000::/3–7FFF::/3 — reserved/unallocated.
  if (is6boneBytes(firstByte, secondByte) || isReservedGlobalByte(firstByte)) {
    return Ipv6Scope.other;
  }

  // Global unicast: 2000::/3  (first byte 0x20–0x3F).
  if (isGlobalUnicastByte(firstByte)) return Ipv6Scope.global;

  // Link-local: fe80::/10  (first byte 0xFE, top two bits of second byte = 10).
  if (isLinkLocalBytes(firstByte, secondByte)) return Ipv6Scope.linkLocal;

  // Unique Local Address: fc00::/7  (first byte 0xFC or 0xFD).
  if (isUniqueLocalByte(firstByte)) return Ipv6Scope.uniqueLocal;

  return Ipv6Scope.other;
}

/// Whether [address] is a globally routable (global unicast) IPv6 address.
bool isGlobalUnicastIpv6(String address) =>
    classifyIpv6Scope(address) == Ipv6Scope.global;

/// Returns [addresses] reordered so the most routable address comes first:
/// global unicast, then ULA, then link-local, then anything else. The relative
/// order of addresses that share a scope is preserved (stable sort), so the
/// original TR-181 instance order still acts as a tie-breaker.
List<String> preferGlobalIpv6First(Iterable<String> addresses) {
  final list = addresses.toList();
  // List.sort is not guaranteed stable, so decorate with the original index.
  final indexed = <MapEntry<int, String>>[
    for (var i = 0; i < list.length; i++) MapEntry(i, list[i]),
  ];
  indexed.sort((a, b) {
    final byScope = classifyIpv6Scope(a.value)
        .preference
        .compareTo(classifyIpv6Scope(b.value).preference);
    if (byScope != 0) return byScope;
    return a.key.compareTo(b.key); // stable tie-break on original position
  });
  return [for (final e in indexed) e.value];
}

/// Parses just the first two bytes of an IPv6 [address].
///
/// Handles `::` zero-compression and rejects obviously invalid input. Returns
/// `null` when the address cannot be parsed into at least one hextet.
List<int>? _firstTwoBytes(String address) {
  final trimmed = address.trim();
  if (trimmed.isEmpty) return null;

  // Strip a zone id / scope suffix (e.g. "fe80::1%eth0") and any prefix length.
  var s = trimmed.split('%').first.split('/').first;
  if (s.isEmpty) return null;

  // Reject anything that is not hex digits or colons (e.g. IPv4).
  if (!RegExp(r'^[0-9a-fA-F:]+$').hasMatch(s)) return null;

  // Only one '::' is allowed.
  if (s.indexOf('::') != s.lastIndexOf('::')) return null;

  // The first hextet is what determines the scope. Take the substring up to
  // the first ':' (or '::'); an address beginning with '::' has a zero first
  // hextet.
  String firstHextet;
  if (s.startsWith('::')) {
    firstHextet = '0';
  } else {
    final colon = s.indexOf(':');
    firstHextet = colon == -1 ? s : s.substring(0, colon);
    if (firstHextet.isEmpty) firstHextet = '0';
  }

  final value = int.tryParse(firstHextet, radix: 16);
  if (value == null || value < 0 || value > 0xFFFF) return null;

  return [(value >> 8) & 0xFF, value & 0xFF];
}
