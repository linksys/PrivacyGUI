import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/services/local_network_settings_service.dart';
import 'package:privacy_gui/utils.dart';

final dhcpReservationsServiceProvider =
    Provider<DHCPReservationsService>((ref) {
  return DHCPReservationsService(
    ref.watch(localNetworkSettingsServiceProvider),
  );
});

/// Service for handling DHCP Reservations specific business logic
///
/// Responsibilities:
/// - Fetch initial reservations from LocalNetworkSettingsProvider
/// - Save reservations via LocalNetworkSettingsService
/// - Provide conflict checking logic
///
/// This service depends on LocalNetworkSettingsService for actual JNAP operations.
class DHCPReservationsService {
  final LocalNetworkSettingsService _localNetworkService;

  DHCPReservationsService(this._localNetworkService);

  /// Fetch initial reservations from LocalNetworkSettingsProvider
  ///
  /// Returns the current DHCP reservation list as UI models.
  /// No conversion needed as LocalNetworkStatus now uses UI models directly.
  Future<List<DHCPReservationUIModel>> fetchInitialReservations(Ref ref) async {
    final localNetworkStatus =
        ref.read(localNetworkSettingProvider.select((state) => state.status));

    // Direct access - LocalNetworkStatus.dhcpReservationList is already UI Model
    return localNetworkStatus.dhcpReservationList;
  }

  /// Save reservations by calling LocalNetworkSettingsService
  ///
  /// Reads current LAN settings from LocalNetworkSettingsProvider
  /// and saves with updated reservations.
  ///
  /// After save, triggers a refresh of LocalNetworkSettings to get the updated state.
  Future<void> saveReservations(
    Ref ref,
    List<DHCPReservationUIModel> reservations,
  ) async {
    final currentSettings = ref.read(
        localNetworkSettingProvider.select((state) => state.settings.current));

    await _localNetworkService.saveReservations(
      routerIp: currentSettings.ipAddress,
      networkPrefixLength:
          NetworkUtils.subnetMaskToPrefixLength(currentSettings.subnetMask),
      hostName: currentSettings.hostName,
      isDHCPEnabled: currentSettings.isDHCPEnabled,
      firstClientIP: currentSettings.firstIPAddress,
      lastClientIP: currentSettings.lastIPAddress,
      leaseMinutes: currentSettings.clientLeaseTime,
      dns1: currentSettings.dns1,
      dns2: currentSettings.dns2,
      dns3: currentSettings.dns3,
      wins: currentSettings.wins,
      reservations: reservations,
    );

    // Refresh LocalNetworkSettings after save
    await ref
        .read(localNetworkSettingProvider.notifier)
        .fetch(forceRemote: true);
  }

  /// Check if a reservation conflicts with existing ones
  ///
  /// Conflicts occur when:
  /// - MAC address already exists in another reservation
  /// - IP address already exists in another reservation
  ///
  /// The [indexToExclude] parameter is used when editing an existing reservation
  /// to avoid self-comparison.
  bool isConflict(
    DHCPReservationUIModel item,
    List<DHCPReservationUIModel> existingList, {
    int? indexToExclude,
  }) {
    for (int i = 0; i < existingList.length; i++) {
      if (indexToExclude != null && i == indexToExclude) {
        continue;
      }

      final existing = existingList[i];
      if (existing.macAddress == item.macAddress ||
          existing.ipAddress == item.ipAddress) {
        return true;
      }
    }
    return false;
  }
}
