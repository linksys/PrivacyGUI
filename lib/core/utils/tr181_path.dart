// Shared helpers for TR-181 object path manipulation.

/// Ensures a TR-181 instance path ends with a dot so paths from different
/// sources (codegen `instancePath`, `lowerLayers`, `ssidReference`, provider
/// maps) compare and look up consistently. Returns [path] unchanged when empty
/// or already dot-terminated.
String ensureTrailingDot(String path) {
  if (path.isEmpty) return path;
  return path.endsWith('.') ? path : '$path.';
}
