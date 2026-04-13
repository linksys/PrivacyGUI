import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservation_list.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservations_feature_state.dart';
import 'package:privacy_gui/page/dhcp/models/dhcp_reservations_status.dart';
import 'package:privacy_gui/page/dhcp/services/usp_dhcp_service.dart';
import 'package:privacy_gui/page/local_network/providers/dhcp_data_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspDhcpReservationsProvider = AutoDisposeNotifierProvider<
    UspDhcpReservationsNotifier, DhcpReservationsFeatureState>(
  UspDhcpReservationsNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspDhcpReservationsProvider = AutoDisposeProvider<
    PreservableContract<DhcpReservationList, DhcpReservationsStatus>>(
  (ref) => ref.watch(uspDhcpReservationsProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspDhcpReservationsNotifier
    extends AutoDisposeNotifier<DhcpReservationsFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<DhcpReservationList,
            DhcpReservationsStatus, DhcpReservationsFeatureState> {
  UspDhcpService get _svc => ref.read(uspDhcpServiceProvider);

  @override
  DhcpReservationsFeatureState build() {
    // SSE invalidation: re-fetch when DHCP reservations change externally.
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.valueOrNull == InvalidationDomain.dhcpReservations) {
        onSseInvalidation();
      }
    });

    Future.microtask(() => fetch());
    return DhcpReservationsFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch
  // ---------------------------------------------------------------------------

  @override
  Future<(DhcpReservationList?, DhcpReservationsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final reservations = await _svc.fetchReservations();

      logger.d('[USP][DHCP][Reservations] Fetched — '
          'total: ${reservations.length}');

      return (
        DhcpReservationList(reservations: reservations),
        const DhcpReservationsStatus(),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][DHCP][Reservations] Fetch failed', error: e);
      return (
        null,
        DhcpReservationsStatus(errorMessage: '$e'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — diff original vs current, batch API calls
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );

    try {
      final original = state.settings.original.reservations;
      final current = state.settings.current.reservations;

      await ref.read(uspMutationLockProvider).withLock(() async {
        final result = await _svc.saveBatch(
          original: original,
          current: current,
        );

        logger.d('[USP][DHCP][Reservations] Batch save — '
            'added: ${result.added}, updated: ${result.updated}, '
            'deleted: ${result.deleted}');
      });

      // Invalidate Layer 1 provider to refresh dashboard card
      ref.invalidate(dhcpDataProvider);
    } on ServiceError catch (e) {
      logger.e('[USP][DHCP][Reservations] Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Immediate mutations (Dashboard card / Device Detail — single operations)
  // ---------------------------------------------------------------------------

  /// Toggle a reservation on/off immediately (writes to router).
  Future<void> immediateToggle(String instancePath, bool enable) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.immediateToggle(instancePath, enable);
      });
    } on ServiceError catch (e) {
      logger.e('[USP][DHCP] Immediate toggle failed', error: e);
      rethrow;
    }
    ref.invalidate(dhcpDataProvider);
  }

  /// Add a reservation immediately (writes to router).
  Future<void> immediateAdd({
    required String mac,
    required String ip,
    bool enable = true,
  }) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.immediateAdd(mac: mac, ip: ip, enable: enable);
      });
    } on ServiceError catch (e) {
      logger.e('[USP][DHCP] Immediate add failed', error: e);
      rethrow;
    }
    ref.invalidate(dhcpDataProvider);
  }

  /// Delete a reservation immediately (writes to router).
  Future<void> immediateDelete(String instancePath) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.immediateDelete(instancePath);
      });
    } on ServiceError catch (e) {
      logger.e('[USP][DHCP] Immediate delete failed', error: e);
      rethrow;
    }
    ref.invalidate(dhcpDataProvider);
  }

  // ---------------------------------------------------------------------------
  // Local Mutations (synchronous — no network calls)
  // ---------------------------------------------------------------------------

  void addReservation(DhcpReservationUIModel reservation) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        DhcpReservationList(
            reservations: [...current.reservations, reservation]),
      ),
    );
  }

  void editReservation(
      DhcpReservationUIModel oldReservation, DhcpReservationUIModel updated) {
    final reservations =
        List<DhcpReservationUIModel>.from(state.settings.current.reservations);
    final index = reservations.indexOf(oldReservation);
    if (index == -1) return;
    reservations[index] = updated;
    state = state.copyWith(
      settings: state.settings
          .update(DhcpReservationList(reservations: reservations)),
    );
  }

  void toggleReservation(DhcpReservationUIModel reservation, bool enable) {
    editReservation(reservation, reservation.copyWith(enable: enable));
  }

  void deleteReservation(DhcpReservationUIModel reservation) {
    final reservations =
        List<DhcpReservationUIModel>.from(state.settings.current.reservations);
    reservations.remove(reservation);
    state = state.copyWith(
      settings: state.settings
          .update(DhcpReservationList(reservations: reservations)),
    );
  }
}
