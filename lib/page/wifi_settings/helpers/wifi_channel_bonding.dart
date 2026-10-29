/// IEEE 802.11 channel bonding rules for computing valid primary channels
/// per bandwidth.
///
/// This is a pure utility with no Flutter or provider dependencies.
/// All group tables are IEEE 802.11 standard constants.

/// Computes a map of bandwidth -> valid primary channels, filtered by
/// what the router actually supports ([possibleChannels]).
///
/// [band]: normalized band string ("2.4GHz", "5GHz", "6GHz")
/// [possibleChannels]: from Device.WiFi.Radio.{i}.PossibleChannels (parsed)
/// [supportedBandwidths]: from Device.WiFi.Radio.{i}.SupportedOperatingChannelBandwidths (parsed)
///
/// Returns: { "20MHz": [1,2,...], "40MHz": [1,5,9], "80MHz": [...], ... }
/// The "Auto" key always maps to all possibleChannels.
Map<String, List<int>> computeChannelsPerBandwidth({
  required String band,
  required List<int> possibleChannels,
  required List<String> supportedBandwidths,
}) {
  if (possibleChannels.isEmpty) return {};

  final result = <String, List<int>>{};
  final possibleSet = possibleChannels.toSet();

  // "Auto" always includes all possible channels.
  result['Auto'] = List.of(possibleChannels);

  // Determine which bandwidths to compute.
  // If supportedBandwidths is provided, use it; otherwise compute all known widths for the band.
  final widths = supportedBandwidths.isNotEmpty
      ? supportedBandwidths.where((bw) => bw != 'Auto').toList()
      : _defaultWidthsForBand(band);

  for (final bw in widths) {
    final channels = _channelsForBandwidth(band, bw, possibleSet);
    if (channels.isNotEmpty) {
      result[bw] = channels;
    }
  }

  return result;
}

List<String> _defaultWidthsForBand(String band) {
  return switch (band) {
    '2.4GHz' => ['20MHz', '40MHz'],
    '5GHz' => ['20MHz', '40MHz', '80MHz', '160MHz'],
    '6GHz' => ['20MHz', '40MHz', '80MHz', '160MHz'],
    _ => ['20MHz'],
  };
}

List<int> _channelsForBandwidth(String band, String bw, Set<int> possible) {
  return switch (band) {
    '2.4GHz' => _channels24(bw, possible),
    '5GHz' => _channels5(bw, possible),
    '6GHz' => _channels6(bw, possible),
    _ => possible.toList()..sort(),
  };
}

// ---------------------------------------------------------------------------
// 2.4 GHz bonding rules
// ---------------------------------------------------------------------------

List<int> _channels24(String bw, Set<int> possible) {
  return switch (bw) {
    '20MHz' => possible.toList()..sort(),
    '40MHz' => _filterByGroups(possible, _bondingGroups24_40),
    _ => possible.toList()..sort(),
  };
}

/// 2.4 GHz 40 MHz: HT40+ pairs.
/// A channel is a valid primary if its bonding partner (primary + 4) exists.
/// Standard pairs: (1,5), (2,6), (3,7), (4,8), (5,9), (6,10), (7,11), (8,12), (9,13).
const _bondingGroups24_40 = [
  [1, 5],
  [2, 6],
  [3, 7],
  [4, 8],
  [5, 9],
  [6, 10],
  [7, 11],
  [8, 12],
  [9, 13],
];

// ---------------------------------------------------------------------------
// 5 GHz bonding rules
// ---------------------------------------------------------------------------

List<int> _channels5(String bw, Set<int> possible) {
  return switch (bw) {
    '20MHz' => possible.toList()..sort(),
    '40MHz' => _filterByGroups(possible, _bondingGroups5_40),
    '80MHz' => _filterByGroups(possible, _bondingGroups5_80),
    '160MHz' => _filterByGroups(possible, _bondingGroups5_160),
    _ => possible.toList()..sort(),
  };
}

/// 5 GHz 40 MHz bonding pairs (IEEE 802.11n/ac/ax).
const _bondingGroups5_40 = [
  [36, 40],
  [44, 48],
  [52, 56],
  [60, 64],
  [100, 104],
  [108, 112],
  [116, 120],
  [124, 128],
  [132, 136],
  [140, 144],
  [149, 153],
  [157, 161],
  [165, 169],
  [173, 177],
];

/// 5 GHz 80 MHz bonding groups (IEEE 802.11ac/ax).
const _bondingGroups5_80 = [
  [36, 40, 44, 48],
  [52, 56, 60, 64],
  [100, 104, 108, 112],
  [116, 120, 124, 128],
  [132, 136, 140, 144],
  [149, 153, 157, 161],
  [165, 169, 173, 177],
];

/// 5 GHz 160 MHz bonding groups (IEEE 802.11ac Wave 2 / ax).
const _bondingGroups5_160 = [
  [36, 40, 44, 48, 52, 56, 60, 64],
  [100, 104, 108, 112, 116, 120, 124, 128],
];

// ---------------------------------------------------------------------------
// 6 GHz bonding rules
// ---------------------------------------------------------------------------

List<int> _channels6(String bw, Set<int> possible) {
  return switch (bw) {
    '20MHz' => possible.toList()..sort(),
    '40MHz' => _filterByGroups(possible, _build6GhzGroups(2)),
    '80MHz' => _filterByGroups(possible, _build6GhzGroups(4)),
    '160MHz' => _filterByGroups(possible, _build6GhzGroups(8)),
    '320MHz' => _filterByGroups(possible, _build6GhzGroups(16)),
    _ => possible.toList()..sort(),
  };
}

