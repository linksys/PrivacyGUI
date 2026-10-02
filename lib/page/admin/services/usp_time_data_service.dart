import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/generated/time_zones.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/timezone_definitions.dart';
import 'package:privacy_gui/page/_shared/models/timezone_info.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspTimeDataServiceProvider = Provider<UspTimeDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspTimeDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching time settings data.
///
/// Owns the codegen call and error mapping for [timeDataProvider].
class UspTimeDataService {
  final UspClient _usp;

  UspTimeDataService(this._usp);

  /// `Device.Time.X_LINKSYS_LocalTimeZoneName`, read raw (#1609), for the
  /// fallback resolution only.
  ///
  /// Nothing writes it any more — a zone is saved through `SetTimeSettings`
  /// (linksys/FWDEV#198). It is still read because a router last saved by 2.7.2
  /// holds the zone here, under a POSIX string the device usually cannot resolve
  /// to a `TimeZoneID`. Not in `time_settings.yaml`, so read in its own `Get`
  /// rather than by widening the generated `_paths` by hand.
  static const _zoneNamePath = 'Device.Time.X_LINKSYS_LocalTimeZoneName';

  /// Fetches time settings and returns a [TimeSettingsUIModel].
  Future<TimeSettingsUIModel> fetch() async {
    try {
      // Started together, not awaited in turn. They are independent reads with
      // distinct throttler cacheKeys, and OBUSPA processes one message at a time,
      // so sequencing them would put a full extra serialized round trip plus the
      // 80 ms stagger on every load of a card that also ticks every second.
      final settings = TimeSettings.fetch(_usp);
      final zoneName = _fetchZoneName();
      final ts = await settings;
      return TimeSettingsUIModel(
        enable: ts.enable,
        status: ts.status,
        currentLocalTime: ts.currentLocalTime,
        localTimeZone: ts.localTimeZone,
        localTimeZoneName: await zoneName,
        timeZoneId: ts.timeZoneId,
        autoAdjustForDst: ts.autoAdjustForDst,
        ntpServer1: ts.ntpServer1,
        ntpServer2: ts.ntpServer2,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The zones the edit dialog offers, as the device lists them
  /// (`Device.Time.X_LINKSYS_TimeZones.{i}`, linksys/FWDEV#198), in device order.
  ///
  /// Falls back to the built-in [kTimeZoneDefinitions] instead of failing, on a
  /// firmware without the catalogue (an empty result) and on a fault reading it:
  /// the list is what the user picks from, so losing it would take the edit away
  /// entirely. The built-in table is the 1.0 / Olympus table the firmware ships
  /// (linksys/usp_framework#72); compared row by row against the device on
  /// 2.0.2.26100116 during #1609 — same 39 IDs, offsets, DST flags and labels.
  Future<List<TimeZoneInfo>> fetchZones() async {
    try {
      final catalogue = await TimeZones.fetch(_usp);
      if (catalogue.items.isEmpty) return kTimeZoneDefinitions;
      return [
        for (final row in catalogue.items)
          TimeZoneInfo(
            timeZoneID: row.timeZoneId,
            utcOffsetMinutes: row.utcOffsetMinutes,
            observesDST: row.observesDst,
            description: row.description,
          ),
      ];
    } catch (e) {
      logger.w(
          '[USP][Time]: zone catalogue unreadable, '
          'falling back to the built-in list',
          error: e);
      return kTimeZoneDefinitions;
    }
  }

  /// Reads the zone name, degrading to `''` rather than failing the page.
  ///
  /// The name only ever *improves* the label — `resolveTimezone` falls back to
  /// the POSIX string without it — so a firmware that does not carry the leaf,
  /// or a transient fault on it, must not take the whole time card down with it.
  ///
  /// It is logged on the way past, because `''` otherwise means two different
  /// things — "this box has no such leaf" and "the read failed" — and the second
  /// leaves the card on the ambiguous POSIX label with nothing in the
  /// diagnostics to say why.
  Future<String> _fetchZoneName() async {
    try {
      final response = await _usp.get([_zoneNamePath]);
      final value = response[_zoneNamePath];
      return value is String ? value : '';
    } catch (e) {
      logger.w(
          '[USP][Time]: $_zoneNamePath unreadable, '
          'falling back to the POSIX string',
          error: e);
      return '';
    }
  }
}
