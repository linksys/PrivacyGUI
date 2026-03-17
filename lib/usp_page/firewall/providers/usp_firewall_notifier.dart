import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/firewall_chain_rules.g.dart';
import 'package:privacy_gui/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/usp_page/firewall/services/usp_firewall_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UspFirewallState extends Equatable {
  /// Original UI model (from last fetch).
  final FirewallUIModel original;

  /// User's pending changes — may differ from [original] before save.
  final FirewallUIModel pending;

  /// Parsed rule map (feature key → codegen rule instance).
  /// Retained for building SET payloads on save.
  final Map<String, FirewallChainRule> ruleMap;

  /// Whether a save operation is in progress.
  final bool isSaving;

  const UspFirewallState({
    required this.original,
    required this.pending,
    required this.ruleMap,
    this.isSaving = false,
  });

  bool get isDirty => original != pending;

  UspFirewallState copyWith({
    FirewallUIModel? original,
    FirewallUIModel? pending,
    Map<String, FirewallChainRule>? ruleMap,
    bool? isSaving,
  }) {
    return UspFirewallState(
      original: original ?? this.original,
      pending: pending ?? this.pending,
      ruleMap: ruleMap ?? this.ruleMap,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [original, pending, isSaving];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspFirewallProvider =
    AsyncNotifierProvider.autoDispose<UspFirewallNotifier, UspFirewallState>(
  UspFirewallNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspFirewallNotifier extends AutoDisposeAsyncNotifier<UspFirewallState> {
  @override
  Future<UspFirewallState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    // SSE invalidation: re-fetch when firewall rules change externally.
    // Only invalidate if user has no unsaved edits.
    ref.listen(sseInvalidationProvider, (prev, next) {
      if (next.valueOrNull == InvalidationDomain.firewallRules) {
        final s = state.valueOrNull;
        if (s != null && !s.isDirty && !s.isSaving) {
          ref.invalidateSelf();
        }
      }
    });

    // Use codegen fetch — queries Device.Firewall.Chain.1.Rule.*
    final chainRules = await FirewallChainRules.fetch(usp);

    final svc = ref.read(uspFirewallServiceProvider);
    final ruleMap = svc.parseFirewallRules(chainRules);
    final uiModel = svc.buildUIModel(rules: ruleMap);

    logger.d('[USP][Firewall]Firewall fetched — '
        'rules: ${ruleMap.length}, '
        'spiV4: ${uiModel.isIPv4FirewallEnabled}, '
        'spiV6: ${uiModel.isIPv6FirewallEnabled}');

    return UspFirewallState(
      original: uiModel,
      pending: uiModel,
      ruleMap: ruleMap,
    );
  }

  /// Update a single setting synchronously (no network call).
  void updateSetting(FirewallUIModel Function(FirewallUIModel) updater) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(pending: updater(s.pending)));
  }

  /// Save all pending changes to the router.
  ///
  /// Computes diff between [original] and [pending], then issues
  /// a batch SET via codegen [FirewallChainRules.updateMany].
  /// Re-fetches after save to confirm changes.
  Future<void> save() async {
    final s = state.requireValue;
    if (!s.isDirty) return;

    state = AsyncData(s.copyWith(isSaving: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      final svc = ref.read(uspFirewallServiceProvider);
      final updates = svc.buildSetPayload(
        original: s.original,
        pending: s.pending,
        rules: s.ruleMap,
      );

      await FirewallChainRules.updateMany(usp, updates);

      logger
          .d('[USP][Firewall]Firewall saved — ${updates.length} rules updated');

      // Re-fetch to confirm changes took effect.
      ref.invalidateSelf();
    } catch (e) {
      state = AsyncData(s.copyWith(isSaving: false));
      rethrow;
    }
  }
}
