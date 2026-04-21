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
  ),
  // GMT-11:00
  TimeZoneInfo(
    timeZoneID: 'WST11-NO-DST',
    utcOffsetMinutes: -660,
    observesDST: false,
    description: '(GMT-11:00) Midway Island, Samoa',
    posixNoDST: 'UTC11',
    posixWithDST: 'UTC11',
  ),
  // GMT-10:00
  TimeZoneInfo(
    timeZoneID: 'HST10-NO-DST',
    utcOffsetMinutes: -600,
    observesDST: false,
    description: '(GMT-10:00) Hawaii',
    posixNoDST: 'UTC10',
    posixWithDST: 'UTC10',
  ),
  // GMT-09:00
  TimeZoneInfo(
    timeZoneID: 'AKST9',
    utcOffsetMinutes: -540,
    observesDST: true,
    description: '(GMT-09:00) Alaska',
    posixNoDST: 'UTC9',
    posixWithDST: 'AKST9AKDT,M3.2.0/02:00,M11.1.0/02:00',
  ),
  // GMT-08:00
  TimeZoneInfo(
    timeZoneID: 'PST8',
    utcOffsetMinutes: -480,
    observesDST: true,
    description: '(GMT-08:00) Pacific Time (USA & Canada)',
    posixNoDST: 'UTC8',
    posixWithDST: 'PST8PDT,M3.2.0/02:00,M11.1.0/02:00',
  ),
  // GMT-07:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'MST7',
    utcOffsetMinutes: -420,
    observesDST: true,
    description: '(GMT-07:00) Mountain Time (USA & Canada)',
    posixNoDST: 'UTC7',
    posixWithDST: 'MST7MDT,M3.2.0/02:00,M11.1.0/02:00',
  ),
  // GMT-07:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'MST7-NO-DST',
    utcOffsetMinutes: -420,
    observesDST: false,
    description: '(GMT-07:00) Arizona',
    posixNoDST: 'UTC7',
    posixWithDST: 'UTC7',
  ),
  // GMT-06:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'CST6',
    utcOffsetMinutes: -360,
    observesDST: true,
    description: '(GMT-06:00) Central Time (USA & Canada)',
    posixNoDST: 'UTC6',
    posixWithDST: 'CST6CDT,M3.2.0/02:00,M11.1.0/02:00',
  ),
  // GMT-06:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'CST6-NO-DST',
    utcOffsetMinutes: -360,
    observesDST: false,
    description: '(GMT-06:00) Mexico',
    posixNoDST: 'UTC6',
    posixWithDST: 'UTC6',
  ),
  // GMT-05:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'EST5',
    utcOffsetMinutes: -300,
    observesDST: true,
    description: '(GMT-05:00) Eastern Time (USA & Canada)',
    posixNoDST: 'UTC5',
    posixWithDST: 'EST5EDT,M3.2.0/02:00,M11.1.0/02:00',
  ),
  // GMT-05:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'EST5-NO-DST',
    utcOffsetMinutes: -300,
    observesDST: false,
    description: '(GMT-05:00) Indiana East, Colombia, Panama',
    posixNoDST: 'UTC5',
    posixWithDST: 'UTC5',
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
  ),
  // GMT-04:00 (DST — Chile)
  TimeZoneInfo(
    timeZoneID: 'CLT4',
    utcOffsetMinutes: -240,
    observesDST: true,
    description: '(GMT-04:00) Chile Time (Chile, Antarctica)',
    posixNoDST: 'UTC4',
    posixWithDST: 'CLT4CLST,M10.2.6/00:00,M3.2.6/00:00',
  ),
  // GMT-04:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'VET4-NO-DST',
    utcOffsetMinutes: -240,
    observesDST: false,
    description: '(GMT-04:00) Bolivia, Venezuela',
    posixNoDST: 'UTC4',
    posixWithDST: 'UTC4',
  ),
  // GMT-03:30 (DST)
  TimeZoneInfo(
    timeZoneID: 'NST03:30',
    utcOffsetMinutes: -210,
    observesDST: true,
    description: '(GMT-03:30) Newfoundland',
    posixNoDST: 'UTC3:30',
    posixWithDST: 'NST3:30NDT,M3.2.0/00:01,M11.1.0/00:01',
  ),
  // GMT-03:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'BRT3',
    utcOffsetMinutes: -180,
    observesDST: true,
    description: '(GMT-03:00) Brazil East, Greenland',
    posixNoDST: 'UTC3',
    posixWithDST: 'BRT3BRST,M10.3.0/00:00,M2.3.0/00:00',
  ),
  // GMT-03:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'ART3-NO-DST',
    utcOffsetMinutes: -180,
    observesDST: false,
    description: '(GMT-03:00) Guyana',
    posixNoDST: 'UTC3',
    posixWithDST: 'UTC3',
  ),
  // GMT-02:00
  TimeZoneInfo(
    timeZoneID: 'MAT2-NO-DST',
    utcOffsetMinutes: -120,
    observesDST: false,
    description: '(GMT-02:00) Mid-Atlantic',
    posixNoDST: 'UTC2',
    posixWithDST: 'UTC2',
  ),
  // GMT-01:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'AZOT1',
    utcOffsetMinutes: -60,
    observesDST: true,
    description: '(GMT-01:00) Azores',
    posixNoDST: 'UTC1',
    posixWithDST: 'AZOT1AZOST,M3.5.0/00:00,M10.5.0/01:00',
  ),
  // GMT+00:00 (DST — England)
  TimeZoneInfo(
    timeZoneID: 'GMT0',
    utcOffsetMinutes: 0,
    observesDST: true,
    description: '(GMT) England',
    posixNoDST: 'UTC0',
    posixWithDST: 'GMT0BST,M3.5.0/01:00,M10.5.0/02:00',
  ),
  // GMT+00:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'GMT0-NO-DST',
    utcOffsetMinutes: 0,
    observesDST: false,
    description: '(GMT) Gambia, Liberia, Morocco',
    posixNoDST: 'UTC0',
    posixWithDST: 'UTC0',
  ),
  // GMT+01:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'CET-1',
    utcOffsetMinutes: 60,
    observesDST: true,
    description: '(GMT+01:00) France, Germany, Italy',
    posixNoDST: 'UTC-1',
    posixWithDST: 'CET-1CEST,M3.5.0/02:00,M10.5.0/03:00',
  ),
  // GMT+01:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'CET-1-NO-DST',
    utcOffsetMinutes: 60,
    observesDST: false,
    description: '(GMT+01:00) Tunisia',
    posixNoDST: 'UTC-1',
    posixWithDST: 'UTC-1',
  ),
  // GMT+02:00 (DST)
  TimeZoneInfo(
    timeZoneID: 'EET-2',
    utcOffsetMinutes: 120,
    observesDST: true,
    description: '(GMT+02:00) Greece, Ukraine, Romania, Turkey',
    posixNoDST: 'UTC-2',
    posixWithDST: 'EET-2EEST,M3.5.0/03:00,M10.5.0/04:00',
  ),
  // GMT+02:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'SAST-2-NO-DST',
    utcOffsetMinutes: 120,
    observesDST: false,
    description: '(GMT+02:00) South Africa',
    posixNoDST: 'UTC-2',
    posixWithDST: 'UTC-2',
  ),
  // GMT+03:00
  TimeZoneInfo(
    timeZoneID: 'AST-3-NO-DST',
    utcOffsetMinutes: 180,
    observesDST: false,
    description: '(GMT+03:00) Iraq, Jordan, Kuwait',
    posixNoDST: 'UTC-3',
    posixWithDST: 'UTC-3',
  ),
  // GMT+04:00
  TimeZoneInfo(
    timeZoneID: 'GST-4-NO-DST',
    utcOffsetMinutes: 240,
    observesDST: false,
    description: '(GMT+04:00) Armenia',
    posixNoDST: 'UTC-4',
    posixWithDST: 'UTC-4',
  ),
  // GMT+05:00
  TimeZoneInfo(
    timeZoneID: 'PKT-5-NO-DST',
    utcOffsetMinutes: 300,
    observesDST: false,
    description: '(GMT+05:00) Pakistan, Russia',
    posixNoDST: 'UTC-5',
    posixWithDST: 'UTC-5',
  ),
  // GMT+05:30
  TimeZoneInfo(
    timeZoneID: 'IST-05:30-NO-DST',
    utcOffsetMinutes: 330,
    observesDST: false,
    description: '(GMT+05:30) Bombay, Kalkutta, Madras, Neu Delhi',
    posixNoDST: 'UTC-5:30',
    posixWithDST: 'UTC-5:30',
  ),
  // GMT+06:00
  TimeZoneInfo(
    timeZoneID: 'ALMT-6-NO-DST',
    utcOffsetMinutes: 360,
    observesDST: false,
    description: '(GMT+06:00) Bangladesh, Russia',
    posixNoDST: 'UTC-6',
    posixWithDST: 'UTC-6',
  ),
  // GMT+07:00
  TimeZoneInfo(
    timeZoneID: 'ICT-7-NO-DST',
    utcOffsetMinutes: 420,
    observesDST: false,
    description: '(GMT+07:00) Thailand, Russia',
    posixNoDST: 'UTC-7',
    posixWithDST: 'UTC-7',
  ),
  // GMT+08:00 (China/HK)
  TimeZoneInfo(
    timeZoneID: 'HKT-8-NO-DST',
    utcOffsetMinutes: 480,
    observesDST: false,
    description: '(GMT+08:00) China, Hong Kong, Australia Western',
    posixNoDST: 'UTC-8',
    posixWithDST: 'UTC-8',
  ),
  // GMT+08:00 (Singapore/Taiwan)
  TimeZoneInfo(
    timeZoneID: 'SGT-8-NO-DST',
    utcOffsetMinutes: 480,
    observesDST: false,
    description: '(GMT+08:00) Singapore, Taiwan, Russia',
    posixNoDST: 'UTC-8',
    posixWithDST: 'UTC-8',
  ),
  // GMT+09:00
  TimeZoneInfo(
    timeZoneID: 'JST-9-NO-DST',
    utcOffsetMinutes: 540,
    observesDST: false,
    description: '(GMT+09:00) Japan, Korea',
    posixNoDST: 'UTC-9',
    posixWithDST: 'UTC-9',
  ),
  // GMT+10:00 (DST — Australia)
  TimeZoneInfo(
    timeZoneID: 'AEST-10',
    utcOffsetMinutes: 600,
    observesDST: true,
    description: '(GMT+10:00) Australia',
    posixNoDST: 'UTC-10',
    posixWithDST: 'AEST-10AEDT,M10.1.0/02:00,M4.1.0/03:00',
  ),
  // GMT+10:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'GST-10-NO-DST',
    utcOffsetMinutes: 600,
    observesDST: false,
    description: '(GMT+10:00) Guam, Russia',
    posixNoDST: 'UTC-10',
    posixWithDST: 'UTC-10',
  ),
  // GMT+11:00
  TimeZoneInfo(
    timeZoneID: 'SBT-11-NO-DST',
    utcOffsetMinutes: 660,
    observesDST: false,
    description: '(GMT+11:00) Solomon Islands',
    posixNoDST: 'UTC-11',
    posixWithDST: 'UTC-11',
  ),
  // GMT+12:00 (no DST)
  TimeZoneInfo(
    timeZoneID: 'FJT-12-NO-DST',
    utcOffsetMinutes: 720,
    observesDST: false,
    description: '(GMT+12:00) Fiji',
    posixNoDST: 'UTC-12',
    posixWithDST: 'UTC-12',
  ),
  // GMT+12:00 (DST — New Zealand)
  TimeZoneInfo(
    timeZoneID: 'NZST-12',
    utcOffsetMinutes: 720,
    observesDST: true,
    description: '(GMT+12:00) New Zealand',
    posixNoDST: 'UTC-12',
    posixWithDST: 'NZST-12NZDT,M9.5.0/02:00,M4.1.0/03:00',
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

/// Infer whether DST is currently enabled based on the router's POSIX string.
///
/// Returns `true` only if the string matches a `posixWithDST` value that
/// differs from its `posixNoDST` (i.e., a DST-capable timezone with DST on).
bool inferDstEnabled(String posixFromRouter) {
  final tz = matchTimezone(posixFromRouter);
  if (tz == null || !tz.observesDST) return false;
  return posixFromRouter == tz.posixWithDST;
}
