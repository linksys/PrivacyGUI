import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
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
  Map<String, Object?> get namedProps => {
        'firewallModel': firewallModel,
        'ruleCount': ruleSummaries.length,
        'dmzModel': dmzModel,
      };
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

  void _debouncedInvalidate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.invalidateSelf();
    });
  }
}
