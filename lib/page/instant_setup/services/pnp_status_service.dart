import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_trigger_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for PnP status checking service.
///
/// Currently uses [LocalPnpStatusService] (SharedPreferences fallback).
/// When TR-181 parameters become available, swap to Tr181PnpStatusService.
final pnpStatusServiceProvider = Provider<PnpStatusService>((ref) {
  return LocalPnpStatusService();
});

/// Abstract interface for checking and acknowledging PnP setup status.
///
/// This service determines whether the PnP setup wizard should be shown
/// after the user logs in. It abstracts the storage mechanism to allow
/// easy migration from SharedPreferences to TR-181 in the future.
///
/// Implementations:
/// - [LocalPnpStatusService]: Uses SharedPreferences (current fallback)
/// - Tr181PnpStatusService: Uses TR-181 parameters (future, when available)
abstract class PnpStatusService {
  /// Check if PnP setup wizard is needed.
  ///
  /// [currentSerialNumber] - The serial number of the currently connected router.
  ///
  /// Returns [PnpTriggerResult.needsPnp] = true if:
  /// - No setup acknowledgment record exists, OR
  /// - Serial number has changed since last acknowledgment (different router)
  Future<PnpTriggerResult> check(String? currentSerialNumber);

  /// Record that PnP setup has been completed for the given serial number.
  ///
  /// This should be called after the user successfully completes the PnP wizard.
  /// Once acknowledged, [check()] will return needsPnp=false for this serial number.
  Future<void> acknowledge(String serialNumber);
}

/// SharedPreferences-based implementation for PnP status.
///
/// This is the fallback implementation until TR-181 `Device.X_LINKSYS.Setup.*`
/// parameters are available on firmware. Stores the serial number of routers
/// that have completed PnP setup.
class LocalPnpStatusService implements PnpStatusService {
  @override
  Future<PnpTriggerResult> check(String? currentSerialNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final acknowledgedSN = prefs.getString(pPnpConfiguredSN);

    logger.d('[PnP] check: currentSN=$currentSerialNumber, '
        'acknowledgedSN=$acknowledgedSN');

    // Already acknowledged and serial number matches → no PnP needed
    if (acknowledgedSN != null &&
        acknowledgedSN.isNotEmpty &&
        acknowledgedSN == currentSerialNumber) {
      logger.d('[PnP] check: SN matches, PnP not needed');
      return PnpTriggerResult.notNeeded();
    }

    // No record or different router → PnP needed
    logger.d('[PnP] check: PnP needed');
    return PnpTriggerResult.needed();
  }

  @override
  Future<void> acknowledge(String serialNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pPnpConfiguredSN, serialNumber);
    logger.i('[PnP] acknowledge: setup completed for SN=$serialNumber');
  }
}
