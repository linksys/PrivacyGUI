import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/power_table_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_state.dart';

/// Riverpod provider for [PowerTableService]
final powerTableServiceProvider = Provider<PowerTableService>((ref) {
  return PowerTableService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for power table (transmit region) JNAP operations.
///
/// Encapsulates all power table JNAP communication (getPowerTableSettings via polling,
/// setPowerTableSettings), separating business logic from state management (PowerTableNotifier).
///
/// Example:
/// ```dart
/// final service = ref.read(powerTableServiceProvider);
///
/// // Parse from polling data (does not throw)
/// final state = service.parsePowerTableSettings(pollingData);
/// if (state != null) {
///   // Use state
/// }
///
/// // Save country (may throw ServiceError)
/// try {
///   await service.savePowerTableCountry(PowerTableCountries.twn);
/// } on ServiceError catch (e) {
///   // Handle error
/// }
/// ```
class PowerTableService {
  /// Constructor injection of RouterRepository for testability
  PowerTableService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Parses power table settings from polling data.
  ///
  /// This is a synchronous best-effort operation that extracts power table configuration
  /// from the polling data map. It does not make network calls.
  ///
  /// Parameters:
  ///   - [pollingData]: Map of JNAP action results from polling provider
  ///
  /// Returns:
  ///   - [PowerTableState] if power table data is available in polling data
  ///   - `null` if power table data is not available
  ///
  /// Note: This method does not throw. Returns null for missing data.
  PowerTableState? parsePowerTableSettings(
    Map<JNAPAction, JNAPResult> pollingData,
  ) {
    final powerTableResult = JNAPTransactionSuccessWrap.getResult(
      JNAPAction.getPowerTableSettings,
      pollingData,
    );

    if (powerTableResult == null) {
      return null;
    }

    final powerTable = PowerTableSettings.fromMap(powerTableResult.output);

    return PowerTableState(
      isPowerTableSelectable: powerTable.isPowerTableSelectable,
      supportedCountries: List.from(
        powerTable.supportedCountries.map(
          (e) => PowerTableCountries.resolve(e),
        ),
      )..sort((a, b) => a.compareTo(b)),
      country: PowerTableCountries.resolve(powerTable.country ?? ''),
    );
  }

  /// Saves the selected power table country to the router.
  ///
  /// Parameters:
  ///   - [country]: The country to set for power table (required)
  ///
  /// Throws:
  ///   - [NetworkError]: On network communication failure
  ///   - [UnexpectedError]: On unexpected JNAP errors
  Future<void> savePowerTableCountry(PowerTableCountries country) async {
    try {
      await _routerRepository.send(
        JNAPAction.setPowerTableSettings,
        data: {'country': country.name.toUpperCase()},
        auth: true,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }
}
