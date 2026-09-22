import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/time_settings.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';

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

  /// `Device.Time.X_LINKSYS_LocalTimeZoneName`, read raw (#1609).
  ///
  /// Not in `time_settings.yaml`, so not on the codegen model, and read in its
  /// own `Get` rather than by widening `TimeSettings._paths` by hand — the
  /// generated file is overwritten on the next run. Folding the leaf into the
  /// upstream definition is the follow-up; reading one leaf raw is the existing
  /// idiom until then.
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
        ntpServer1: ts.ntpServer1,
        ntpServer2: ts.ntpServer2,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
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
