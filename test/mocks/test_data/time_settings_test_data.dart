/// Test data builder for the time settings services (linksys/FWDEV#198).
///
/// Provides raw USP `Get` response shapes for `Device.Time.*` so service-level
/// tests can stub `UspClient.get()` realistically.
class TimeSettingsTestData {
  static const _catalogue = 'Device.Time.X_LINKSYS_TimeZones';

  /// One `Device.Time.X_LINKSYS_TimeZones.{i}.` row, as the device reports it
  /// (every value a string).
  static Map<String, dynamic> zoneRow(
    int instance, {
    required String timeZoneId,
    required int utcOffsetMinutes,
    required bool observesDst,
    required String description,
  }) =>
      <String, dynamic>{
        '$_catalogue.$instance.TimeZoneID': timeZoneId,
        '$_catalogue.$instance.UTCOffsetMinutes': '$utcOffsetMinutes',
        '$_catalogue.$instance.ObservesDST': observesDst ? '1' : '0',
        '$_catalogue.$instance.Description': description,
      };

  /// A two-row catalogue: one DST zone and one `-NO-DST` zone.
  static Map<String, dynamic> catalogueResponse() => <String, dynamic>{
        ...zoneRow(
          1,
          timeZoneId: 'PST8',
          utcOffsetMinutes: -480,
          observesDst: true,
          description: '(GMT-08:00) Pacific Time (USA & Canada)',
        ),
        ...zoneRow(
          2,
          timeZoneId: 'JST-9-NO-DST',
          utcOffsetMinutes: 540,
          observesDst: false,
          description: '(GMT+09:00) Japan, Korea',
        ),
      };
}
