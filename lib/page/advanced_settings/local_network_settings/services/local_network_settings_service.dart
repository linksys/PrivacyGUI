import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/reservation_item_ui_model.dart';

final localNetworkSettingsServiceProvider =
    Provider<LocalNetworkSettingsService>((ref) {
  return LocalNetworkSettingsService(ref.watch(routerRepositoryProvider));
});

/// Service for handling Local Network Settings JNAP communication
///
/// Responsibilities:
/// - Fetch LAN settings from router via JNAP
/// - Save LAN settings including DHCP reservations
/// - Transform JNAP DHCPReservation ↔ UI ReservationItemUIModel
///
/// This service is shared by:
/// - DHCPReservationsProvider (reservation management)
/// - LocalNetworkSettingsProvider (full LAN settings)
class LocalNetworkSettingsService {
  final RouterRepository _routerRepository;

  LocalNetworkSettingsService(this._routerRepository);

  /// Fetch LAN settings from router
  ///
  /// Returns the complete RouterLANSettings from JNAP API
  Future<RouterLANSettings> fetchLANSettings({bool forceRemote = false}) async {
    final response = await _routerRepository.send(
      JNAPAction.getLANSettings,
      fetchRemote: forceRemote,
      auth: true,
    );
    return RouterLANSettings.fromMap(response.output);
  }

  /// Save reservations to router
  ///
  /// This method is called by both:
  /// - DHCPReservationsProvider (saving reservation changes)
  /// - LocalNetworkSettingsProvider (saving full LAN settings)
  ///
  /// Parameters include all required LAN settings fields since the JNAP API
  /// requires the complete settings object.
  Future<void> saveReservations({
    required String routerIp,
    required int networkPrefixLength,
    required String hostName,
    required bool isDHCPEnabled,
    required String firstClientIP,
    required String lastClientIP,
    required int leaseMinutes,
    String? dns1,
    String? dns2,
    String? dns3,
    String? wins,
    required List<DHCPReservationUIModel> reservations,
  }) async {
    final setLANSettings = SetRouterLANSettings(
      ipAddress: routerIp,
      networkPrefixLength: networkPrefixLength,
      hostName: hostName,
      isDHCPEnabled: isDHCPEnabled,
      dhcpSettings: DHCPSettings(
        firstClientIPAddress: firstClientIP,
        lastClientIPAddress: lastClientIP,
        leaseMinutes: leaseMinutes,
        dnsServer1: dns1?.isEmpty == true ? null : dns1,
        dnsServer2: dns2?.isEmpty == true ? null : dns2,
        dnsServer3: dns3?.isEmpty == true ? null : dns3,
        winsServer: wins?.isEmpty == true ? null : wins,
        reservations: _toJNAPList(reservations),
      ),
    );

    await _routerRepository.send(
      JNAPAction.setLANSettings,
      auth: true,
      data: setLANSettings.toMap()..removeWhere((key, value) => value == null),
      sideEffectOverrides: const JNAPSideEffectOverrides(maxRetry: 5),
    );
  }

  // ============================================
  // Conversion Helpers (JNAP ↔ UI Model)
  // ============================================

  /// Convert JNAP DHCPReservation to UI Model
  DHCPReservationUIModel _fromJNAP(DHCPReservation jnap) {
    return DHCPReservationUIModel(
      macAddress: jnap.macAddress,
      ipAddress: jnap.ipAddress,
      description: jnap.description,
    );
  }

  /// Convert UI Model to JNAP DHCPReservation
  DHCPReservation _toJNAP(DHCPReservationUIModel ui) {
    return DHCPReservation(
      macAddress: ui.macAddress,
      ipAddress: ui.ipAddress,
      description: ui.description,
    );
  }

  /// Convert list of JNAP models to UI models
  List<DHCPReservationUIModel> _fromJNAPList(List<DHCPReservation> list) {
    return list.map((jnap) => _fromJNAP(jnap)).toList();
  }

  /// Convert list of UI models to JNAP models
  List<DHCPReservation> _toJNAPList(List<DHCPReservationUIModel> list) {
    return list.map((ui) => _toJNAP(ui)).toList();
  }

  /// Public helper for external conversion (used during Phase 1 transition)
  ///
  /// This is used by DHCPReservationsService to convert from LocalNetworkStatus's
  /// JNAP model list to UI model list during the transition phase.
  ///
  /// In Phase 2 (LocalNetworkSettings refactoring), this will no longer be needed
  /// as LocalNetworkStatus will directly use List<ReservationItemUIModel>.
  List<DHCPReservationUIModel> convertFromJNAPList(List<DHCPReservation> list) {
    return _fromJNAPList(list);
  }
}
