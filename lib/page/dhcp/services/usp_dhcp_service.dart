import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/_shared/services/empty_row.dart';
import 'package:privacy_gui/page/_shared/utils/lan_dhcp_pool_pick.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';

final uspDhcpServiceProvider = Provider<UspDhcpService>(
  (ref) => UspDhcpService(ref.read(uspClientProvider)!),
);

/// Service layer for DHCP Reservations — encapsulates codegen CRUD + transform.
class UspDhcpService {
  final UspClient _usp;

  UspDhcpService(this._usp);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch DHCP reservations and transform to UI models.
  Future<List<DhcpReservationUIModel>> fetchReservations() async {
    try {
      final pool = _lanPool(await DhcpReservations.fetch(_usp));
      // A row with every value blank is no reservation (0.17 dropped it).
      return (pool?.staticAddresses ?? const <DhcpReservation>[])
          .where((r) => !isEmptyDhcpReservation(r))
          .map((r) => DhcpReservationUIModel(
                instancePath: r.instancePath,
                mac: r.chaddr,
                ip: r.yiaddr,
                enable: r.enable,
              ))
          .toList();
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The LAN pool's reservation table, or null when the router lists none.
  static DhcpReservationPool? _lanPool(DhcpReservations reservations) =>
      lanDhcpPoolOf(reservations.items, (p) => p.alias);

  /// The path new reservations are added under: the LAN pool's.
  Future<String> _lanPoolPath() async {
    final pool = _lanPool(await DhcpReservations.fetch(_usp));
    if (pool == null) {
      throw const ResourceNotFoundError(
          detail: 'No DHCP pool with Alias $lanDhcpPoolAlias on the router');
    }
    return pool.instancePath;
  }

  // ---------------------------------------------------------------------------
  // Immediate mutations (Dashboard card / Device Detail — single operations)
  // ---------------------------------------------------------------------------

  /// Toggle a single reservation's enable state.
  Future<void> immediateToggle(String instancePath, bool enable) async {
    try {
      final result = await DhcpReservations.updateStaticAddresses(
        _usp,
        [DhcpReservationUpdate(instancePath: instancePath, enable: enable)],
      );
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'DHCP toggle partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'DHCP toggle failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Add a single reservation immediately.
  Future<void> immediateAdd({
    required String mac,
    required String ip,
    bool enable = true,
  }) async {
    try {
      final result = await DhcpReservations.addStaticAddresses(_usp, [
        DhcpReservationAdd(
          parentInstancePath: await _lanPoolPath(),
          enable: enable,
          chaddr: mac,
          yiaddr: ip,
        ),
      ]);
      final parsed = UspResultParser.parseAddResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'DHCP add partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'DHCP add failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Delete a single reservation immediately.
  Future<void> immediateDelete(String instancePath) async {
    try {
      final result =
          await DhcpReservations.deleteStaticAddresses(_usp, [instancePath]);
      final parsed = UspResultParser.parseDeleteResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'DHCP delete partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'DHCP delete failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Batch save
  // ---------------------------------------------------------------------------

  /// Batch save: diff original vs current, execute delete/add/update.
  ///
  /// Lenient mode: partial success is acceptable for batch operations,
  /// only log warnings. Complete failure still throws.
  Future<({int added, int updated, int deleted})> saveBatch({
    required List<DhcpReservationUIModel> original,
    required List<DhcpReservationUIModel> current,
  }) async {
    try {
      // 1. Delete (in original, not in current)
      final currentPaths = <String>{
        for (final r in current)
          if (r.instancePath != null) r.instancePath!,
      };
      final toDelete = original
          .where((r) =>
              r.instancePath != null && !currentPaths.contains(r.instancePath))
          .toList();

      // Delete in reverse instance order to avoid firmware renumbering issues
      for (final r in toDelete.reversed) {
        final result = await DhcpReservations.deleteStaticAddresses(
            _usp, [r.instancePath!]);
        final parsed = UspResultParser.parseDeleteResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(:final successes, :final failures):
            logger.w(
                '[DHCP]: Batch delete partial: ${successes.length} ok, ${failures.length} failed');
            break;
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'DHCP batch delete failed: $errorSummary',
              failures: errors,
            );
        }
      }

      // 2. Add
      final toAdd = current.where((r) => r.instancePath == null).toList();
      if (toAdd.isNotEmpty) {
        final poolPath = await _lanPoolPath();
        final result = await DhcpReservations.addStaticAddresses(
          _usp,
          toAdd
              .map((r) => DhcpReservationAdd(
                    parentInstancePath: poolPath,
                    enable: r.enable,
                    chaddr: r.mac,
                    yiaddr: r.ip,
                  ))
              .toList(),
        );
        final parsed = UspResultParser.parseAddResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(:final successes, :final failures):
            logger.w(
                '[DHCP]: Batch add partial: ${successes.length} ok, ${failures.length} failed');
            break;
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'DHCP batch add failed: $errorSummary',
              failures: errors,
            );
        }
      }

      // 3. Update (same path, different content)
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
        final result =
            await DhcpReservations.updateStaticAddresses(_usp, toUpdate);
        final parsed = UspResultParser.parseSetResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(:final successes, :final failures):
            logger.w(
                '[DHCP]: Batch update partial: ${successes.length} ok, ${failures.length} failed');
            break;
          case UspFailure(:final errorSummary, :final errors):
            throw UspCompleteFailureError(
              summary: 'DHCP batch update failed: $errorSummary',
              failures: errors,
            );
        }
      }

      return (
        added: toAdd.length,
        updated: toUpdate.length,
        deleted: toDelete.length,
      );
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }
}
