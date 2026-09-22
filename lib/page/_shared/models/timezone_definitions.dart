import 'package:privacy_gui/page/_shared/models/timezone_info.dart';

/// All 39 supported timezones, sorted by UTC offset (GMT-12:00 → GMT+12:00).
///
/// POSIX strings sourced from:
/// - feed_uspapi#12 verified results (5 DST + 9 UTC patterns)
/// - Standard regional DST rules for remaining 10 DST timezones
const List<TimeZoneInfo> kTimeZoneDefinitions = [
  // GMT-12:00
  TimeZoneInfo(
    timeZoneID: 'MHT12-NO-DST',
    utcOffsetMinutes: -720,
    observesDST: false,
    description: '(GMT-12:00) Kwajalein',
    posixNoDST: 'UTC12',
    posixWithDST: 'UTC12',
    // No `ianaName`: Kwajalein has been UTC+12 since 1993, so nothing in
    // the tz database sits at GMT-12:00 and no IANA name would mean what
    // this label says. Keeps writing POSIX until the data is settled (#1609).
  ),
  // GMT-11:00
  TimeZoneInfo(
    timeZoneID: 'WST11-NO-DST',
    utcOffsetMinutes: -660,
    observesDST: false,
    description: '(GMT-11:00) Midway Island, Samoa',
    posixNoDST: 'UTC11',
    posixWithDST: 'UTC11',
    ianaName: 'Pacific/Midway',
  ),
  // GMT-10:00
  TimeZoneInfo(
    timeZoneID: 'HST10-NO-DST',
    utcOffsetMinutes: -600,
    observesDST: false,
    description: '(GMT-10:00) Hawaii',
    posixNoDST: 'UTC10',
    posixWithDST: 'UTC10',
    ianaName: 'Pacific/Honolulu',
  ),
  // GMT-09:00
  TimeZoneInfo(
    timeZoneID: 'AKST9',
    utcOffsetMinutes: -540,
    observesDST: true,
    description: '(GMT-09:00) Alaska',
    posixNoDST: 'UTC9',
    posixWithDST: 'AKST9AKDT,M3.2.0/02:00,M11.1.0/02:00',
    ianaName: 'America/Anchorage',
    standardTimePosix: 'AKST9',
  ),
  // GMT-08:00
  TimeZoneInfo(
    timeZoneID: 'PST8',
    utcOffsetMinutes: -480,
    observesDST: true,
    description: '(GMT-08:00) Pacific Time (USA & Canada)',
    posixNoDST: 'UTC8',
    posixWithDST: 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00',
    ianaName: 'America/Los_Angeles',
    standardTimePosix: 'PST8',
  ),
  // GMT-07:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'MST7',
    utcOffsetMinutes: -420,
    observesDST: true,
    description: '(GMT-07:00) Mountain Time (USA & Canada)',
    posixNoDST: 'UTC7',
    posixWithDST: 'MST7MDT,M3.2.0/02:00,M11.1.0/02:00',
    ianaName: 'America/Denver',
    standardTimePosix: 'MST7',
  ),
  // GMT-07:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'MST7-NO-DST',
    utcOffsetMinutes: -420,
    observesDST: false,
    description: '(GMT-07:00) Arizona',
    posixNoDST: 'UTC7',
    posixWithDST: 'UTC7',
    ianaName: 'America/Phoenix',
  ),
  // GMT-06:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'CST6',
    utcOffsetMinutes: -360,
    observesDST: true,
    description: '(GMT-06:00) Central Time (USA & Canada)',
    posixNoDST: 'UTC6',
    posixWithDST: 'CST6CDT,M3.2.0/02:00,M11.1.0/02:00',
    ianaName: 'America/Chicago',
    standardTimePosix: 'CST6',
  ),
  // GMT-06:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'CST6-NO-DST',
    utcOffsetMinutes: -360,
    observesDST: false,
    description: '(GMT-06:00) Mexico',
    posixNoDST: 'UTC6',
    posixWithDST: 'UTC6',
    ianaName: 'America/Mexico_City',
  ),
  // GMT-05:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'EST5',
    utcOffsetMinutes: -300,
    observesDST: true,
    description: '(GMT-05:00) Eastern Time (USA & Canada)',
    posixNoDST: 'UTC5',
    posixWithDST: 'EST5EDT,M3.2.0/02:00,M11.1.0/02:00',
    ianaName: 'America/New_York',
    standardTimePosix: 'EST5',
  ),
  // GMT-05:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'EST5-NO-DST',
    utcOffsetMinutes: -300,
    observesDST: false,
    description: '(GMT-05:00) Indiana East, Colombia, Panama',
    posixNoDST: 'UTC5',
    posixWithDST: 'UTC5',
    ianaName: 'America/Panama',
  ),
  // GMT-04:00 (DST — Atlantic)
  TimeZoneInfo(
    timeZoneID: 'AST4',
    utcOffsetMinutes: -240,
    observesDST: true,
    description:
        '(GMT-04:00) Atlantic Time (Canada, Greenland, Atlantic Islands)',
    posixNoDST: 'UTC4',
    posixWithDST: 'AST4ADT,M3.2.0/02:00,M11.1.0/02:00',
    ianaName: 'America/Halifax',
    standardTimePosix: 'AST4',
  ),
  // GMT-04:00 (DST — Chile)
  TimeZoneInfo(
    timeZoneID: 'CLT4',
    utcOffsetMinutes: -240,
    observesDST: true,
    description: '(GMT-04:00) Chile Time (Chile, Antarctica)',
    posixNoDST: 'UTC4',
    posixWithDST: 'CLT4CLST,M10.2.6/00:00,M3.2.6/00:00',
    ianaName: 'America/Santiago',
    // No `standardTimePosix`: the firmware rejects `CLT4` — Chile is
    // `-04` in modern tzdata and the old abbreviation parses as neither
    // a supported zone nor POSIX, so daylight savings cannot be
    // switched off here (#1609).
  ),
  // GMT-04:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'VET4-NO-DST',
    utcOffsetMinutes: -240,
    observesDST: false,
    description: '(GMT-04:00) Bolivia, Venezuela',
    posixNoDST: 'UTC4',
    posixWithDST: 'UTC4',
    ianaName: 'America/Caracas',
  ),
  // GMT-03:30 (DST)
  TimeZoneInfo(
    timeZoneID: 'NST03:30',
    utcOffsetMinutes: -210,
    observesDST: true,
    description: '(GMT-03:30) Newfoundland',
    posixNoDST: 'UTC3:30',
    posixWithDST: 'NST3:30NDT,M3.2.0/00:01,M11.1.0/00:01',
    ianaName: 'America/St_Johns',
    // No `standardTimePosix`: the firmware rejects both `NST03:30` and
    // `NST3:30`, and its zone list has no UTC-03:30 row without a DST
    // rule, so there is nothing to write (#1609).
  ),
  // GMT-03:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'BRT3',
    utcOffsetMinutes: -180,
    observesDST: true,
    description: '(GMT-03:00) Brazil East, Greenland',
    posixNoDST: 'UTC3',
    posixWithDST: 'BRT3BRST,M10.3.0/00:00,M2.3.0/00:00',
    // No `ianaName`: Brazil abolished DST in 2019, so `America/Sao_Paulo`
    // reports no DST rule and would contradict `observesDST: true` here.
    // Keeps writing POSIX until the data is settled (#1609).
    // No `standardTimePosix`: the firmware rejects `BRT3` — Brazil is
    // `-03` in modern tzdata. Note this entry also claims DST that
    // Brazil abolished in 2019, which is the data question above (#1609).
  ),
  // GMT-03:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'ART3-NO-DST',
    utcOffsetMinutes: -180,
    observesDST: false,
    description: '(GMT-03:00) Guyana',
    posixNoDST: 'UTC3',
    posixWithDST: 'UTC3',
    // No `ianaName`: Guyana is UTC-4, not the GMT-03:00 this entry claims,
    // so `America/Guyana` would move the clock an hour from what the label
    // promises. Keeps writing POSIX until the data is settled (#1609).
  ),
  // GMT-02:00
  TimeZoneInfo(
    timeZoneID: 'MAT2-NO-DST',
    utcOffsetMinutes: -120,
    observesDST: false,
    description: '(GMT-02:00) Mid-Atlantic',
    posixNoDST: 'UTC2',
    posixWithDST: 'UTC2',
    ianaName: 'Atlantic/South_Georgia',
  ),
  // GMT-01:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'AZOT1',
    utcOffsetMinutes: -60,
    observesDST: true,
    description: '(GMT-01:00) Azores',
    posixNoDST: 'UTC1',
    posixWithDST: 'AZOT1AZOST,M3.5.0/00:00,M10.5.0/01:00',
    ianaName: 'Atlantic/Azores',
    // No `standardTimePosix`: the firmware rejects `AZOT1` — the Azores
    // are `-01` in modern tzdata (#1609).
  ),
  // GMT+00:00 (DST — England)
  TimeZoneInfo(
    timeZoneID: 'GMT0',
    utcOffsetMinutes: 0,
    observesDST: true,
    description: '(GMT) England',
    posixNoDST: 'UTC0',
    posixWithDST: 'GMT0BST,M3.5.0/01:00,M10.5.0/02:00',
    ianaName: 'Europe/London',
    standardTimePosix: 'GMT0',
  ),
  // GMT+00:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'GMT0-NO-DST',
    utcOffsetMinutes: 0,
    observesDST: false,
    description: '(GMT) Gambia, Liberia, Morocco',
    posixNoDST: 'UTC0',
    posixWithDST: 'UTC0',
    ianaName: 'Africa/Monrovia',
  ),
  // GMT+01:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'CET-1',
    utcOffsetMinutes: 60,
    observesDST: true,
    description: '(GMT+01:00) France, Germany, Italy',
    posixNoDST: 'UTC-1',
    posixWithDST: 'CET-1CEST,M3.5.0/02:00,M10.5.0/03:00',
    ianaName: 'Europe/Paris',
    standardTimePosix: 'CET-1',
  ),
  // GMT+01:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'CET-1-NO-DST',
    utcOffsetMinutes: 60,
    observesDST: false,
    description: '(GMT+01:00) Tunisia',
    posixNoDST: 'UTC-1',
    posixWithDST: 'UTC-1',
    ianaName: 'Africa/Tunis',
  ),
  // GMT+02:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'EET-2',
    utcOffsetMinutes: 120,
    observesDST: true,
    description: '(GMT+02:00) Greece, Ukraine, Romania, Turkey',
    posixNoDST: 'UTC-2',
    posixWithDST: 'EET-2EEST,M3.5.0/03:00,M10.5.0/04:00',
    ianaName: 'Europe/Athens',
    standardTimePosix: 'EET-2',
  ),
  // GMT+02:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'SAST-2-NO-DST',
    utcOffsetMinutes: 120,
    observesDST: false,
    description: '(GMT+02:00) South Africa',
    posixNoDST: 'UTC-2',
    posixWithDST: 'UTC-2',
    ianaName: 'Africa/Johannesburg',
  ),
  // GMT+03:00
  TimeZoneInfo(
    timeZoneID: 'AST-3-NO-DST',
    utcOffsetMinutes: 180,
    observesDST: false,
    description: '(GMT+03:00) Iraq, Jordan, Kuwait',
    posixNoDST: 'UTC-3',
    posixWithDST: 'UTC-3',
    ianaName: 'Asia/Baghdad',
  ),
  // GMT+04:00
  TimeZoneInfo(
    timeZoneID: 'GST-4-NO-DST',
    utcOffsetMinutes: 240,
    observesDST: false,
    description: '(GMT+04:00) Armenia',
    posixNoDST: 'UTC-4',
    posixWithDST: 'UTC-4',
    ianaName: 'Asia/Yerevan',
  ),
  // GMT+05:00
  TimeZoneInfo(
    timeZoneID: 'PKT-5-NO-DST',
    utcOffsetMinutes: 300,
    observesDST: false,
    description: '(GMT+05:00) Pakistan, Russia',
    posixNoDST: 'UTC-5',
    posixWithDST: 'UTC-5',
    ianaName: 'Asia/Karachi',
  ),
  // GMT+05:30
  TimeZoneInfo(
    timeZoneID: 'IST-05:30-NO-DST',
    utcOffsetMinutes: 330,
    observesDST: false,
    description: '(GMT+05:30) Bombay, Kalkutta, Madras, Neu Delhi',
    posixNoDST: 'UTC-5:30',
    posixWithDST: 'UTC-5:30',
    ianaName: 'Asia/Kolkata',
  ),
  // GMT+06:00
  TimeZoneInfo(
    timeZoneID: 'ALMT-6-NO-DST',
    utcOffsetMinutes: 360,
    observesDST: false,
    description: '(GMT+06:00) Bangladesh, Russia',
    posixNoDST: 'UTC-6',
    posixWithDST: 'UTC-6',
    ianaName: 'Asia/Dhaka',
  ),
  // GMT+07:00
  TimeZoneInfo(
    timeZoneID: 'ICT-7-NO-DST',
    utcOffsetMinutes: 420,
    observesDST: false,
    description: '(GMT+07:00) Thailand, Russia',
    posixNoDST: 'UTC-7',
    posixWithDST: 'UTC-7',
    ianaName: 'Asia/Bangkok',
  ),
  // GMT+08:00 (China/HK)
  TimeZoneInfo(
    timeZoneID: 'HKT-8-NO-DST',
    utcOffsetMinutes: 480,
    observesDST: false,
    description: '(GMT+08:00) China, Hong Kong, Australia Western',
    posixNoDST: 'UTC-8',
    posixWithDST: 'UTC-8',
    ianaName: 'Asia/Hong_Kong',
  ),
  // GMT+08:00 (Singapore/Taiwan)
  TimeZoneInfo(
    timeZoneID: 'SGT-8-NO-DST',
    utcOffsetMinutes: 480,
    observesDST: false,
    description: '(GMT+08:00) Singapore, Taiwan, Russia',
    posixNoDST: 'UTC-8',
    posixWithDST: 'UTC-8',
    ianaName: 'Asia/Singapore',
  ),
  // GMT+09:00
  TimeZoneInfo(
    timeZoneID: 'JST-9-NO-DST',
    utcOffsetMinutes: 540,
    observesDST: false,
    description: '(GMT+09:00) Japan, Korea',
    posixNoDST: 'UTC-9',
    posixWithDST: 'UTC-9',
    ianaName: 'Asia/Tokyo',
  ),
  // GMT+10:00 (DST — Australia)
  TimeZoneInfo(
    timeZoneID: 'AEST-10',
    utcOffsetMinutes: 600,
    observesDST: true,
    description: '(GMT+10:00) Australia',
    posixNoDST: 'UTC-10',
    posixWithDST: 'AEST-10AEDT,M10.1.0/02:00,M4.1.0/03:00',
    ianaName: 'Australia/Sydney',
    standardTimePosix: 'AEST-10',
  ),
  // GMT+10:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'GST-10-NO-DST',
    utcOffsetMinutes: 600,
    observesDST: false,
    description: '(GMT+10:00) Guam, Russia',
    posixNoDST: 'UTC-10',
    posixWithDST: 'UTC-10',
    ianaName: 'Pacific/Guam',
  ),
  // GMT+11:00
  TimeZoneInfo(
    timeZoneID: 'SBT-11-NO-DST',
    utcOffsetMinutes: 660,
    observesDST: false,
    description: '(GMT+11:00) Solomon Islands',
    posixNoDST: 'UTC-11',
    posixWithDST: 'UTC-11',
    ianaName: 'Pacific/Guadalcanal',
  ),
  // GMT+12:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'FJT-12-NO-DST',
    utcOffsetMinutes: 720,
    observesDST: false,
    description: '(GMT+12:00) Fiji',
    posixNoDST: 'UTC-12',
    posixWithDST: 'UTC-12',
    ianaName: 'Pacific/Fiji',
  ),
  // GMT+12:00 (DST — New Zealand)
  TimeZoneInfo(
    timeZoneID: 'NZST-12',
    utcOffsetMinutes: 720,
    observesDST: true,
    description: '(GMT+12:00) New Zealand',
    posixNoDST: 'UTC-12',
    posixWithDST: 'NZST-12NZDT,M9.5.0/02:00,M4.1.0/03:00',
    ianaName: 'Pacific/Auckland',
    standardTimePosix: 'NZST-12',
  ),
];

