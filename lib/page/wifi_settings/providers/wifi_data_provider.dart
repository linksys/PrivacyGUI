import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/wifi_client_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/wifi_radio_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/client_connection_detail.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart';

// Re-export so existing consumers can still import WifiCodegenContext from here.
export 'package:privacy_gui/page/wifi_settings/services/usp_wifi_data_service.dart'
    show WifiCodegenContext;

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — UIModel only)
// ---------------------------------------------------------------------------

class WifiData extends Equatable with DiagnosticLoggable {
  /// Opaque codegen context for WiFi settings service consumption.
  final WifiCodegenContext codegenContext;

  // Enrichment (UI-safe types — codegen converted at boundary)
  final Map<String, WifiClientUIModel> wifiClientMap;
  final Map<String, ClientConnectionDetail> connectionDetailMap;

  // UI models (computed from raw, cached here to avoid repeated computation)
  final List<WifiRadioUIModel> radioModels;

  const WifiData({
    required this.codegenContext,
    this.wifiClientMap = const {},
    this.connectionDetailMap = const {},
    this.radioModels = const [],
  });

  const WifiData.empty()
      : codegenContext = WifiCodegenContext.empty,
        wifiClientMap = const {},
        connectionDetailMap = const {},
        radioModels = const [];

  @override
  String get diagnosticName => 'WifiData';

  @override
  Map<String, Object?> get namedProps => {
        'wifiClientMap': wifiClientMap,
        'connectionDetailMap': connectionDetailMap,
        'radioModels': radioModels,
      };

  // Explicit props override for reliable equality comparison (includes codegenContext).
  // namedProps is kept lean for diagnostic JSON output.
  @override
  List<Object?> get props => [
        codegenContext,
        wifiClientMap,
        connectionDetailMap,
        radioModels,
      ];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final wifiDataProvider =
    AsyncNotifierProvider<WifiDataNotifier, WifiData>(WifiDataNotifier.new);

// ---------------------------------------------------------------------------
// Notifier (NOT autoDispose — persists for dashboard card lifetime)
// ---------------------------------------------------------------------------

class WifiDataNotifier extends AsyncNotifier<WifiData> {
  Timer? _debounce;

  @override
  Future<WifiData> build() async {
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

    // SSE: listen for WiFi domain changes → debounce → re-fetch
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull?.domain;
      if (domain == InvalidationDomain.wifiRadios ||
          domain == InvalidationDomain.wifiSsids ||
          domain == InvalidationDomain.wifiAccessPoints ||
          domain == InvalidationDomain.wifiClients) {
        _debouncedInvalidate();
      }
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch();
  }

  Future<WifiData> _fetch() async {
    final svc = ref.read(uspWifiDataServiceProvider);
    final result = await svc.fetch();

    return WifiData(
      codegenContext: result.codegenContext,
      wifiClientMap: result.wifiClientMap,
      connectionDetailMap: result.connectionDetailMap,
      radioModels: result.radioModels,
    );
  }

  /// Which push refresh is allowed to publish — see [_refreshFromPush].
  int _pushGeneration = 0;

  /// Schedule a re-fetch that does NOT depend on anyone reading this provider.
  ///
  /// WHY NOT `invalidateSelf()` — linksys/PrivacyGUI#1615. That call discards the state
  /// and marks the provider for rebuild; riverpod runs `build()` again **when something
  /// reads the provider**. When the debounce timer fires with no reader:
  ///
  ///   - `build()` does not run, so no re-fetch happens, and
  ///   - the `ref.listen` above — which lives INSIDE `build()` — is not re-registered,
  ///     so the NEXT notification does not even reach a listener.
  ///
  /// So the first matching notification disables the mechanism. Measured: a held
  /// subscriber gave 1 fetch → 2 after a `wifiAccessPoints` event; no subscriber, 1 → 1.
  ///
  /// WAS THIS REACHABLE? Not on any current preset — `stats_panel` watches this provider
  /// and appears in all five (`usp_dashboard_preset.dart`), so something was always
  /// subscribed. That made this correct BY COINCIDENCE: the guarantee was five `const`
  /// lists all happening to include one card, not anything this provider controls, and
  /// no test would have caught its removal because every existing test holds a
  /// `container.listen`.
  ///
  /// Assigning `state` directly removes the dependency. `ref.onDispose` still cancels
  /// the timer, which matters for efficiency (a disposed notifier would otherwise issue
  /// one more USP fetch); it is not needed for correctness, because riverpod 2.6.1
  /// accepts a post-dispose `state` assignment silently rather than throwing (measured).
  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _refreshFromPush());
  }

  /// Re-read the device and publish the result, keeping the previous value on failure.
  ///
  /// Every consumer reads this through `valueOrNull`, so an error state renders as
  /// "unknown" — a transient hiccup would blank the radio list and client counts on the
  /// dashboard. A stale-but-plausible value is the better failure here.
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
      logger.w('[WiFi] push-triggered refetch failed, keeping previous value',
          error: e, stackTrace: st);
    }
  }
}
