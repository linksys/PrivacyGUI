import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
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
  /// enrichment, and returns UI models.
  Future<DhcpDataFetchResult> fetch({
    required Map<String, String> hostNameByMac,
  }) async {
    try {
      final results = await Future.wait([
        DhcpClients.fetch(_usp),
        DhcpReservations.fetch(_usp),
      ]);

      final clients = results[0] as DhcpClients;
      final reservations = results[1] as DhcpReservations;

      final clientModels = clients.items
          .map((c) => DhcpClientUIModel(
                mac: c.chaddr,
                ip: c.ipAddress,
                active: c.active,
                hostName: hostNameByMac[c.chaddr.trim().toUpperCase()] ?? '',
                leaseExpiry: c.leaseTimeRemaining,
              ))
          .toList();

      final reservationModels = reservations.items
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
