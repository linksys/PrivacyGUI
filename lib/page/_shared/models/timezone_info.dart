/// Formats a UTC offset in minutes as `GMT±HH:MM`.
///
/// Top-level rather than a member of [TimeZoneInfo] because the cards need it
/// for an offset that has no [TimeZoneInfo] at all — the one the device reported
/// alongside its clock, which is all we can say about a zone our table does not
/// carry (#1609). Not localized on purpose: the output is a numeric offset and a
/// unit abbreviation used verbatim in every locale we ship, the same reasoning
/// that keeps `offsetDisplayText` out of the ARB files.
String formatGmtOffset(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final abs = minutes.abs();
  final hh = (abs ~/ 60).toString().padLeft(2, '0');
  final mm = (abs % 60).toString().padLeft(2, '0');
  return 'GMT$sign$hh:$mm';
}

/// Time zone information model for timezone selection.
class TimeZoneInfo {
  final String timeZoneID;
  final int utcOffsetMinutes;
  final bool observesDST;
  final String description;

  /// Legacy POSIX forms, kept for *reading* only (#1609).
  ///
  /// These are what releases up to 2.7.1 wrote, so routers in the field still
  /// hold them and [matchTimezone] must go on recognising them. They are no
  /// longer what we write, because `UTC±N` carries an offset but no identity:
  /// eleven of these strings are each shared by two or three zones, so a saved
  /// zone came back wearing another zone's name.
  final String posixNoDST;
  final String posixWithDST;

  /// The IANA zone we write to `Device.Time.X_LINKSYS_LocalTimeZoneName`, or
  /// null when this entry has no faithful one.
  ///
  /// This is the identity that fixes the relabelling: the firmware derives the
  /// POSIX string from it (`Asia/Taipei` → `CST-8`, `America/New_York` →
  /// `EST5EDT,M3.2.0,M11.1.0`, DST rule included) and hands the name straight
  /// back on a read, so what was chosen is what returns. A POSIX string cannot
  /// do that — `EST5` *is* Panama as far as the device is concerned.
  ///
  /// Null on the three entries whose own offset or DST flag disagrees with the
  /// tz database, where no IANA name would mean what the label says; those keep
  /// writing [posixNoDST]/[posixWithDST] until the data is settled. See
  /// `kTimeZoneDefinitions` for which and why.
  final String? ianaName;

  /// What to write when the user switches daylight savings **off** on a zone
  /// that observes it — this zone's own standard-time POSIX string.
  ///
  /// Null on a zone whose daylight savings cannot be switched off, which is a
  /// firmware limit and not a choice: the validator accepts a string only if it
  /// is in `X_LINKSYS_SupportedZones` or parses as POSIX, and it rejects `CLT4`,
  /// `NST3:30`, `BRT3` and `AZOT1` on both counts — those abbreviations are
  /// obsolete in modern tzdata, which now spells those zones `-04`, `-03` and
  /// `-01`. The switch is disabled for them. Measured on the bench, 2026-09-22.
  ///
  /// This is what makes the switch safe to keep at all (#1609). Switching off
  /// used to write [posixNoDST], a bare `UTC±N` that carries an offset and no
  /// identity, so the zone came back as whichever of the two or three zones
  /// sharing that string `matchTimezone` reached first. A zone's own
  /// abbreviation is unambiguous, because [matchTimezone] tries `timeZoneID`
  /// before anything else and these strings *are* the ids. The sibling non-DST
  /// zone at the same offset is not in the way either: it writes its
  /// [ianaName], on the other leaf entirely.
  final String? standardTimePosix;

  const TimeZoneInfo({
    required this.timeZoneID,
    required this.utcOffsetMinutes,
    required this.observesDST,
    required this.description,
    required this.posixNoDST,
    required this.posixWithDST,
    this.ianaName,
    this.standardTimePosix,
  });

  /// Whether the daylight-savings switch can be operated for this zone.
  bool get canSwitchDstOff => observesDST && standardTimePosix != null;

  /// Human-readable name without the leading "(GMT±HH:MM) " prefix.
  /// e.g. "(GMT+08:00) Singapore, Taiwan, Russia" → "Singapore, Taiwan, Russia"
  String get friendlyName {
    final match = RegExp(r'^\(GMT[^)]*\)\s*').firstMatch(description);
    if (match != null) {
      return description.substring(match.end);
    }
    return description;
  }

  /// Display format: "GMT±HH:MM"
  String get offsetDisplayText => formatGmtOffset(utcOffsetMinutes);

  /// Returns the POSIX string based on whether DST is enabled.
  String posixFor({required bool dstEnabled}) {
    if (!observesDST) return posixNoDST;
    return dstEnabled ? posixWithDST : posixNoDST;
  }

  @override
  String toString() => '$friendlyName ($offsetDisplayText)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeZoneInfo &&
          runtimeType == other.runtimeType &&
          timeZoneID == other.timeZoneID;

  @override
  int get hashCode => timeZoneID.hashCode;
}
