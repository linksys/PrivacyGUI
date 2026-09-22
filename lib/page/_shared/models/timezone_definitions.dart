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

// `inferDstEnabled` was removed with #1609. It answered "does the stored POSIX
// string carry DST rules", which was the closest thing available to a DST state
// while the toggle was writable. Now that daylight savings is a property of the
// zone, `TimeZoneInfo.observesDST` on the resolved entry answers it directly and
// correctly for legacy strings too — `UTC5` resolves to the non-DST sibling, so
// the row reads Off without anyone inferring anything.

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

/// The zone to display, given both of the device's answers.
///
/// Prefers [zoneName], falling back to the POSIX string. The fallback is not
/// belt-and-braces, it is the only thing that works on three real inputs:
/// a router last written by 2.7.1 or earlier (the name is empty, because writing
/// `LocalTimeZone` clears it); a zone set from the device's own 89-row list,
/// which may name a region outside our 39; and a factory-fresh box, where both
/// are useless and the caller falls through to the reported offset.
TimeZoneInfo? resolveTimezone({
  required String zoneName,
  required String localTimeZone,
}) =>
    matchByZoneName(zoneName) ?? matchTimezone(localTimeZone);
