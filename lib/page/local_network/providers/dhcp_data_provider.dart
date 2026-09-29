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
    // A REBUILD SUPERSEDES ANY PUSH IN FLIGHT, so it bumps the same counter.
    //
    // `build()` publishes through its return value, not through `_refreshFromPush`, so
    // without this a push that started BEFORE a save could complete after the post-save
    // rebuild and overwrite fresh data with pre-save data — measured, and on this provider
    // no later push arrives to correct it. Save paths that rebuild:
    // `ref.invalidate`/`ref.refresh` from the page notifiers and the retry buttons.
    //
    // Cancelling the debounce here too: a timer armed before the rebuild would otherwise
    // fire afterwards and re-fetch data the rebuild just read.
    _pushGeneration++;
    _debounce?.cancel();

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

  /// Which push refresh is allowed to publish — see [_refreshFromPush].
  int _pushGeneration = 0;

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
  /// ONLY THE NEWEST PUSH REFRESH MAY PUBLISH. `invalidateSelf()` used to give this for
  /// free — measured: riverpod coalesces repeated invalidations into one rebuild, whereas
  /// two bare `async` calls run overlapping fetches and the LAST TO COMPLETE wins. An
  /// older read then overwrites a newer one and nothing corrects it, because these
  /// providers are push-driven only.
  ///
  /// THE DEBOUNCE DOES NOT PREVENT THIS, which is worth stating because it looks like it
  /// should. `_debounce?.cancel()` only cancels a timer that has not fired yet; once it
  /// has fired and this method is awaiting, a later event starts a NEW timer and a second
  /// fetch. Measured on this provider's own shape: two events 600ms apart produced three
  /// fetches with two of them in flight together.
  ///
  /// A local counter rather than the event's `seq`: `seq` comes from the device and this
  /// code does not own its ordering guarantees, while a counter incremented here is
  /// monotonic by construction. `!=` rather than `<` for the same reason — it asks "am I
  /// still the newest?", which needs no ordering assumption at all.
  ///
  /// Same guard and same reasoning as `wan_data_provider` (#1615/#1618).
  Future<void> _refreshFromPush() async {
    final generation = ++_pushGeneration;
    try {
      final data = await _fetch();
      if (generation != _pushGeneration) return;
      state = AsyncData(data);
    } catch (e, st) {
      logger.w('[DHCP] push-triggered refetch failed, keeping previous value',
          error: e, stackTrace: st);
    }
  }
}
