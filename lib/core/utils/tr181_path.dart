// Shared helpers for TR-181 object path manipulation.

/// Ensures a TR-181 instance path ends with a dot so paths from different
/// sources (codegen `instancePath`, `lowerLayers`, `ssidReference`, provider
/// maps) compare and look up consistently. Returns [path] unchanged when empty
/// or already dot-terminated.
String ensureTrailingDot(String path) {
  if (path.isEmpty) return path;
  return path.endsWith('.') ? path : '$path.';
}

/// [path] without its trailing dot, the form a reference parameter such as
/// `LowerLayers` holds (`Device.GRE.Tunnel.1.Interface.1`). Returns [path]
/// unchanged when it has none.
String withoutTrailingDot(String path) =>
    path.endsWith('.') ? path.substring(0, path.length - 1) : path;

/// The `Alias` of the LAN `Device.IP.Interface.{i}`.
const lanInterfaceAlias = 'lan';

/// The `Alias` of the WAN `Device.IP.Interface.{i}`.
const wanInterfaceAlias = 'wan';

final _interfaceAliasKey = RegExp(r'^Device\.IP\.Interface\.(\d+)\.Alias$');

/// `Alias` → `Device.IP.Interface.{i}.` (dot-terminated), from the response to
/// a `Device.IP.Interface.*.Alias` GET. An interface with an empty Alias is
/// left out; of two with the same Alias, the first in the response is kept.
Map<String, String> interfacePathsByAlias(Map<String, dynamic> aliases) {
  final byAlias = <String, String>{};
  for (final entry in aliases.entries) {
    final alias = entry.value;
    if (alias is! String || alias.isEmpty) continue;
    final instance = _interfaceAliasKey.firstMatch(entry.key)?.group(1);
    if (instance == null) continue;
    byAlias.putIfAbsent(alias, () => 'Device.IP.Interface.$instance.');
  }
  return byAlias;
}
