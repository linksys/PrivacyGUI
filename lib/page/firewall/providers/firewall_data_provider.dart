import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_data_service.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

// ---------------------------------------------------------------------------
// Summary UIModels (for charts / statistics / cards)
// ---------------------------------------------------------------------------

/// Per-rule summary for chart display (target distribution, active count).
class FirewallRuleSummary extends Equatable {
  final String target;
  final bool enabled;

  const FirewallRuleSummary({required this.target, required this.enabled});

  @override
  List<Object?> get props => [target, enabled];
}

/// Per-DMZ entry summary for card display.
class DmzEntrySummary extends Equatable {
  final bool enable;
  final String destIp;

  const DmzEntrySummary({required this.enable, required this.destIp});

  @override
  List<Object?> get props => [enable, destIp];
}

// ---------------------------------------------------------------------------
// Data Model (Layer 1 — UIModel only)
// ---------------------------------------------------------------------------

class FirewallData extends Equatable with DiagnosticLoggable {
  /// Pre-built firewall toggle model.
  final FirewallUIModel firewallModel;

  /// Opaque context for save operations (consumed by firewall notifier).
  final FirewallRuleContext ruleContext;

  /// Per-rule summary for charts/statistics.
  final List<FirewallRuleSummary> ruleSummaries;

  /// DMZ UI model (single-entry abstraction).
  final DmzUIModel dmzModel;

  /// Per-DMZ entry summary for card display.
  final List<DmzEntrySummary> dmzSummaries;

  const FirewallData({
    required this.firewallModel,
    required this.ruleContext,
    required this.ruleSummaries,
    required this.dmzModel,
    required this.dmzSummaries,
  });

  const FirewallData.empty()
      : firewallModel = const FirewallUIModel(),
        ruleContext = FirewallRuleContext.empty,
        ruleSummaries = const [],
        dmzModel = const DmzUIModel.disabled(),
        dmzSummaries = const [];

  @override
  String get diagnosticName => 'FirewallData';

  @override
  Map<String, Object?> get namedProps => {
        'firewallModel': firewallModel,
        'ruleCount': ruleSummaries.length,
        'dmzModel': dmzModel,
      };

  // Explicit props override for reliable equality comparison (includes
  // ruleContext and the full rule/DMZ summary lists). namedProps is kept lean
  // for diagnostic JSON output — deriving props from it would narrow equality
  // to ruleSummaries.length and drop ruleContext/dmzSummaries, so a rule whose
  // content changed without changing the count would not notify listeners.
  @override
  List<Object?> get props =>
      [firewallModel, ruleContext, ruleSummaries, dmzModel, dmzSummaries];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final firewallDataProvider =
    AsyncNotifierProvider<FirewallDataNotifier, FirewallData>(
  FirewallDataNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier (NOT autoDispose — persists for dashboard card lifetime)
// ---------------------------------------------------------------------------

class FirewallDataNotifier extends AsyncNotifier<FirewallData> {
  Timer? _debounce;

  @override
  Future<FirewallData> build() async {
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
      if (domain == InvalidationDomain.firewallRules ||
          domain == InvalidationDomain.dmz) {
        _debouncedInvalidate();
      }
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch();
  }

  Future<FirewallData> _fetch() async {
    final svc = ref.read(uspFirewallDataServiceProvider);
    final result = await svc.fetch();

    return FirewallData(
      firewallModel: result.firewallModel,
      ruleContext: result.ruleContext,
      ruleSummaries: result.ruleSummaries,
      dmzModel: result.dmzModel,
      dmzSummaries: result.dmzSummaries,
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
  /// subscriber gave 1 fetch → 2 after a `firewallRules` event; no subscriber, 1 → 1.
  ///
  /// WAS THIS REACHABLE? **No — and the earlier claim here that it was, on the
  /// `essential` preset, was wrong.** Both domains this listener watches are produced
  /// only from `Device.Firewall.DMZ.` and `Device.Firewall.Chain.`
  /// (`sse_invalidation_provider.dart`), and NEITHER path is in the five the app
  /// subscribes to (`lib/generated/subscriptions.g.dart`). So no `firewallRules` or `dmz`
  /// notification can arrive at all, and "does anyone hold a subscription when it does"
  /// never gets asked.
  ///
  /// The measurement that suggested otherwise injected the event by hand in a test. That
  /// proves the code path is defective; it does not prove the path is reachable — a
  /// distinction worth keeping, because the opposite mistake (constructing a condition
  /// production cannot produce, then declaring a defect) is the mirror image of the one
  /// #1615 was about.
  ///
  /// It is fixed anyway: the defect is in the pattern, and a subscription added later —
  /// or a firmware that starts pushing these paths — would otherwise turn a dormant bug
  /// live with nothing to catch it.
  ///
  /// Assigning `state` directly removes the dependency entirely. `ref.onDispose` still
  /// cancels the timer, which matters for efficiency (a disposed notifier would
  /// otherwise issue one more USP fetch); it is not needed for correctness, because
  /// riverpod 2.6.1 accepts a post-dispose `state` assignment silently rather than
  /// throwing (measured).
  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _refreshFromPush());
  }

  /// Re-read the device and publish the result, keeping the previous value on failure.
  ///
  /// Every consumer reads this through `valueOrNull`, so an error state renders as
  /// "unknown" — a transient hiccup would blank the firewall and DMZ summaries. A
  /// stale-but-plausible value is the better failure here.
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
          '[Firewall] push-triggered refetch failed, keeping previous value',
          error: e,
          stackTrace: st);
    }
  }
}
