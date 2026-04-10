import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
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

class FirewallData extends Equatable {
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
    // SSE: listen for firewall / DMZ domain changes → debounce → re-fetch
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.firewallRules ||
          domain == InvalidationDomain.dmz) {
        _debouncedInvalidate();
      }
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch();
  }

  Future<FirewallData> _fetch() async {
    final usp = ref.read(uspClientProvider);
    if (usp == null) throw StateError('USP service not available');

    final results = await Future.wait([
      FirewallChainRules.fetch(usp),
      Dmz.fetch(usp),
    ]);

    final chainRules = results[0] as FirewallChainRules;
    final dmzRaw = results[1] as Dmz;

    // Build firewall UIModel + opaque context via service statics.
    final ruleMap = UspFirewallService.parseFirewallRules(chainRules);
    final firewallModel = UspFirewallService.buildUIModel(rules: ruleMap);
    final ruleContext = FirewallRuleContext.fromMap(ruleMap);

    // Build per-rule summaries for chart display.
    final ruleSummaries = chainRules.items
        .map((r) => FirewallRuleSummary(target: r.target, enabled: r.enable))
        .toList();

    // Build DMZ UIModel (first entry or disabled).
    final dmzModel = _buildDmzUIModel(dmzRaw);

    // Build per-DMZ entry summaries.
    final dmzSummaries = dmzRaw.items
        .map((d) => DmzEntrySummary(enable: d.enable, destIp: d.destIp))
        .toList();

    logger.d('[USP][FirewallData] Fetched — '
        'rules: ${chainRules.items.length}, '
        'dmz: ${dmzRaw.items.length}');

    return FirewallData(
      firewallModel: firewallModel,
      ruleContext: ruleContext,
      ruleSummaries: ruleSummaries,
      dmzModel: dmzModel,
      dmzSummaries: dmzSummaries,
    );
  }

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }

  /// Build DmzUIModel from raw codegen (inlined from UspDmzService).
  static DmzUIModel _buildDmzUIModel(Dmz data) {
    if (data.items.isEmpty) return const DmzUIModel.disabled();
    final entry = data.items.first;
    final sourceType =
        (entry.sourcePrefix.isEmpty || entry.sourcePrefix == '0.0.0.0/0')
            ? DmzSourceType.any
            : DmzSourceType.cidr;
    return DmzUIModel(
      isEnabled: entry.enable,
      destIp: entry.destIp,
      sourceType: sourceType,
      sourcePrefix: entry.sourcePrefix,
    );
  }
}
