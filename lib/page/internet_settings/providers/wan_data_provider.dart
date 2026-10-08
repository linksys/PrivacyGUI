import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';

// ── Data Model ──

class WanData extends Equatable with DiagnosticLoggable {
  final WanStatusUIModel model;

  const WanData({required this.model});

  @override
  String get diagnosticName => 'WanData';

  @override
  Map<String, Object?> get namedProps => {'model': model};
}

// ── Provider ──

/// Layer 1 data provider for WAN status.
///
/// SSE invalidation: listens to [InvalidationDomain.wanStatus] for
/// WAN interface status changes (Up/Down, IP address changes).
final wanDataProvider =
    AsyncNotifierProvider<WanDataNotifier, WanData>(WanDataNotifier.new);

/// Whether the WAN is online — **the one definition for the whole app** (#1620).
///
/// `null` means "not read yet", and it is a third answer rather than a default.
/// Two places used to answer this question differently: this provider defaulted
/// an unread L1 to `true` so the dashboard would not flash an offline banner on
/// launch, while `wanIpReadingProvider` answered `unknown` so the Internet
/// Settings banner would not claim "offline" about a device it had failed to
/// read. Both choices were right for their own screen and neither was wrong —
/// but they were two definitions, so the dashboard and Internet Settings could
/// disagree about the same router at the same moment.
///
/// Returning `null` keeps both behaviours and moves the choice to the caller:
/// a screen that prefers optimism writes `?? true`, one that must not claim
/// anything handles `null` explicitly. What callers no longer get to choose is
/// **what online means**.
///
/// ## Online is `Status == 'Up'`, not "has an address"
///
/// Measured on real hardware (M60-US, FW 2.0.2.26091803, 2026-10-01): after
/// `ifup`, `Status` reads `Up` for about **5 seconds before an address
/// arrives**. Reading "online" from the address would therefore report offline
/// through every link recovery — a replugged cable, a modem reboot — and a red
/// banner during normal recovery is worse than being five seconds early.
///
/// Going down there is no disagreement to settle: `Status` and
/// `IPv4Address.1.*` change together, and the address leaf disappears rather
/// than emptying.
///
/// The address itself is a separate question with its own three states, and
/// stays in `WanIpReading` — that type still answers "what address do we show",
/// it just no longer answers "are we online".
///
/// `null` after the first successful read is rarer than it looks, but it is reachable: an
/// SSE-triggered refresh assigns `state` directly (`_refreshFromPush`) and never passes
/// through loading, while `ref.invalidate(wanDataProvider)` — which the save and DHCP-renew
/// paths both call — does. So a caller's `??` is exercised on launch and again briefly
/// after a save. See #1143, #1615, #1620.
final wanIsUpProvider = Provider<bool?>(
  (ref) => ref.watch(wanDataProvider).valueOrNull?.model.isUp,
);

// ── Notifier (NOT autoDispose) ──

