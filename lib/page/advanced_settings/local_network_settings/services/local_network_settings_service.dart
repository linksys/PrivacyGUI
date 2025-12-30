import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_lan_settings.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/utils.dart';

final localNetworkSettingsServiceProvider =
    Provider<LocalNetworkSettingsService>((ref) {
  return LocalNetworkSettingsService(ref.watch(routerRepositoryProvider));
});

/// Service for handling Local Network Settings JNAP communication
///
/// Responsibilities:
/// - Fetch LAN settings from router via JNAP
/// - Save LAN settings including DHCP reservations
/// - Transform JNAP DHCPReservation ↔ UI DHCPReservationUIModel
/// - Perform network calculations (IP ranges, subnet masks, etc.)
///
/// This service is shared by:
/// - DHCPReservationsProvider (reservation management)
/// - LocalNetworkSettingsProvider (full LAN settings)
class LocalNetworkSettingsService {
  final RouterRepository _routerRepository;

  LocalNetworkSettingsService(this._routerRepository);

  /// Fetch LAN settings from router (JNAP Data Model)
  ///
  /// Returns the complete RouterLANSettings from JNAP API.
  /// This is a low-level method used internally for JNAP communication.
  Future<RouterLANSettings> fetchLANSettings({bool forceRemote = false}) async {
    final response = await _routerRepository.send(
      JNAPAction.getLANSettings,
      fetchRemote: forceRemote,
      auth: true,
    );
    return RouterLANSettings.fromMap(response.output);
  }

  /// Fetch LAN settings and convert to UI models with network calculations
  ///
  /// This is the main method for LocalNetworkSettingsProvider to use.
  /// Returns a tuple of (LocalNetworkSettings, LocalNetworkStatus) with:
  /// - All JNAP data converted to UI models
  /// - Network calculations performed (subnet mask, max users, etc.)
  /// - DHCP reservations converted to DHCPReservationUIModel
  Future<(LocalNetworkSettings, LocalNetworkStatus)>
      fetchLANSettingsWithUIModels({
    bool forceRemote = false,
    required LocalNetworkStatus currentStatus,
  }) async {
    final lanSettings = await fetchLANSettings(forceRemote: forceRemote);

    // Convert prefix length to subnet mask string
    final subnetMaskString = NetworkUtils.prefixLengthToSubnetMask(
      lanSettings.networkPrefixLength,
    );

    // Calculate max user allowed in DHCP range
    final maxUserAllowed = NetworkUtils.getMaxUserAllowedInDHCPRange(
      lanSettings.ipAddress,
      lanSettings.dhcpSettings.firstClientIPAddress,
      lanSettings.dhcpSettings.lastClientIPAddress,
    );

    // Calculate max user limit
    final maxUserLimit = NetworkUtils.getMaxUserLimit(
      lanSettings.ipAddress,
      lanSettings.dhcpSettings.firstClientIPAddress,
      subnetMaskString,
      maxUserAllowed,
    );

    // Build LocalNetworkSettings (UI layer settings)
    final newSettings = LocalNetworkSettings(
      hostName: lanSettings.hostName,
      ipAddress: lanSettings.ipAddress,
      subnetMask: subnetMaskString,
      isDHCPEnabled: lanSettings.isDHCPEnabled,
      firstIPAddress: lanSettings.dhcpSettings.firstClientIPAddress,
      lastIPAddress: lanSettings.dhcpSettings.lastClientIPAddress,
      maxUserAllowed: maxUserAllowed,
      clientLeaseTime: lanSettings.dhcpSettings.leaseMinutes,
      dns1: lanSettings.dhcpSettings.dnsServer1,
      dns2: lanSettings.dhcpSettings.dnsServer2,
      dns3: lanSettings.dhcpSettings.dnsServer3,
      wins: lanSettings.dhcpSettings.winsServer,
    );

    // Convert JNAP DHCPReservation list to UI models
    final reservationsUI = _fromJNAPList(lanSettings.dhcpSettings.reservations);

    // Build LocalNetworkStatus (UI layer status)
    final newStatus = currentStatus.copyWith(
      maxUserLimit: maxUserLimit,
      minNetworkPrefixLength: lanSettings.minNetworkPrefixLength,
      maxNetworkPrefixLength: lanSettings.maxNetworkPrefixLength,
      minAllowDHCPLeaseMinutes: lanSettings.minAllowedDHCPLeaseMinutes,
      maxAllowDHCPLeaseMinutes: lanSettings.maxAllowedDHCPLeaseMinutes,
      dhcpReservationList: reservationsUI,
    );

    return (newSettings, newStatus);
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
}
