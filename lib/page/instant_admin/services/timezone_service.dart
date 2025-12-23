import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/timezone.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_state.dart';

/// Riverpod provider for [TimezoneService]
final timezoneServiceProvider = Provider<TimezoneService>((ref) {
  return TimezoneService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for timezone-related JNAP operations.
///
/// Encapsulates all timezone JNAP communication (getTimeSettings, setTimeSettings),
/// separating business logic from state management (TimezoneNotifier).
///
/// Example:
/// ```dart
/// final service = ref.read(timezoneServiceProvider);
/// try {
///   final (settings, status) = await service.fetchTimezoneSettings();
///   // Use settings and status
/// } on ServiceError catch (e) {
///   // Handle error
/// }
/// ```
class TimezoneService {
  /// Constructor injection of RouterRepository for testability
  TimezoneService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Fetches timezone settings from the router.
  ///
  /// Returns a tuple of [TimezoneSettings] (user-configurable) and [TimezoneStatus] (read-only).
  /// Supported timezones are sorted by UTC offset in ascending order.
  ///
  /// Parameters:
  ///   - [forceRemote]: If true, bypasses cache and fetches from router directly. Default: false.
  ///
  /// Returns:
  ///   - A tuple containing:
  ///     - [TimezoneSettings]: Current timezone configuration (timezoneId, isDaylightSaving)
  ///     - [TimezoneStatus]: Read-only data including supported timezones list
  ///
  /// Throws:
  ///   - [NetworkError]: On network communication failure
  ///   - [UnexpectedError]: On unexpected JNAP errors
  Future<(TimezoneSettings, TimezoneStatus)> fetchTimezoneSettings({
    bool forceRemote = false,
  }) async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getTimeSettings,
        auth: true,
        fetchRemote: forceRemote,
      );

      final timezoneId = result.output['timeZoneID'] ?? 'PST8';
      final supportedTimezones = List.from(result.output['supportedTimeZones'])
          .map((e) => SupportedTimezone.fromMap(e))
          .toList()
        ..sort((t1, t2) {
          return t1.utcOffsetMinutes.compareTo(t2.utcOffsetMinutes);
        });
      final autoAdjustForDST = result.output['autoAdjustForDST'] ?? false;

      final settings = TimezoneSettings(
        isDaylightSaving: autoAdjustForDST,
        timezoneId: timezoneId,
      );
      final status = TimezoneStatus(
        supportedTimezones: supportedTimezones,
        error: null,
      );

      return (settings, status);
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }

  /// Saves timezone settings to the router.
  ///
  /// Handles DST validation: if the selected timezone does not observe DST,
  /// autoAdjustForDST is set to false regardless of user selection.
  ///
  /// Parameters:
  ///   - [settings]: The timezone settings to save (required)
  ///   - [supportedTimezones]: List of supported timezones for DST validation (required)
  ///
  /// Throws:
  ///   - [NetworkError]: On network communication failure
  ///   - [UnexpectedError]: On unexpected JNAP errors
  Future<void> saveTimezoneSettings({
    required TimezoneSettings settings,
    required List<SupportedTimezone> supportedTimezones,
  }) async {
    try {
      // Determine if the selected timezone supports DST
      final selectedTimezone = supportedTimezones.firstWhereOrNull(
        (e) => e.timeZoneID == settings.timezoneId,
      );
      final observesDST = selectedTimezone?.observesDST ?? false;

      // If timezone doesn't observe DST, force autoAdjustForDST to false
      final effectiveDST = observesDST ? settings.isDaylightSaving : false;

      await _routerRepository.send(
        JNAPAction.setTimeSettings,
        data: {
          'timeZoneID': settings.timezoneId,
          'autoAdjustForDST': effectiveDST,
        },
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }
}
