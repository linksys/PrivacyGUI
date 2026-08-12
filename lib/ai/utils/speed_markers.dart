import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/utils/usp_formatters.dart';

/// A throughput figure paired with the direction marker that labels it.
typedef SpeedMarker = ({IconData icon, String text});

/// The down/up markers for a link, omitting either direction that has no rate.
///
/// The direction markers are [IconData], not the U+2193/U+2191 characters these
/// rates used to interpolate into a string: no bundled font maps those
/// codepoints, so the arrow only rendered if some font outside the declared set
/// happened to resolve it. Returning icons leaves the drawing to the caller,
/// which is what lets each section colour and lay them out its own way.
///
/// Absent and zero rates are dropped rather than rendered as `0`: a marker with
/// no figure behind it reads as "this link is idle", which is not what a missing
/// reading means.
///
/// Lives under `lib/ai/` rather than `lib/page/_shared/` because both callers
/// are AI sections. Per constitution Article V §5.3, `_shared/` is for code
/// referenced by two or more *unrelated* feature modules, and moving it there
/// preemptively is the thing that rule forbids. The direction-marker *choice*
/// is repeated outside this module (see #1183's icon sweep), so if one of those
/// sites converges on this helper, §5.3 then licenses the move.
List<SpeedMarker> speedMarkersFor({int? downlink, int? uplink}) => [
      for (final entry in [
        (icon: Icons.arrow_downward, speed: _label(downlink)),
        (icon: Icons.arrow_upward, speed: _label(uplink)),
      ])
        if (entry.speed != null) (icon: entry.icon, text: entry.speed!),
    ];

/// Formats a bits-per-second rate, or null when there is nothing to show.
///
/// Delegates to [UspFormatters] rather than tiering the units here — the repo
/// already has exactly one speed formatter and a second one would drift from it.
String? _label(int? bps) => bps == null || bps == 0
    ? null
    : UspFormatters.formatSpeed(bps / 1000, precision: 1);
