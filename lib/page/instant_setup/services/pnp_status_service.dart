import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/setup_operations.g.dart';
import 'package:privacy_gui/generated/setup_state.g.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_trigger_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for PnP status checking service.
///
/// Prefers [Tr181PnpStatusService] when a USP client is available, otherwise
/// falls back to [LocalPnpStatusService] (SharedPreferences).
final pnpStatusServiceProvider = Provider<PnpStatusService>((ref) {
  final usp = ref.watch(uspClientProvider);
  if (usp != null) {
    return Tr181PnpStatusService(usp);
  }
  return LocalPnpStatusService();
});

/// Abstract interface for checking and acknowledging PnP setup status.
///
/// Implementations:
/// - [Tr181PnpStatusService]: Uses TR-181 parameters on the router (preferred).
/// - [LocalPnpStatusService]: SharedPreferences fallback when no USP client
///   is available (e.g. non-Web platforms / pre-USP firmware).
abstract class PnpStatusService {
  /// Check if the PnP setup wizard should be shown.
  ///
  /// [currentSerialNumber] is consumed only by transports that key state per
  /// router locally; transports that read state from the router itself ignore
  /// this argument.
  Future<PnpTriggerResult> check(String? currentSerialNumber);

  /// Record that PnP setup has been completed.
  ///
  /// [serialNumber] is consumed only by transports that key state per router
  /// locally; transports that store state on the router itself ignore it.
  Future<void> acknowledge(String serialNumber);
}

/// SharedPreferences-based implementation. Used as a fallback when no USP
/// client is available; tracks completion per router serial number locally.
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

/// TR-181 implementation backed by `Device.DeviceInfo.X_LINKSYS_Setup.*`.
///
/// PnP completion is tracked on the router itself via
/// `UserAcknowledgedAutoConfig`, so a router that has already been set up
/// will skip the wizard regardless of which app/device the user logs in from.
/// `serialNumber` is ignored on this transport — the router state is
/// authoritative.
class Tr181PnpStatusService implements PnpStatusService {
  Tr181PnpStatusService(this._usp);

  final UspClient _usp;

  @override
  Future<PnpTriggerResult> check(String? currentSerialNumber) async {
    // Fetch failures here are non-fatal: a router that cannot serve
    // X_LINKSYS_Setup (legacy firmware, bbfdm routing fault, transient
    // network error) should fall through to the dashboard rather than
    // block login. Treating the check as "not needed" is the safer UX —
    // the user can still re-trigger the wizard manually if anything is
    // off, and routinely-recurring failures will surface in upstream
    // logging via the [USP] tag.
    try {
      final state = await SetupState.fetch(_usp);
      logger.d('[PnP] tr181 check: '
          'userAcknowledged=${state.userAcknowledgedAutoConfig}, '
          'method=${state.autoConfigurationMethod}');
      if (state.userAcknowledgedAutoConfig) {
        return PnpTriggerResult.notNeeded();
      }
      return PnpTriggerResult.needed(
        method: _parseMethod(state.autoConfigurationMethod),
      );
    } catch (e) {
      logger.w('[PnP] tr181 check failed, treating as notNeeded: $e');
      return PnpTriggerResult.notNeeded();
    }
  }

  @override
  Future<void> acknowledge(String serialNumber) async {
    // Acknowledge is fire-and-forget: a failure here only means the router
    // didn't record completion, which at worst causes the wizard to be
    // shown again on next login. Surfacing it as an exception would mask
    // an otherwise-successful WiFi save in the caller's catch block.
    try {
      await SetupOperations.setUserAcknowledgedAutoConfig(_usp);
      logger.i(
          '[PnP] tr181 acknowledge: SetUserAcknowledgedAutoConfig() invoked');
    } catch (e) {
      logger.w('[PnP] tr181 acknowledge failed (ignored): $e');
    }
  }

  AutoConfigurationMethod _parseMethod(String value) {
    switch (value) {
      case 'AutoParent':
        return AutoConfigurationMethod.autoParent;
      case 'PreConfigured':
        return AutoConfigurationMethod.preConfigured;
      default:
        return AutoConfigurationMethod.none;
    }
  }
}