/// Reverse-match a POSIX string from the router to a [TimeZoneInfo].
///
/// Matching order:
/// 1. `timeZoneID` exact match
/// 2. `posixNoDST` exact match
/// 3. `posixWithDST` exact match
/// 4. Returns `null` if no match found
TimeZoneInfo? matchTimezone(String posixFromRouter) {
  for (final tz in kTimeZoneDefinitions) {
    if (tz.timeZoneID == posixFromRouter) return tz;
  }
  // posixNoDST match: prefer non-DST entry when multiple zones share the
  // same posixNoDST value (e.g. UTC5 → Indiana non-DST, not EST DST).
  // A bare "UTC5" string has no DST transition rules, so it should map to
  // the non-DST variant.
  TimeZoneInfo? posixNoDstMatch;
  for (final tz in kTimeZoneDefinitions) {
    if (tz.posixNoDST == posixFromRouter) {
      if (!tz.observesDST) return tz;
      posixNoDstMatch ??= tz;
    }
  }
  if (posixNoDstMatch != null) return posixNoDstMatch;
  for (final tz in kTimeZoneDefinitions) {
    if (tz.posixWithDST == posixFromRouter) return tz;
  }
  return null;
}

/// Whether daylight savings is actually in effect on the device.
///
/// Not the same question as [TimeZoneInfo.observesDST], and conflating them is a
/// live regression this exists to prevent. When the zone came back by name, the
/// name is the identity and its DST rule is the device's — `observesDST` is the
/// answer. When it came back by POSIX string, the string is a *clock rule*, and a
/// bare `UTC±N` has no transitions in it whatever entry it resolved to.
///
/// Four legacy values make the difference visible: `UTC8`, `UTC9`, `UTC1` and
/// `UTC3:30` are each owned by exactly one entry, and that entry observes DST
/// (`PST8`, `AKST9`, `AZOT1`, `NST03:30` — they have no non-DST sibling). A
/// router that 2.7.1 left on `UTC8` is on fixed UTC-8; reading `observesDST` off
/// `PST8` would tell the user daylight savings is on.
/// [reportedOffsetMinutes] applies the same veto as [resolveTimezone], and it has
/// to be the same one: resolve the label from the POSIX string because the clock
/// contradicts the name, then read the DST state off the name anyway, and the
/// card shows Hong Kong with daylight savings on.
bool dstInEffect({
  required String zoneName,
  required String localTimeZone,
  int? reportedOffsetMinutes,
}) {
  final named = matchByZoneName(zoneName);
  if (named != null && _offsetIsPlausible(named, reportedOffsetMinutes)) {
    return named.observesDST;
  }
  final tz = matchTimezone(localTimeZone);
  if (tz == null || !tz.observesDST) return false;
  return localTimeZone == tz.posixWithDST;
}

