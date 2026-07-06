import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_dhcp_data_service.dart';

// ── Data Model ──

class DhcpData extends Equatable with DiagnosticLoggable {
  final List<DhcpClientUIModel> clientModels;
  final List<DhcpReservationUIModel> reservationModels;

  const DhcpData({
    required this.clientModels,
    required this.reservationModels,
  });

  @override
  String get diagnosticName => 'DhcpData';

  @override
  Map<String, Object?> get namedProps => {
        'clientModels': clientModels,
        'reservationModels': reservationModels,
      };
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
    final svc = ref.read(uspDhcpDataServiceProvider);

    // Hostname enrichment: read pre-computed map from devices provider.
    final devicesData = ref.read(devicesDataProvider).valueOrNull;
    final hostNameByMac = devicesData?.hostNameByMac ?? const {};

    final result = await svc.fetch(hostNameByMac: hostNameByMac);

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
