import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_contract.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/usp_page/dashboard/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/usp_page/dhcp/models/dhcp_reservation_list.dart';
import 'package:privacy_gui/usp_page/dhcp/models/dhcp_reservations_feature_state.dart';
import 'package:privacy_gui/usp_page/dhcp/models/dhcp_reservations_status.dart';
import 'package:privacy_gui/usp_page/local_network/providers/dhcp_data_provider.dart';

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
      final usp = ref.read(uspServiceProvider)!;
      final raw = await DhcpReservations.fetch(usp);

      final reservations = raw.items
          .map((r) => DhcpReservationUIModel(
                instancePath: r.instancePath,
                mac: r.chaddr,
                ip: r.yiaddr,
                enable: r.enable,
              ))
          .toList();

      logger.d('[USP][DHCP][Reservations] Fetched — '
          'total: ${reservations.length}');

      return (
        DhcpReservationList(reservations: reservations),
        const DhcpReservationsStatus(),
      );
    } catch (e) {
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
      final usp = ref.read(uspServiceProvider)!;
      final original = state.settings.original.reservations;
      final current = state.settings.current.reservations;

      await ref.read(uspMutationLockProvider).withLock(() async {
        // 1. Delete
        final currentPaths = <String>{
          for (final r in current)
            if (r.instancePath != null) r.instancePath!,
        };
        final toDelete = original
            .where((r) =>
                r.instancePath != null &&
                !currentPaths.contains(r.instancePath))
            .toList();
        for (var i = 0; i < toDelete.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          await DhcpReservations.delete(usp, toDelete[i].instancePath!);
        }

        // 2. Add (sequential with delay to avoid bridge 504)
        final toAdd = current.where((r) => r.instancePath == null).toList();
        for (var i = 0; i < toAdd.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          final r = toAdd[i];
          await DhcpReservations.add(
            usp,
            enable: r.enable,
            chaddr: r.mac,
            yiaddr: r.ip,
          );
        }

        // 3. Update
        final originalByPath = <String, DhcpReservationUIModel>{
          for (final r in original)
            if (r.instancePath != null) r.instancePath!: r,
        };
        final toUpdate = <DhcpReservationUpdate>[];
        for (final cur in current) {
          if (cur.instancePath == null) continue;
          final orig = originalByPath[cur.instancePath!];
          if (orig == null) continue;
          if (cur != orig) {
            toUpdate.add(DhcpReservationUpdate(
              instancePath: cur.instancePath!,
              enable: cur.enable,
              chaddr: cur.mac,
              yiaddr: cur.ip,
            ));
          }
        }
        if (toUpdate.isNotEmpty) {
          await DhcpReservations.updateMany(usp, toUpdate);
        }

        logger.d('[USP][DHCP][Reservations] Batch save — '
            'added: ${toAdd.length}, updated: ${toUpdate.length}, '
            'deleted: ${toDelete.length}');
      });

      // Invalidate Layer 1 provider to refresh dashboard card
      ref.invalidate(dhcpDataProvider);
    } catch (e) {
      logger.e('[USP][DHCP][Reservations] Save failed', error: e);
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
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
    final reservations = List<DhcpReservationUIModel>.from(
        state.settings.current.reservations);
    final index = reservations.indexOf(oldReservation);
    if (index == -1) return;
    reservations[index] = updated;
    state = state.copyWith(
      settings:
          state.settings.update(DhcpReservationList(reservations: reservations)),
    );
  }

  void toggleReservation(DhcpReservationUIModel reservation, bool enable) {
    editReservation(reservation, reservation.copyWith(enable: enable));
  }

  void deleteReservation(DhcpReservationUIModel reservation) {
    final reservations = List<DhcpReservationUIModel>.from(
        state.settings.current.reservations);
    reservations.remove(reservation);
    state = state.copyWith(
      settings:
          state.settings.update(DhcpReservationList(reservations: reservations)),
    );
  }
}