/// Builds 6 GHz bonding groups dynamically.
///
/// 6 GHz channels: 1, 5, 9, 13, 17, 21, ..., 229, 233 (step 4).
/// 20 MHz channels use all of them as primary.
/// 40 MHz pairs: [1,5], [9,13], [17,21], ... (groups of 2, step 8)
/// 80 MHz groups: [1,5,9,13], [17,21,25,29], ... (groups of 4, step 16)
/// 160 MHz groups: [1,5,9,13,17,21,25,29], ... (groups of 8, step 32)
/// 320 MHz groups: groups of 16, step 64
List<List<int>> _build6GhzGroups(int channelsPerGroup) {
  const firstChannel = 1;
  const channelStep = 4;
  const lastChannel = 233;
  final groupStep = channelsPerGroup * channelStep;

  final groups = <List<int>>[];
  for (var start = firstChannel; start <= lastChannel; start += groupStep) {
    final group = <int>[];
    for (var i = 0; i < channelsPerGroup; i++) {
      final ch = start + i * channelStep;
      if (ch <= lastChannel) group.add(ch);
    }
    if (group.length == channelsPerGroup) {
      groups.add(group);
    }
  }
  return groups;
}

// ---------------------------------------------------------------------------
// Shared group filter
// ---------------------------------------------------------------------------

/// Given a set of available channels and bonding group definitions,
/// returns all channels from [possible] that belong to a group where
/// at least 2 members (for pairs) or all members (for wider groups) are present.
///
/// For 40 MHz (2-member groups): both channels in the pair must exist.
/// For 80/160/320 MHz (4+): all channels in the group must exist.
List<int> _filterByGroups(Set<int> possible, List<List<int>> groups) {
  final result = <int>{};
  for (final group in groups) {
    final presentInGroup = group.where(possible.contains).toList();
    // For a bonding group to be valid, all members must be present.
    if (presentInGroup.length == group.length) {
      result.addAll(presentInGroup);
    }
  }
  final sorted = result.toList()..sort();
  return sorted;
}

// ---------------------------------------------------------------------------
// Wireless mode ↔ bandwidth constraints
// ---------------------------------------------------------------------------

/// Ordered bandwidth values from narrowest to widest.
const bandwidthOrder = ['20MHz', '40MHz', '80MHz', '160MHz', '320MHz'];

/// Returns the numeric index of a bandwidth string in [bandwidthOrder].
/// "Auto" returns the highest index (no filtering). Unknown values return -1.
int bandwidthIndex(String bw) {
  if (bw == 'Auto') return bandwidthOrder.length; // Auto = no constraint
  return bandwidthOrder.indexOf(bw);
}

/// Maximum bandwidth supported by each IEEE 802.11 standard amendment.
const _maxBandwidthByStandard = {
  'b': '20MHz',
  'g': '20MHz',
  'a': '20MHz',
  'n': '40MHz',
  'ac': '160MHz',
  'ax': '160MHz',
  'be': '320MHz',
};

/// Returns the maximum bandwidth the given operating standards can support.
///
/// [operatingStandards] can be comma-separated ("a,n,ac,ax") or concatenated
/// ("anacax"). Returns "20MHz" for empty/unknown input.
String maxBandwidthForStandards(String operatingStandards) {
  if (operatingStandards.isEmpty) return '320MHz'; // "mixed" = no limit

  final standards = _parseStandardsSet(operatingStandards);
  var maxIdx = 0;
  for (final std in standards) {
    final bw = _maxBandwidthByStandard[std];
    if (bw != null) {
      final idx = bandwidthOrder.indexOf(bw);
      if (idx > maxIdx) maxIdx = idx;
    }
  }
  return bandwidthOrder[maxIdx];
}

/// Returns the minimum WiFi standard needed to support the given [bandwidth].
///
/// Used for bidirectional filtering: selecting 80MHz requires at least 802.11ac.
/// Returns null for "Auto" or "20MHz" (any standard works).
String? minStandardForBandwidth(String bandwidth) {
  if (bandwidth == 'Auto' || bandwidth.isEmpty) return null;
  final idx = bandwidthOrder.indexOf(bandwidth);
  if (idx <= 0) return null; // 20MHz or unknown
  if (idx == 1) return 'n'; // 40MHz
  if (idx <= 3) return 'ac'; // 80MHz, 160MHz
  return 'be'; // 320MHz
}

/// Parses a wireless standards string into a normalized Set.
///
/// Handles comma-separated ("a,n,ac,ax") and concatenated ("anacax").
Set<String> _parseStandardsSet(String raw) {
  final lower = raw.toLowerCase().trim();
  if (lower == 'mixed') return _maxBandwidthByStandard.keys.toSet();

  if (lower.contains(',')) {
    return lower
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();
  }

  // Concatenated form: try to parse known standard names
  const known = ['be', 'ax', 'ac', 'n', 'g', 'b', 'a'];
  final found = <String>{};
  var remaining = lower;
  for (final std in known) {
    while (remaining.contains(std)) {
      found.add(std);
      remaining = remaining.replaceFirst(std, '');
    }
  }
  return found;
}
