/// Single source of truth for IPv6 high-order byte-range classification.
///
/// Two independent call sites classify IPv6 addresses by their first two
/// bytes and had drifted into duplicated magic constants:
///   * [classifyIpv6Scope] in `core/utils/ipv6_address.dart` (display ordering)
///   * [IPv6WithReservedRule] in `validator_rules/rules.dart` (input validation)
///
/// The predicates below are the shared definition of those ranges so the two
/// callers cannot diverge. Each takes already-parsed bytes (0–0xFF) — parsing
/// remains the caller's responsibility.
library;

/// Global unicast — `2000::/3` (first byte `0x20`–`0x3F`).
bool isGlobalUnicastByte(int firstByte) =>
    firstByte >= 0x20 && firstByte <= 0x3F;

/// Link-local — `fe80::/10` (first byte `0xFE`, top two bits of the second
/// byte are `10`).
bool isLinkLocalBytes(int firstByte, int secondByte) =>
    firstByte == 0xFE && (secondByte & 0xC0) == 0x80;

/// Unique Local Address — `fc00::/7` (first byte `0xFC` or `0xFD`).
bool isUniqueLocalByte(int firstByte) => firstByte == 0xFC || firstByte == 0xFD;

/// 6bone deprecated IPv6 testing network — `3FFE::/16` (RFC 3701). This falls
/// inside the `2000::/3` global-unicast range by first byte, so it must be
/// excluded explicitly before applying [isGlobalUnicastByte].
bool is6boneBytes(int firstByte, int secondByte) =>
    firstByte == 0x3F && secondByte == 0xFE;

/// Reserved / unallocated space adjacent to the global-unicast range
/// (e.g. `5F00::/12`, `6000::/3`–`7FFF::/3`) — first byte `0x5F`–`0x7F`.
/// These already fall outside [isGlobalUnicastByte]; the predicate exists so
/// validators that must reject them share one definition.
bool isReservedGlobalByte(int firstByte) =>
    firstByte >= 0x5F && firstByte <= 0x7F;
