import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_contract.dart';
import 'package:privacy_gui/usp_page/_framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/usp_page/dashboard/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/dashboard/services/usp_device_service.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_forwarding_page_feature_state.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_forwarding_page_settings.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_forwarding_page_status.dart';
import 'package:privacy_gui/usp_page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/usp_page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/usp_page/port_forwarding/providers/port_triggering_data_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspPortForwardingPageProvider = AutoDisposeNotifierProvider<
    UspPortForwardingPageNotifier, PortForwardingPageFeatureState>(
  UspPortForwardingPageNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspPortForwardingPageProvider = AutoDisposeProvider<
    PreservableContract<PortForwardingPageSettings,
        PortForwardingPageStatus>>(
  (ref) => ref.watch(uspPortForwardingPageProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspPortForwardingPageNotifier
    extends AutoDisposeNotifier<PortForwardingPageFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<PortForwardingPageSettings,
            PortForwardingPageStatus, PortForwardingPageFeatureState> {
  @override
  PortForwardingPageFeatureState build() {
    // SSE invalidation: re-fetch when port forwarding changes externally.
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.valueOrNull == InvalidationDomain.portForwarding) {
        onSseInvalidation();
      }
    });

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
      final usp = ref.read(uspServiceProvider)!;
      final svc = ref.read(uspDeviceServiceProvider);

      final results = await Future.wait([
        PortForwarding.fetch(usp),
        PortTriggering.fetch(usp),
      ]);

      final pfRaw = results[0] as PortForwarding;
      final ptRaw = results[1] as PortTriggering;

      final forwardingRules = svc.buildPortForwardingRuleUIModels(pfRaw);
      final triggeringRules = svc.buildPortTriggeringRuleUIModels(ptRaw);

      logger.d('[USP][Firewall][PortForwarding] Fetched — '
          'forwarding: ${forwardingRules.length}, '
          'triggering: ${triggeringRules.length}');

      return (
        PortForwardingPageSettings(
          forwardingRules: forwardingRules,
          triggeringRules: triggeringRules,
        ),
        const PortForwardingPageStatus(),
      );
    } catch (e) {
      logger.e('[USP][Firewall][PortForwarding] Fetch failed', error: e);
      return (
        null,
        PortForwardingPageStatus(errorMessage: '$e'),
      );
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
      final usp = ref.read(uspServiceProvider)!;
      final originalPf = state.settings.original.forwardingRules;
      final currentPf = state.settings.current.forwardingRules;
      final originalPt = state.settings.original.triggeringRules;
      final currentPt = state.settings.current.triggeringRules;

      await ref.read(uspMutationLockProvider).withLock(() async {
        // ====== Port Forwarding ======

        // 1. Delete (sequential with delay)
        final currentPfPaths = <String>{
          for (final r in currentPf)
            if (r.instancePath != null) r.instancePath!,
        };
        final pfToDelete = originalPf
            .where((r) =>
                r.instancePath != null &&
                !currentPfPaths.contains(r.instancePath))
            .toList();
        for (var i = 0; i < pfToDelete.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          await PortForwarding.delete(usp, pfToDelete[i].instancePath!);
        }

        // 2. Add (sequential with delay to avoid bridge 504)
        final pfToAdd =
            currentPf.where((r) => r.instancePath == null).toList();
        for (var i = 0; i < pfToAdd.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          final r = pfToAdd[i];
          await PortForwarding.add(
            usp,
            enabled: r.enabled,
            externalPort: r.externalPort,
            externalPortEndRange: r.externalPortEndRange,
            internalPort: r.internalPort,
            internalClient: r.internalClient,
            protocol: r.protocol,
            description: r.description,
          );
        }

        // 3. Update
        final originalPfByPath = <String, PortForwardingRuleUIModel>{
          for (final r in originalPf)
            if (r.instancePath != null) r.instancePath!: r,
        };
        final pfToUpdate = <PortForwardingRuleUpdate>[];
        for (final cur in currentPf) {
          if (cur.instancePath == null) continue;
          final orig = originalPfByPath[cur.instancePath!];
          if (orig == null) continue;
          if (cur != orig) {
            pfToUpdate.add(PortForwardingRuleUpdate(
              instancePath: cur.instancePath!,
              enabled: cur.enabled,
              externalPort: cur.externalPort,
              externalPortEndRange: cur.externalPortEndRange,
              internalPort: cur.internalPort,
              internalClient: cur.internalClient,
              protocol: cur.protocol,
              description: cur.description,
            ));
          }
        }
        if (pfToUpdate.isNotEmpty) {
          await PortForwarding.updateMany(usp, pfToUpdate);
        }

        // ====== Port Triggering ======

        // 1. Delete (sequential with delay)
        final currentPtPaths = <String>{
          for (final r in currentPt)
            if (r.instancePath != null) r.instancePath!,
        };
        final ptToDelete = originalPt
            .where((r) =>
                r.instancePath != null &&
                !currentPtPaths.contains(r.instancePath))
            .toList();
        for (var i = 0; i < ptToDelete.length; i++) {
          if (i > 0) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          await PortTriggering.delete(usp, ptToDelete[i].instancePath!);
        }

        // 2. Add (parent + forward rules)
        final ptToAdd =
            currentPt.where((r) => r.instancePath == null).toList();
        for (final r in ptToAdd) {
          final parentPath = await PortTriggering.add(
            usp,
            enabled: r.enabled,
            description: r.description,
            triggerPort: r.triggerPort,
            triggerPortEndRange: r.triggerPortEndRange,
            triggerProtocol: r.triggerProtocol,
          );
          for (final fr in r.forwardRules) {
            await PortTriggering.addPortTriggerForwardRule(
              usp,
              parentPath,
              forwardPort: fr.forwardPort,
              forwardPortEndRange: fr.forwardPortEndRange,
              forwardProtocol: fr.forwardProtocol,
            );
          }
        }

        // 3. Update (parent-level only)
        final originalPtByPath = <String, PortTriggeringRuleUIModel>{
          for (final r in originalPt)
            if (r.instancePath != null) r.instancePath!: r,
        };
        final ptToUpdate = <PortTriggerUpdate>[];
        for (final cur in currentPt) {
          if (cur.instancePath == null) continue;
          final orig = originalPtByPath[cur.instancePath!];
          if (orig == null) continue;
          if (cur != orig) {
            ptToUpdate.add(PortTriggerUpdate(
              instancePath: cur.instancePath!,
              enabled: cur.enabled,
              description: cur.description,
              triggerPort: cur.triggerPort,
              triggerPortEndRange: cur.triggerPortEndRange,
              triggerProtocol: cur.triggerProtocol,
            ));
          }
        }
        if (ptToUpdate.isNotEmpty) {
          await PortTriggering.updateMany(usp, ptToUpdate);
        }

        logger.d('[USP][Firewall][PortForwarding] Batch save — '
            'PF added: ${pfToAdd.length}, updated: ${pfToUpdate.length}, '
            'deleted: ${pfToDelete.length} | '
            'PT added: ${ptToAdd.length}, updated: ${ptToUpdate.length}, '
            'deleted: ${ptToDelete.length}');
      });

      // Invalidate Layer 1 providers to refresh dashboard card
      ref.invalidate(portForwardingDataProvider);
      ref.invalidate(portTriggeringDataProvider);
    } catch (e) {
      logger.e('[USP][Firewall][PortForwarding] Save failed', error: e);
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
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
