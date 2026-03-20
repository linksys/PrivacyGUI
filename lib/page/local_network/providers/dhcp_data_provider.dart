import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/dhcp_clients.g.dart';
import 'package:privacy_gui/generated/dhcp_reservations.g.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

// ── Data Model ──

class DhcpData extends Equatable {
  final List<DhcpClientUIModel> clientModels;
  final List<DhcpReservationUIModel> reservationModels;

  const DhcpData({
    required this.clientModels,
    required this.reservationModels,
  });

  @override
  List<Object?> get props => [
        clientModels.length,
        reservationModels.length,
      ];
}

// ── Provider ──

final dhcpDataProvider =
    AsyncNotifierProvider<DhcpDataNotifier, DhcpData>(DhcpDataNotifier.new);

// ── Notifier (NOT autoDispose) ──

class DhcpDataNotifier extends AsyncNotifier<DhcpData> {
  Timer? _debounce;

  @override
  Future<DhcpData> build() async {
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.dhcpReservations ||
          domain == InvalidationDomain.dhcpClients) {
        _debouncedInvalidate();
      }
    });
    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<DhcpData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      DhcpClients.fetch(usp),
      DhcpReservations.fetch(usp),
    ]);

    final clients = results[0] as DhcpClients;
    final reservations = results[1] as DhcpReservations;

    // Hostname enrichment: read pre-computed map from devices provider.
    final devicesData = ref.read(devicesDataProvider).valueOrNull;
    final hostNameByMac = devicesData?.hostNameByMac ?? const {};

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

    logger.d('[USP][DhcpData] Fetched — '
        'clients: ${clients.items.length}, '
        'reservations: ${reservations.items.length}');

    return DhcpData(
      clientModels: clientModels,
      reservationModels: reservationModels,
    );
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }

  // ── Mutations ──

  Future<void> toggleReservation(String instancePath, bool enable) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = ref.read(uspServiceProvider)!;
      await DhcpReservations.update(
        usp,
        DhcpReservationUpdate(instancePath: instancePath, enable: enable),
      );
    });
    ref.invalidateSelf();
  }

  Future<void> addReservation({
    required String mac,
    required String ip,
    bool enable = true,
  }) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = ref.read(uspServiceProvider)!;
      await DhcpReservations.add(usp, enable: enable, chaddr: mac, yiaddr: ip);
    });
    ref.invalidateSelf();
  }

  Future<void> updateReservation({
    required String instancePath,
    String? mac,
    String? ip,
    bool? enable,
  }) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = ref.read(uspServiceProvider)!;
      await DhcpReservations.update(
        usp,
        DhcpReservationUpdate(
          instancePath: instancePath,
          enable: enable,
          chaddr: mac,
          yiaddr: ip,
        ),
      );
    });
    ref.invalidateSelf();
  }

  Future<void> deleteReservation(String instancePath) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = ref.read(uspServiceProvider)!;
      await DhcpReservations.delete(usp, instancePath);
    });
    ref.invalidateSelf();
  }
}
