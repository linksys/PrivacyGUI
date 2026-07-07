import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_dhcp_data_service.dart';

// ── Data Model ──

class DhcpData extends Equatable {
  final List<DhcpClientUIModel> clientModels;
  final List<DhcpReservationUIModel> reservationModels;

  const DhcpData({
    required this.clientModels,
    required this.reservationModels,
  });

  @override
  List<Object?> get props => [clientModels, reservationModels];
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

    // Devices listener: device online status changes affect DHCP client
    // isOnline enrichment. Only re-fetch when the online-status map actually
    // changed — DevicesData emits on any device field change (RSSI, band,
    // SSID), so a naive listener would trigger needless DHCP re-fetches.
    ref.listen(devicesDataProvider, (prev, next) {
      if (!next.hasValue || !state.hasValue) return;
      final prevOnline = <String, bool>{
        for (final d in prev?.valueOrNull?.deviceModels ?? []) d.mac: d.isActive
      };
      final nextOnline = <String, bool>{
        for (final d in next.value!.deviceModels) d.mac: d.isActive
      };
      if (!const MapEquality<String, bool>().equals(prevOnline, nextOnline)) {
        _debouncedInvalidate();
      }
    });

    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<DhcpData> _fetch() async {
    final svc = ref.read(uspDhcpDataServiceProvider);

    // Enrichment: read pre-computed maps from devices provider.
    final devicesData = ref.read(devicesDataProvider).valueOrNull;
    final hostNameByMac = devicesData?.hostNameByMac ?? const {};
    // Compute isOnlineByMac inline from deviceModels.
    final isOnlineByMac = <String, bool>{
      for (final d in devicesData?.deviceModels ?? []) d.mac: d.isActive,
    };

    final result = await svc.fetch(
      hostNameByMac: hostNameByMac,
      isOnlineByMac: isOnlineByMac,
    );

    logger.d('[USP][DhcpData]: Fetched — '
        'clients: ${result.clientModels.length}, '
        'reservations: ${result.reservationModels.length}');

    return DhcpData(
      clientModels: result.clientModels,
      reservationModels: result.reservationModels,
    );
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }
}
