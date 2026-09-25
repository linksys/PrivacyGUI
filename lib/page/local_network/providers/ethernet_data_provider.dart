import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/ethernet_port_ui_model.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/services/usp_ethernet_data_service.dart';

/// Layer 1 Ethernet Data Provider — port UI models.
///
/// NOT autoDispose — persists across tab switches.
/// Listens to [devicesDataProvider] to re-fetch when device list changes.
final ethernetDataProvider =
    AsyncNotifierProvider<EthernetDataNotifier, EthernetData>(
  EthernetDataNotifier.new,
);

/// Aggregated Ethernet data: presentation-layer port models.
class EthernetData extends Equatable with DiagnosticLoggable {
  final List<EthernetPortUIModel> ethernetPortModels;

  const EthernetData({
    this.ethernetPortModels = const [],
  });

  EthernetData copyWith({
    List<EthernetPortUIModel>? ethernetPortModels,
  }) {
    return EthernetData(
      ethernetPortModels: ethernetPortModels ?? this.ethernetPortModels,
    );
  }

  @override
  String get diagnosticName => 'EthernetData';

  @override
  Map<String, Object?> get namedProps => {
        'ethernetPortModels': ethernetPortModels,
      };
}

class EthernetDataNotifier extends AsyncNotifier<EthernetData> {
  /// The `deviceModels` list the most recent [_fetch] passed to the service.
  ///
  /// This, not the listener's `prev` argument, is what the devices listener
  /// compares against — see the comment at the listener. Whether riverpod
  /// reuses this notifier across builds or creates a fresh one does not matter:
  /// [_fetch] writes the field before its await, so the listener never compares
  /// against a stale generation, and the initial `const []` is exactly what the
  /// first fetch consumes when `devicesDataProvider` has not settled yet.
  List<ClientDevice> _consumedDevices = const [];

  @override
  Future<EthernetData> build() async {
    // SSE listener: Ethernet interface status changes (link up/down)
    //
    // `_refreshFromPush()`, not `invalidateSelf()` — see that method for why.
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.valueOrNull?.domain == InvalidationDomain.ethernetInterfaces) {
        _refreshFromPush();
      }
    });

    // Devices listener: device list changes affect which wired devices
    // show on LAN ports. Re-fetch to get fresh Ethernet data.
    //
    // Compare the exact input _fetch() consumes — `clientDevices`, the only
    // thing passed to the service at :78 — rather than re-fetching on every
    // DevicesData emission. In riverpod 2.6.1 an AsyncNotifier re-notifies on
    // every data→data transition even when the payload is identical, so the
    // unguarded version spent one Ethernet USP fetch per redundant emission.
    // Skipping is lossless: causes that are not the device list arrive via the
    // SSE listener above.
    //
    // `ListEquality`, not `==`: `clientDevices` is a plain List built fresh by
    // `MeshNetwork.allClients`, so `==` is reference equality and would make
    // this guard inert. Template: dhcp_data_provider.dart:58 (MapEquality).
    // The *elements* do compare by value — `ClientDevice extends NetworkEntity`,
    // which is `EquatableMixin` — so the comparison is deep end to end. If a
    // future model drops that, this guard silently reverts to always-unequal.
    //
    // The comparison is against [_consumedDevices] — what the last _fetch()
    // actually passed to the service — not against `prev`. Using `prev` was
    // wrong in two ways, both reachable on a normal dashboard boot, because
    // the orchestrator triggers devices and ethernet back to back
    // (dashboard_orchestrator.dart:158-159) so the two settle in a race:
    //
    //  - Ethernet wins: its _fetch() read devicesData as AsyncLoading and
    //    passed []. At the settle `prev` carries no value, and
    //    `ListEquality.equals(null, [...])` is false, so an *empty* device list
    //    looked like a change and cost a second fetch on identical input.
    //  - Devices wins: the settle arrives while this provider's own _fetch() is
    //    still in flight, so a `state.hasValue` guard drops it — and the fetch
    //    it would have corrected already consumed []. Ethernet then serves port
    //    models built from an empty device list until the list changes again or
    //    an `ethernetInterfaces` SSE event lands.
    //
    // A field holding the consumed input answers both without a special case
    // for "no previous value": it starts as the empty list the first fetch
    // really does consume, and it is written before the await, so a settle
    // arriving mid-fetch still compares against the right thing.
    ref.listen(devicesDataProvider, (_, next) {
      final devices = next.valueOrNull?.clientDevices;
      if (devices == null) return;
      if (const ListEquality<ClientDevice>()
          .equals(_consumedDevices, devices)) {
        return;
      }
      // Same reason as the SSE listener above: this fires from outside a build, so
      // `invalidateSelf()` would need a reader that nothing guarantees.
      _refreshFromPush();
    });

    return _fetch();
  }

  /// Which push refresh is allowed to publish — see [_refreshFromPush].
  int _pushGeneration = 0;

  /// Re-read the device and publish the result, WITHOUT depending on anyone reading this
  /// provider afterwards.
  ///
  /// WHY NOT `invalidateSelf()` — linksys/PrivacyGUI#1615. That call discards the state
  /// and marks the provider for rebuild; riverpod runs `build()` again **when something
  /// reads the provider**. Both listeners above fire from outside a build, and when
  /// there is no reader at that moment:
  ///
  ///   - `build()` does not run, so no re-fetch happens, and
  ///   - both `ref.listen` calls — which live INSIDE `build()` — are not re-registered,
  ///     so the NEXT notification does not even reach a listener.
  ///
  /// So the first matching notification disables BOTH paths, not just the one that
  /// fired. Measured: a held subscriber gave 1 fetch → 2 after an `ethernetInterfaces`
  /// event; no subscriber, 1 → 1. This provider has no debounce, which makes no
  /// difference — the defect is the pattern, not the timing.
  ///
  /// WAS THIS REACHABLE? Not on any current preset — both `stats_panel` and the
  /// `ethernet_ports` card watch this provider and `stats_panel` appears in all five
  /// (`usp_dashboard_preset.dart`), so something was always subscribed. That made this
  /// correct BY COINCIDENCE: the guarantee was a `const` list in a preset definition,
  /// and no test would have caught its removal because every existing test holds a
  /// `container.listen`.
  ///
  /// Assigning `state` directly removes the dependency entirely.
  ///
  /// ON FAILURE IT KEEPS THE PREVIOUS VALUE. Consumers read through `valueOrNull`, so an
  /// error state renders as "unknown" — a transient hiccup would blank the port list on
  /// the dashboard and the Local Network page.
  ///
  /// NOTE ON `_consumedDevices`: `_fetch()` writes it before its await, so the devices
  /// listener's equality guard still compares against what the last fetch really
  /// consumed. Going through `state =` rather than a rebuild does not change that — the
  /// same `_fetch()` runs either way, on the same notifier instance.
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
      logger.w(
          '[Ethernet] push-triggered refetch failed, keeping previous value',
          error: e,
          stackTrace: st);
    }
  }

  Future<EthernetData> _fetch() async {
    final svc = ref.read(uspEthernetDataServiceProvider);
    final devicesData = ref.read(devicesDataProvider).valueOrNull;
    final devices = devicesData?.clientDevices ?? const <ClientDevice>[];
    // Written before the await so a settle arriving mid-fetch compares against
    // the input this fetch is actually consuming.
    _consumedDevices = devices;

    final result = await svc.fetch(deviceModels: devices);

    return EthernetData(ethernetPortModels: result.portModels);
  }
}
