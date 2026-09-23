import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
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
      final domain = next.valueOrNull?.domain;
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
        for (final d in prev?.valueOrNull?.clientDevices ?? [])
          d.mac: d.isActive
      };
      final nextOnline = <String, bool>{
        for (final d in next.value!.clientDevices) d.mac: d.isActive
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
    // Compute isOnlineByMac inline from clientDevices (mesh nodes never hold
    // DHCP leases, so their MACs cannot appear in DHCP client models).
    final isOnlineByMac = <String, bool>{
      for (final d in devicesData?.clientDevices ?? []) d.mac: d.isActive,
    };

    final result = await svc.fetch(
      hostNameByMac: hostNameByMac,
      isOnlineByMac: isOnlineByMac,
    );

    return DhcpData(
      clientModels: result.clientModels,
      reservationModels: result.reservationModels,
    );
  }

  /// Schedule a re-fetch that does NOT depend on anyone reading this provider.
  ///
  /// WHY NOT `invalidateSelf()` — linksys/PrivacyGUI#1615. That call discards the state
  /// and marks the provider for rebuild; riverpod runs `build()` again **when something
  /// reads the provider**. Nothing guarantees a reader when the debounce timer fires,
  /// and when there is none:
  ///
  ///   - `build()` does not run, so no re-fetch happens, and
  ///   - the two `ref.listen` calls above — which live INSIDE `build()` — are not
  ///     re-registered, so the NEXT notification does not even reach a listener.
  ///
  /// The second consequence is what makes it worse than a missed refresh: **the first
  /// matching notification disables the mechanism.** Measured for this provider:
  /// holding a subscriber gave 2 fetches → 4 after a `dhcpClients` event; holding none
  /// gave 2 → 2.
  ///
  /// THIS PROVIDER WAS THE ONE ACTUALLY BROKEN IN PRODUCTION. Its only dashboard
  /// consumer is the `dhcp_reservations` card, which appears solely in the
  /// `professional` preset (`usp_dashboard_preset.dart`), so on the default `standard`
  /// preset nothing watched it once the user left the Local Network page — exactly
  /// `wanDataProvider`'s situation in #1615.
  ///
  /// Assigning `state` directly removes the dependency: the value is published whether
  /// or not anything is watching, and `build()` — with its listeners — is never torn
  /// down. `ref.onDispose` still cancels the timer, which matters for efficiency (a
  /// disposed notifier would otherwise issue one more USP fetch); it is not needed for
  /// correctness, because riverpod 2.6.1 accepts a post-dispose `state` assignment
  /// silently rather than throwing (measured).
  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _refreshFromPush());
  }

  /// Re-read the device and publish the result, keeping the previous value on failure.
  ///
  /// An error state would render as "unknown" to every consumer (all read through
  /// `valueOrNull`), so a transient device hiccup would blank the client and
  /// reservation lists. A stale-but-plausible value is the better failure here — the
  /// same reasoning `wanDataProvider` records for #1615.
  Future<void> _refreshFromPush() async {
    try {
      state = AsyncData(await _fetch());
    } catch (e, st) {
      logger.w('[DHCP] push-triggered refetch failed, keeping previous value',
          error: e, stackTrace: st);
    }
  }
}