/// Resolve an IANA zone name from `Device.Time.X_LINKSYS_LocalTimeZoneName`.
///
/// Unlike [matchTimezone] this is unambiguous, which is the whole point (#1609).
/// A POSIX string is a clock rule, and one rule can belong to several zones —
/// `EST5` is Panama *and* Eastern-without-DST, `UTC-8` was Hong Kong *and*
/// Singapore — so reading one back could never tell us which was chosen. A zone
/// name is an identity, so it can.
TimeZoneInfo? matchByZoneName(String zoneName) {
  if (zoneName.isEmpty) return null;
  for (final tz in kTimeZoneDefinitions) {
    if (tz.ianaName == zoneName) return tz;
  }
  return null;
}

/// The zone to display, given the device's answers.
///
/// Prefers [zoneName], falling back to the POSIX string. The fallback is not
/// belt-and-braces, it is the only thing that works on three real inputs:
/// a router last written by 2.7.1 or earlier (the name is empty, because writing
/// `LocalTimeZone` clears it); a zone set from the device's own 89-row list,
/// which may name a region outside our 39; and a factory-fresh box, where both
/// are useless and the caller falls through to the reported offset.
///
/// [reportedOffsetMinutes] vetoes a name that cannot be telling the truth. The
/// firmware clears the name whenever the POSIX leaf is written, which is what
/// keeps the two consistent — measured, but it is the firmware's promise and not
/// ours, and something other than this app (the device's own zone list, a CLI, a
/// cloud push) could leave a name behind that the clock contradicts. A name is
/// only believed if the zone's standard offset, or that offset plus an hour when
/// it observes DST, matches what the device reports; otherwise we fall through to
/// the POSIX string, and past that to the raw offset. Pass null to skip the check
/// when no clock reading is available.
TimeZoneInfo? resolveTimezone({
  required String zoneName,
  required String localTimeZone,
  int? reportedOffsetMinutes,
}) {
  final named = matchByZoneName(zoneName);
  if (named != null && _offsetIsPlausible(named, reportedOffsetMinutes)) {
    return named;
  }
  return matchTimezone(localTimeZone);
}

bool _offsetIsPlausible(TimeZoneInfo tz, int? reported) {
  if (reported == null) return true;
  if (reported == tz.utcOffsetMinutes) return true;
  return tz.observesDST && reported == tz.utcOffsetMinutes + 60;
}
