import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_feature_state.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_settings.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_forwarding_page_status.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspPortForwardingPageProvider = AutoDisposeNotifierProvider<
    UspPortForwardingPageNotifier, PortForwardingPageFeatureState>(
  UspPortForwardingPageNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspPortForwardingPageNotifier
    extends AutoDisposeNotifier<PortForwardingPageFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<PortForwardingPageSettings,
            PortForwardingPageStatus, PortForwardingPageFeatureState> {
  UspPortForwardingService get _svc =>
      ref.read(uspPortForwardingServiceProvider);

  @override
  PortForwardingPageFeatureState build() {
    Future.microtask(() => fetch());
    return PortForwardingPageFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch
  // ---------------------------------------------------------------------------

  @override
  Future<(PortForwardingPageSettings?, PortForwardingPageStatus?)>
      performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final results = await Future.wait([
        _svc.fetchForwardingRules(),
        _svc.fetchTriggeringRules(),
      ]);

      final forwardingRules = results[0] as List<PortForwardingRuleUIModel>;
      final triggeringRules = results[1] as List<PortTriggeringRuleUIModel>;

      logger.d('[USP][Firewall][PortForwarding]: Fetched — '
          'forwarding: ${forwardingRules.length}, '
          'triggering: ${triggeringRules.length}');

      return (
        PortForwardingPageSettings(
          forwardingRules: forwardingRules,
          triggeringRules: triggeringRules,
        ),
        const PortForwardingPageStatus(),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][Firewall][PortForwarding]: Fetch failed', error: e);
      return (
        null,
        PortForwardingPageStatus(error: e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // save — re-read the router after a save that wrote some rules
  // ---------------------------------------------------------------------------

  /// A failed save that has already written some rules re-reads the router, so
  /// those rules carry their instance paths: otherwise a second Save would Add
  /// them again. The error still reaches the page. A save that wrote nothing
  /// keeps the user's edits for a retry.
  ///
  /// [performSave] reports "wrote some" as a [UspPartialFailureError], whichever
  /// batch it came from, so the error type alone tells the two apart.
  @override
  Future<PortForwardingPageFeatureState> save() async {
    try {
      return await super.save();
    } on UspPartialFailureError {
      await fetch(forceRemote: true);
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — diff original vs current, batch API calls
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );

    try {
      final originalPf = state.settings.original.forwardingRules;
      final currentPf = state.settings.current.forwardingRules;
      final originalPt = state.settings.original.triggeringRules;
      final currentPt = state.settings.current.triggeringRules;

      // Both batches always run: a refused forwarding step must not keep the
      // triggering edits in the same Save from being sent.
      final (pf, pt) =
          await ref.read(uspMutationLockProvider).withLock(() async {
        final pf = await _runBatch(() => _svc.saveForwardingBatch(
              original: originalPf,
              current: currentPf,
            ));
        final pt = await _runBatch(() => _svc.saveTriggeringBatch(
              original: originalPt,
              current: currentPt,
            ));
        return (pf, pt);
      });

      final wrote = pf.wrote || pt.wrote;
      // The dashboard card and the dialogs' overlap and limit checks read the
      // shared lists, so a save that wrote anything refreshes them.
      if (wrote) _refreshSharedLists();

      final error = pf.error ?? pt.error;
      if (error == null) return;
      logger.e('[USP][Firewall][PortForwarding]: Save failed', error: error);
      // Each batch is tallied on its own, so one that wrote nothing reports a
      // complete failure even when the other wrote every rule. For the save as
      // a whole that is a partial failure, and [save] re-reads on that.
      if (wrote && error is! UspPartialFailureError) {
        throw UspPartialFailureError(
          summary: error.toString(),
          successPaths: const [],
          failures: switch (error) {
            UspCompleteFailureError(:final failures) => failures,
            _ => const [],
          },
          code: error.code,
          detail: error.detail,
        );
      }
      throw error;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  /// Run one batch, reporting what it did instead of throwing.
  ///
  /// "Wrote" follows the tally's classes: a returned count above zero or a
  /// partial failure wrote rules, a complete failure wrote none. Any other
  /// [ServiceError] (transport, timeout) is counted as nothing written.
  Future<({bool wrote, ServiceError? error})> _runBatch(
    Future<({int added, int updated, int deleted})> Function() batch,
  ) async {
    try {
      final r = await batch();
      logger.d('[USP][Firewall][PortForwarding]: Batch — '
          'added: ${r.added}, updated: ${r.updated}, deleted: ${r.deleted}');
      return (wrote: r.added + r.updated + r.deleted > 0, error: null);
    } on UspPartialFailureError catch (e) {
      return (wrote: true, error: e);
    } on ServiceError catch (e) {
      return (wrote: false, error: e);
    }
  }

  /// Invalidate Layer 1 so the dashboard card re-reads the router.
  void _refreshSharedLists() {
    ref.invalidate(portForwardingDataProvider);
    ref.invalidate(portTriggeringDataProvider);
  }

  // ---------------------------------------------------------------------------
  // Local Mutations — Port Forwarding
  // ---------------------------------------------------------------------------

  void addForwardingRule(PortForwardingRuleUIModel rule) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: [...current.forwardingRules, rule],
          triggeringRules: current.triggeringRules,
        ),
      ),
    );
  }

  void editForwardingRule(
      PortForwardingRuleUIModel oldRule, PortForwardingRuleUIModel newRule) {
    final rules = List<PortForwardingRuleUIModel>.from(
        state.settings.current.forwardingRules);
    final index = rules.indexOf(oldRule);
    if (index == -1) return;
    rules[index] = newRule;
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: rules,
          triggeringRules: state.settings.current.triggeringRules,
        ),
      ),
    );
  }

  void toggleForwardingRule(PortForwardingRuleUIModel rule, bool enabled) {
    editForwardingRule(rule, rule.copyWith(enabled: enabled));
  }

  void deleteForwardingRule(PortForwardingRuleUIModel rule) {
    final rules = List<PortForwardingRuleUIModel>.from(
        state.settings.current.forwardingRules);
    rules.remove(rule);
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: rules,
          triggeringRules: state.settings.current.triggeringRules,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Local Mutations — Port Triggering
  // ---------------------------------------------------------------------------

  void addTriggeringRule(PortTriggeringRuleUIModel rule) {
    final current = state.settings.current;
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: current.forwardingRules,
          triggeringRules: [...current.triggeringRules, rule],
        ),
      ),
    );
  }

  void editTriggeringRule(
      PortTriggeringRuleUIModel oldRule, PortTriggeringRuleUIModel newRule) {
    final rules = List<PortTriggeringRuleUIModel>.from(
        state.settings.current.triggeringRules);
    final index = rules.indexOf(oldRule);
    if (index == -1) return;
    rules[index] = newRule;
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: state.settings.current.forwardingRules,
          triggeringRules: rules,
        ),
      ),
    );
  }

  void toggleTriggeringRule(PortTriggeringRuleUIModel rule, bool enabled) {
    editTriggeringRule(rule, rule.copyWith(enabled: enabled));
  }

  // ---------------------------------------------------------------------------
  // Immediate mutations (Dashboard card — single operations)
  // ---------------------------------------------------------------------------

  /// Toggle a port forwarding rule immediately (writes to router).
  Future<void> immediateToggleForwarding(
      String instancePath, bool enabled) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.immediateToggleForwarding(instancePath, enabled);
      });
    } on ServiceError catch (e) {
      logger.e('[USP][PortFwd]: Immediate toggle forwarding failed', error: e);
      rethrow;
    }
    ref.invalidate(portForwardingDataProvider);
  }

  /// Add a port forwarding rule immediately (writes to router).
  Future<void> immediateAddForwarding({
    required int externalPort,
    required int internalPort,
    required String internalClient,
    required String protocol,
    String description = '',
    bool enabled = true,
    int externalPortEndRange = 0,
  }) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.immediateAddForwarding(
          externalPort: externalPort,
          internalPort: internalPort,
          internalClient: internalClient,
          protocol: protocol,
          description: description,
          enabled: enabled,
          externalPortEndRange: externalPortEndRange,
        );
      });
    } on ServiceError catch (e) {
      logger.e('[USP][PortFwd]: Immediate add forwarding failed', error: e);
      rethrow;
    }
    ref.invalidate(portForwardingDataProvider);
  }

  /// Toggle a port triggering rule immediately (writes to router).
  Future<void> immediateToggleTriggering(
      String instancePath, bool enabled) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.immediateToggleTriggering(instancePath, enabled);
      });
    } on ServiceError catch (e) {
      logger.e('[USP][PortFwd]: Immediate toggle triggering failed', error: e);
      rethrow;
    }
    ref.invalidate(portTriggeringDataProvider);
  }

  // ---------------------------------------------------------------------------
  // Local Mutations — Port Triggering (continued)
  // ---------------------------------------------------------------------------

  void deleteTriggeringRule(PortTriggeringRuleUIModel rule) {
    final rules = List<PortTriggeringRuleUIModel>.from(
        state.settings.current.triggeringRules);
    rules.remove(rule);
    state = state.copyWith(
      settings: state.settings.update(
        PortForwardingPageSettings(
          forwardingRules: state.settings.current.forwardingRules,
          triggeringRules: rules,
        ),
      ),
    );
  }
}
