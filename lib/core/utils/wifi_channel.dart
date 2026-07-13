// Shared WiFi channel helpers: TR-181 PossibleChannels parsing and DFS
// (IEEE 802.11h) channel classification/filtering. Pure functions with no
// Flutter or provider dependencies — safe to import from services and widgets.

/// Parses a TR-181 `PossibleChannels` string into a sorted list of channel
/// numbers. Handles comma-separated values and range notation.
/// e.g. "1-13,36,40,44,48" → [1,2,3,4,5,6,7,8,9,10,11,12,13,36,40,44,48]
List<int> parsePossibleChannels(String raw) {
  if (raw.isEmpty) return const [];
  final result = <int>[];
  for (final part in raw.split(',')) {
    final trimmed = part.trim();
    if (trimmed.contains('-')) {
      final bounds = trimmed.split('-');
      // Skip malformed range tokens (e.g. "1-2-3").
      if (bounds.length != 2) continue;
      final start = int.tryParse(bounds[0].trim());
      final end = int.tryParse(bounds[1].trim());
      if (start != null && end != null) {
        // Inverted ranges (start > end) naturally yield nothing.
        for (var i = start; i <= end; i++) {
          result.add(i);
        }
      }
    } else {
      final ch = int.tryParse(trimmed);
      if (ch != null) result.add(ch);
    }
  }
  // Drop non-positive channels: TR-181 PossibleChannels "0" is an auto/any
  // sentinel, not a real channel, and channel 0 must never reach the dropdown
  // or be sent to firmware.
  result.removeWhere((ch) => ch <= 0);
  result.sort();
  return result;
}

/// 5 GHz DFS channels (IEEE 802.11h): UNII-2A (52–64) + UNII-2C (100–144).
/// These are the only channels subject to Dynamic Frequency Selection; 2.4 GHz
/// and 6 GHz channels are never DFS.
///
/// Regulatory scope: this is the US/FCC (UNII-2A/2C) set. Other domains differ
/// (e.g. ETSI weather-radar restrictions, MIC/Japan assignments) — extend or
/// parameterize per regulatory domain if multi-market support is required.
const Set<int> dfsChannels5GHz = {
  52, 56, 60, 64, //
  100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140, 144,
};

/// True only for 5 GHz DFS channels. [band] is the normalized band string
/// ("2.4GHz" / "5GHz" / "6GHz").
bool isDfsChannel(int channel, {required String band}) =>
    band == '5GHz' && dfsChannels5GHz.contains(channel);

/// Removes DFS channels when DFS is disabled. Returns [channels] unchanged when
/// DFS is enabled or when the band is not 5 GHz (DFS applies only to 5 GHz).
///
/// The firmware does not trim `PossibleChannels` by DFS state, and TR-181
/// exposes no DFS-vs-non-DFS channel field, so the client filters here.
List<int> filterDfsChannels(
  List<int> channels, {
  required String band,
  required bool dfsEnabled,
}) =>
    (dfsEnabled || band != '5GHz')
        ? channels
        : channels.where((ch) => !dfsChannels5GHz.contains(ch)).toList();
