import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

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
  ///
  /// Returns [WifiWriteOutcome.unanswered] when every error says the request
  /// never got an answer: like any WiFi write it reloads the radios, and over
  /// Remote Assistance #1460's DFS SET took 35.4 s and had applied when the app
  /// reported a failure. The caller reads [fetchIeee80211h] back to settle it.
  /// A refusal still throws.
  ///
  /// Not `allowPartial`, unlike the WiFi Settings save: every leaf here is on
  /// `Device.WiFi.Radio`, one USP service, so the atomic SET is accepted.
  Future<WifiWriteOutcome> setIeee80211hEnabled({
    required List<String> radioPaths,
    required bool enabled,
    List<String> forceAutoChannelPaths = const [],
  }) async {
    if (radioPaths.isEmpty) return WifiWriteOutcome.confirmed;
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
      if (parsed is UspFailure &&
          parsed.errors.every((e) => isUnansweredWifiWrite(e.errorMessage))) {
        logger.i('[USP][WiFi][Advanced]: IEEE80211h update unanswered — the '
            'radios reloaded under the request');
        return WifiWriteOutcome.unanswered;
      }
      switch (parsed) {
        case UspSuccess():
          return WifiWriteOutcome.confirmed;
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

  /// [setIeee80211hEnabled] as a [WifiWritePlan], for a caller that settles a
  /// lost reply by reading the radios back.
  ///
  /// The proof is the `IEEE80211hEnabled` values, which [fetchIeee80211h]
  /// reads back — but only for radios whose value actually changes, since an
  /// unchanged one would read back "matching" whether or not the write arrived.
  /// The forced `AutoChannelEnable` is not proof: it goes out in the same SET,
  /// so the DFS state landing means it did.
  WifiWritePlan planIeee80211h({
    required Map<String, bool> current,
    required List<String> radioPaths,
    required bool enabled,
    List<String> forceAutoChannelPaths = const [],
  }) =>
      WifiWritePlan(
        params: {
          for (final path in radioPaths) '${path}IEEE80211hEnabled': enabled,
          for (final path in forceAutoChannelPaths)
            '${path}AutoChannelEnable': true,
        },
        proof: {
          for (final path in radioPaths)
            if (current[path] != enabled) '${path}IEEE80211hEnabled': enabled,
        },
        send: () => setIeee80211hEnabled(
          radioPaths: radioPaths,
          enabled: enabled,
          forceAutoChannelPaths: forceAutoChannelPaths,
        ),
      );

  /// Whether the radios now carry every `IEEE80211hEnabled` value in [proof].
  /// Fails closed: an empty [proof] is not applied.
  Future<bool> isIeee80211hApplied(Map<String, dynamic> proof) async {
    if (proof.isEmpty) return false;
    final now = await fetchIeee80211h();
    return proof.entries.every((e) {
      final radio =
          e.key.substring(0, e.key.length - 'IEEE80211hEnabled'.length);
      return now[radio] == e.value;
    });
  }
}
