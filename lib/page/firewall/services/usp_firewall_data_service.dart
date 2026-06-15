import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspFirewallDataServiceProvider = Provider<UspFirewallDataService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspFirewallDataService(usp);
  },
);

// ---------------------------------------------------------------------------
// Fetch result
// ---------------------------------------------------------------------------

/// Result of a firewall data fetch.
class FirewallDataFetchResult {
  final FirewallUIModel firewallModel;
  final FirewallRuleContext ruleContext;
  final List<FirewallRuleSummary> ruleSummaries;
  final DmzUIModel dmzModel;
  final List<DmzEntrySummary> dmzSummaries;

  const FirewallDataFetchResult({
    required this.firewallModel,
    required this.ruleContext,
    required this.ruleSummaries,
    required this.dmzModel,
    required this.dmzSummaries,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless L1 Service for fetching firewall + DMZ data.
///
/// Owns codegen calls and all transform logic for [firewallDataProvider].
class UspFirewallDataService {
  final UspClient _usp;

  UspFirewallDataService(this._usp);

  /// Fetches firewall chain rules + DMZ in parallel and builds all UI models.
  Future<FirewallDataFetchResult> fetch() async {
    final List<Object> results;
    try {
      results = await Future.wait([
        FirewallChainRules.fetch(_usp),
        Dmz.fetch(_usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

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

    // Build DMZ UIModel.
    final dmzModel = _buildDmzUIModel(dmzRaw);

    // Build per-DMZ entry summaries.
    final dmzSummaries = dmzRaw.items
        .map((d) => DmzEntrySummary(enable: d.enable, destIp: d.destIp))
        .toList();

    return FirewallDataFetchResult(
      firewallModel: firewallModel,
      ruleContext: ruleContext,
      ruleSummaries: ruleSummaries,
      dmzModel: dmzModel,
      dmzSummaries: dmzSummaries,
    );
  }

  /// Build DmzUIModel from raw codegen.
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
