import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/_shared/services/empty_row.dart';
import 'package:privacy_gui/page/_shared/utils/lan_dhcp_pool_pick.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspDhcpDataServiceProvider = Provider<UspDhcpDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspDhcpDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Fetch result
// ---------------------------------------------------------------------------

/// Result of a DHCP data fetch.
class DhcpDataFetchResult {
  final List<DhcpClientUIModel> clientModels;
  final List<DhcpReservationUIModel> reservationModels;

  const DhcpDataFetchResult({
    required this.clientModels,
    required this.reservationModels,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching DHCP clients and reservations.
///
/// Owns codegen calls and error mapping for [dhcpDataProvider].
class UspDhcpDataService {
  final UspClient _usp;

  UspDhcpDataService(this._usp);

  /// Fetches DHCP clients + reservations in parallel, applies hostname
  /// and online status enrichment, and returns UI models.
  Future<DhcpDataFetchResult> fetch({
    required Map<String, String> hostNameByMac,
    required Map<String, bool> isOnlineByMac,
  }) async {
    try {
      final results = await Future.wait([
        DhcpClients.fetch(_usp),
        DhcpReservations.fetch(_usp),
      ]);

      // The LAN pool's leases and reservations; the guest pool's are not
      // shown on these pages, nor is a row with every value blank.
      final clients =
          (lanDhcpPoolOf((results[0] as DhcpClients).items, (p) => p.alias)
                      ?.clients ??
                  const <DhcpClient>[])
              .where((c) => !isEmptyDhcpClient(c));
      final reservations =
          (lanDhcpPoolOf((results[1] as DhcpReservations).items, (p) => p.alias)
                      ?.staticAddresses ??
                  const <DhcpReservation>[])
              .where((r) => !isEmptyDhcpReservation(r));

      final clientModels = clients.map((c) {
        final normalizedMac = c.chaddr.trim().toUpperCase();
        // A lease's first address row is the address it holds; a client with
        // no row has no address yet.
        final ipv4 = c.ipv4Addresses.firstOrNull;
        return DhcpClientUIModel(
          mac: c.chaddr,
          ip: ipv4?.ipAddress ?? '',
          leaseActive: c.active,
          isOnline: isOnlineByMac[normalizedMac],
          hostName: hostNameByMac[normalizedMac] ?? '',
          leaseExpiry: ipv4?.leaseTimeRemaining,
        );
      }).toList();

      final reservationModels = reservations
          .map((r) => DhcpReservationUIModel(
                instancePath: r.instancePath,
                mac: r.chaddr,
                ip: r.yiaddr,
                enable: r.enable,
              ))
          .toList();

      return DhcpDataFetchResult(
        clientModels: clientModels,
        reservationModels: reservationModels,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }
}