class WanDataNotifier extends AsyncNotifier<WanData> {
  @override
  Future<WanData> build() async {
    // A REBUILD SUPERSEDES ANY PUSH IN FLIGHT, so it bumps the same counter.
    //
    // `build()` publishes through its return value rather than through
    // `_refreshFromPush`, so without this a push that started BEFORE a save could complete
    // after the post-save rebuild and overwrite fresh data with pre-save data. Measured on
    // `firewallDataProvider`, which has the identical shape; the save paths here are
    // `usp_internet_settings_notifier.dart`'s `ref.invalidate` after a WAN save and after a
    // DHCP renew — the two moments a user is most likely to be watching the address.
    _pushGeneration++;

    // SSE listener: WAN status changes (link up/down, IP changes)
    // Logged on both sides of the branch. Knowing the listener RAN but did not match is
    // a different fact from it never running, and that distinction is what identified
    // #1615: the listener fired, the old `invalidateSelf()` was called, and `build()`
    // was never re-entered — so nothing below this line ran again and the listener was
    // never re-registered. Without a log here that was indistinguishable from the
    // notification never arriving. See linksys/PrivacyGUI-RealRouter-E2E's R20 spec
    // header for the measurement.
    ref.listen(sseInvalidationProvider, (_, next) {
      final domain = next.valueOrNull?.domain;
      if (domain == InvalidationDomain.wanStatus) {
        logger.d('[WAN] wanStatus invalidation (seq=${next.valueOrNull?.seq}) '
            '→ refetch');
        _refreshFromPush();
      } else {
        logger.t('[WAN] ignoring ${domain?.name ?? 'no-domain'} invalidation');
      }
    });

    // Tunnel creation/deletion need not emit the legacy WAN object's SSE event.
    if (ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.autoIPoE)) {
      final timer = Timer.periodic(
          const Duration(seconds: 15), (_) => _refreshFromPush());
      ref.onDispose(timer.cancel);
    }
    return _fetch();
  }

  /// Re-read the device and publish the result, WITHOUT depending on anyone reading
  /// this provider afterwards.
  ///
  /// WHY NOT `invalidateSelf()` — linksys/PrivacyGUI#1615. That call discards the state
  /// and marks the provider for rebuild, and riverpod runs `build()` again **when
  /// something reads the provider**. Nothing guarantees a reader at the moment an SSE
  /// notification arrives, and when there is none:
  ///
  ///   - `build()` does not run, so no re-fetch happens, and
  ///   - the `ref.listen` above — which lives INSIDE `build()` — is not re-registered,
  ///     so the NEXT notification does not even reach the listener.
  ///
  /// That second consequence is what makes it worse than a missed refresh: **the first
  /// matching notification disables the mechanism.** Measured on FW 2.0 (the listener
  /// fires once, `invalidateSelf()` is called, and no fetch ever follows), and pinned in
  /// `wan_data_provider_test.dart` by a test that holds no listener.
  ///
  /// Assigning `state` directly is what removes the dependency: the new value is
  /// published whether or not anything is watching, and `build()` — with its
  /// `ref.listen` — stays alive because it is never torn down.
  ///
  /// ON FAILURE IT KEEPS THE PREVIOUS VALUE rather than moving to `AsyncError`. Every
  /// consumer reads this through `valueOrNull` (see `wanIsUpProvider`), so an error
  /// state renders as "unknown" — a transient device hiccup would blank the WAN address
  /// on the dashboard. A stale-but-plausible value is the better failure here, and the
  /// same reasoning is already recorded for the loading case (#1143).
  /// Which push refresh is allowed to publish. See [_refreshFromPush].
  int _pushGeneration = 0;

  /// ONLY THE NEWEST PUSH REFRESH MAY PUBLISH — and this is what `invalidateSelf()` used
  /// to give for free, so dropping it created a hazard that had to be replaced rather
  /// than merely noted.
  ///
  /// Measured: two `invalidateSelf()` calls inside one fetch window produce ONE rebuild
  /// (riverpod coalesces them), whereas two bare `async` calls run two overlapping
  /// fetches and the LAST TO COMPLETE wins. `_fetch()` fans out over several USP `get`s
  /// through a throttler against a single-threaded OBUSPA, so that window is wide enough
  /// to matter:
  ///
  ///   seq=N   link DOWN  → fetch A starts
  ///   seq=N+1 link UP    → fetch B starts while A is in flight
  ///   B completes        → state = up      (correct)
  ///   A completes        → state = DOWN    (the older device read wins)
  ///
  /// With Auto-IPoE disabled this provider is push-driven only — not autoDispose,
  /// and this method deliberately avoids invalidation — so a settled WAN that
  /// sends no further notification leaves the dashboard, Statistics and health scoring
  /// reporting a dead link indefinitely. Reproduced in
  /// `wan_data_provider_test.dart` before fixing it.
  ///
  /// A LOCAL COUNTER, NOT THE EVENT'S `seq`. `seq` comes from the device and this code
  /// does not own its ordering guarantees; a monotonic counter incremented here is true
  /// by construction. The comparison is `!=` rather than `<` for the same reason — it
  /// asks "am I still the newest?", which needs no assumption about ordering at all.
  ///
  /// The stale fetch's RESULT is discarded, not its request: cancelling an in-flight USP
  /// read is not something the client offers, and the wasted round trip is cheaper than
  /// the wrong value.
  Future<void> _refreshFromPush() async {
    final generation = ++_pushGeneration;
    try {
      final data = await _fetch();
      if (generation != _pushGeneration) {
        logger.d('[WAN] discarding push refresh $generation, superseded by '
            '$_pushGeneration');
        return;
      }
      state = AsyncData(data);
    } catch (e, st) {
      // Deliberately not rethrown and not surfaced as AsyncError — see above.
      logger.w('[WAN] push-triggered refetch failed, keeping previous value',
          error: e, stackTrace: st);
    }
  }

  Future<WanData> _fetch() async {
    final svc = ref.read(uspWanDataServiceProvider);
    final model = await svc.fetch();
    // The counterpart to the listener log above: together they show whether an
    // invalidation actually produced a re-fetch, which is the link that was broken on
    // FW 2.0.
    logger.d('[WAN] fetched: isUp=${model.isUp} ip="${model.ipAddress}"');

    return WanData(model: model);
  }
}
