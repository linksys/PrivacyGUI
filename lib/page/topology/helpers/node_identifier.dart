/// Pure helpers that build stable, data-derived E2E `identifier` values for
/// topology nodes (constitution Article XVI §16.3).
///
/// Node identifiers are consumed by the E2E suite via `byIdentifier()` against
/// the CanvasKit Semantics tree, so they MUST be stable across
/// quality% / renderer / view-mode / node order and independent of the human
/// label. Per-instance keys are derived from the node's MAC (never a row
/// index), reduced to the shortest suffix that stays unique within the graph.
library;

/// Identifier for the master / gateway node. There is exactly one per topology,
/// so it carries no per-instance key.
const String kTopologyMasterIdentifier = 'topology-node-master';

/// Composes the slave / extender node identifier from a MAC suffix key.
String topologySlaveIdentifier(String macSuffix) =>
    'topology-node-slave-$macSuffix';

/// Composes the client node identifier from a MAC suffix key.
String topologyClientIdentifier(String macSuffix) =>
    'topology-node-client-$macSuffix';

/// Normalizes a MAC / device id to uppercase hex with every separator removed.
///
/// `aa:bb:cc:dd:ee:ff` → `AABBCCDDEEFF`. Any non-hex character (`:`, `-`, `.`,
/// whitespace, …) is stripped, so callers may pass raw `deviceId` / `mac`
/// values without pre-cleaning them.
String normalizeMac(String raw) =>
    raw.toUpperCase().replaceAll(RegExp('[^0-9A-F]'), '');

/// Maps each input MAC / id to the shortest hex suffix that is unique within
/// the group, keeping the derived identifier short yet collision-free.
///
/// - Inputs are normalized via [normalizeMac] (separators stripped, uppercased).
/// - A single group-wide suffix length is used, starting at [minLength]
///   (default 4) and growing in steps of [step] (default 2, MAC-octet aligned)
///   until every suffix in the group is distinct. One shared length keeps the
///   result deterministic and independent of input order.
/// - Genuine duplicates (two inputs that normalize identically) cannot be
///   disambiguated; both fall back to the full normalized value.
///
/// The returned map is keyed by the ORIGINAL input string (exactly as passed),
/// so callers can look up by `slave.deviceId` / `client.mac` directly. Empty
/// and duplicate inputs are tolerated.
Map<String, String> shortestUniqueMacSuffixes(
  Iterable<String> macs, {
  int minLength = 4,
  int step = 2,
}) {
  final originals = macs.toList();
  if (originals.isEmpty) return const {};

  final normalized = {for (final m in originals) m: normalizeMac(m)};
  final maxLen =
      normalized.values.fold<int>(0, (a, s) => s.length > a ? s.length : a);

  String suffixOf(String s, int len) =>
      s.length <= len ? s : s.substring(s.length - len);

  // Grow a single group-wide length until all suffixes are distinct.
  for (var len = minLength; len < maxLen; len += step) {
    final suffixes = normalized.values.map((s) => suffixOf(s, len)).toList();
    if (suffixes.toSet().length == suffixes.length) {
      return {
        for (final entry in normalized.entries)
          entry.key: suffixOf(entry.value, len),
      };
    }
  }

  // Full normalized value: covers the capped length and genuine-duplicate case.
  return normalized;
}
