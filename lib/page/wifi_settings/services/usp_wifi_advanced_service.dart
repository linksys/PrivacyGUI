import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

final uspWifiAdvancedServiceProvider = Provider<UspWifiAdvancedService>(
  (ref) => UspWifiAdvancedService(ref.read(uspClientProvider)!),
);

/// Stateless service for IEEE 802.11h (DFS + TPC) radio settings.
///
/// Reads and writes `Device.WiFi.Radio.{i}.IEEE80211hEnabled` via raw USP
/// get/set (no codegen definition exists for this path).
class UspWifiAdvancedService {
  static const _ieee80211hPath = 'Device.WiFi.Radio.*.IEEE80211hEnabled';

  final UspClient _usp;

  UspWifiAdvancedService(this._usp);

  /// Fetches IEEE 802.11h enabled state per radio.
  ///
  /// Returns a map of radio instance path → enabled flag.
  /// e.g. `{"Device.WiFi.Radio.1." : true, "Device.WiFi.Radio.2." : false}`
  Future<Map<String, bool>> fetchIeee80211h() async {
    try {
      final response = await _usp.get([_ieee80211hPath]);

      final result = <String, bool>{};
      for (final key in response.keys) {
        if (key.startsWith('Device.WiFi.Radio.') &&
            key.endsWith('.IEEE80211hEnabled')) {
          final radioPath =
              key.substring(0, key.length - 'IEEE80211hEnabled'.length);
          final val = response[key];
          result[radioPath] = val == true || val == 'true' || val == '1';
        }
      }
      return result;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Sets IEEE 802.11h on all given radio paths.
  ///
  /// [forceAutoChannelPaths] additionally receives `AutoChannelEnable = true`
  /// in the same set() call. This is used when disabling DFS on a radio that is
  /// parked on a DFS channel: the firmware does not vacate the channel on its
  /// own (SSH-verified), so forcing auto-channel makes it reselect a legal
  /// non-DFS channel. Paths not in this list keep their channel settings.
  Future<void> setIeee80211hEnabled({
    required List<String> radioPaths,
    required bool enabled,
    List<String> forceAutoChannelPaths = const [],
  }) async {
    if (radioPaths.isEmpty) return;
    try {
      final params = <String, dynamic>{
        for (final path in radioPaths) '${path}IEEE80211hEnabled': enabled,
        for (final path in forceAutoChannelPaths)
          '${path}AutoChannelEnable': true,
      };
      final result = await _usp.set(params);
      // Parse the batch result so a firmware partial rejection (e.g. accepts
      // IEEE80211hEnabled but rejects a forced AutoChannelEnable) surfaces as an
      // error instead of being silently swallowed.
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(failures: final f):
          throw UspPartialFailureError(
            summary:
                'IEEE80211h update partial failure: ${f.first.errorMessage}',
            successPaths: const [],
            failures: f,
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'IEEE80211h update failed: ${e.first.errorMessage}',
            failures: e,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }
}
