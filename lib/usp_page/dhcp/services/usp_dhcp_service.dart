import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/_shared/models/dhcp_reservation_ui_model.dart';

final uspDhcpServiceProvider = Provider<UspDhcpService>(
  (ref) => UspDhcpService(ref.read(uspServiceProvider)!),
);

/// Service layer for DHCP Reservations — encapsulates codegen CRUD + transform.
class UspDhcpService {
  final UspService _usp;

  UspDhcpService(this._usp);

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Fetch DHCP reservations and transform to UI models.
  Future<List<DhcpReservationUIModel>> fetchReservations() async {
    final raw = await DhcpReservations.fetch(_usp);
    return raw.items
        .map((r) => DhcpReservationUIModel(
              instancePath: r.instancePath,
              mac: r.chaddr,
              ip: r.yiaddr,
              enable: r.enable,
            ))
        .toList();
  }

  /// Batch save: diff original vs current, execute delete/add/update.
  Future<({int added, int updated, int deleted})> saveBatch({
    required List<DhcpReservationUIModel> original,
    required List<DhcpReservationUIModel> current,
  }) async {
    // 1. Delete (in original, not in current)
    final currentPaths = <String>{
      for (final r in current)
        if (r.instancePath != null) r.instancePath!,
    };
    final toDelete = original
        .where((r) =>
            r.instancePath != null && !currentPaths.contains(r.instancePath))
        .toList();

    for (var i = 0; i < toDelete.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      await DhcpReservations.delete(_usp, toDelete[i].instancePath!);
    }

    // 2. Add (sequential with delay to avoid bridge 504)
    final toAdd = current.where((r) => r.instancePath == null).toList();

    for (var i = 0; i < toAdd.length; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      final r = toAdd[i];
      await DhcpReservations.add(
        _usp,
        enable: r.enable,
        chaddr: r.mac,
        yiaddr: r.ip,
      );
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
      await DhcpReservations.updateMany(_usp, toUpdate);
    }

    return (
      added: toAdd.length,
      updated: toUpdate.length,
      deleted: toDelete.length,
    );
  }
}
