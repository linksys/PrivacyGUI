import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/port_forwarding_transforms.dart';

final uspPortForwardingServiceProvider = Provider<UspPortForwardingService>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    return UspPortForwardingService(usp);
  },
);

/// Service layer for Port Forwarding + Port Triggering — encapsulates codegen CRUD + transform.
class UspPortForwardingService {
  final UspClient _usp;

  UspPortForwardingService(this._usp);

  // ---------------------------------------------------------------------------
  // Fetch
  // ---------------------------------------------------------------------------

  /// Fetch port forwarding rules and transform to UI models.
  Future<List<PortForwardingRuleUIModel>> fetchForwardingRules() async {
    try {
      final raw = await PortForwarding.fetch(_usp);
      return transformForwardingRules(raw);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Fetch port triggering rules and transform to UI models.
  Future<List<PortTriggeringRuleUIModel>> fetchTriggeringRules() async {
    try {
      final raw = await PortTriggering.fetch(_usp);
      return transformTriggeringRules(raw);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Immediate mutations — Port Forwarding (Dashboard card)
  // ---------------------------------------------------------------------------

  /// Toggle a single port forwarding rule.
  Future<void> immediateToggleForwarding(
      String instancePath, bool enabled) async {
    try {
      final result = await PortForwarding.update(
        _usp,
        [
          PortForwardingRuleUpdate(instancePath: instancePath, enabled: enabled)
        ],
      );
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(failures: final f):
          throw UspPartialFailureError(
            summary:
                'Toggle forwarding partial failure: ${f.first.errorMessage}',
            successPaths: [],
            failures: f,
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'Toggle forwarding failed: ${e.first.errorMessage}',
            failures: e,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Add a single port forwarding rule immediately.
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
      final result = await PortForwarding.add(
        _usp,
        [
          {
            'Enable': enabled,
            'ExternalPort': externalPort,
            'ExternalPortEndRange': externalPortEndRange,
            'InternalPort': internalPort,
            'InternalClient': internalClient,
            'Protocol': protocol,
            'Description': description,
          }
        ],
      );
      final parsed = UspResultParser.parseAddResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(failures: final f):
          throw UspPartialFailureError(
            summary: 'Add forwarding partial failure: ${f.first.errorMessage}',
            successPaths: [],
            failures: f,
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'Add forwarding failed: ${e.first.errorMessage}',
            failures: e,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Immediate mutations — Port Triggering (Dashboard card)
  // ---------------------------------------------------------------------------

  /// Toggle a single port triggering rule.
  Future<void> immediateToggleTriggering(
      String instancePath, bool enabled) async {
    try {
      final result = await PortTriggering.update(
        _usp,
        [PortTriggerUpdate(instancePath: instancePath, enabled: enabled)],
      );
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(failures: final f):
          throw UspPartialFailureError(
            summary:
                'Toggle triggering partial failure: ${f.first.errorMessage}',
            successPaths: [],
            failures: f,
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'Toggle triggering failed: ${e.first.errorMessage}',
            failures: e,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Save — Port Forwarding (batch)
  // ---------------------------------------------------------------------------

  /// Batch save port forwarding rules: diff original vs current.
  ///
  /// Lenient mode: partial success is acceptable (log warning),
  /// only throws if ALL operations fail.
  /// FWDEV#204: a range forwards to the same ports on the LAN host, so its
  /// internal port is its start port, as on 1.x (#1080). A stored range may
  /// carry another value, and every Set sends the whole rule.
  static int _internalPortFor(PortForwardingRuleUIModel r) =>
      r.isPortRange ? r.externalPort : r.internalPort;

  Future<({int added, int updated, int deleted})> saveForwardingBatch({
    required List<PortForwardingRuleUIModel> original,
    required List<PortForwardingRuleUIModel> current,
  }) async {
    try {
      final tally = _BatchTally('[PortForwarding]');

      // 1. Delete (sequential, reverse order to avoid firmware renumbering)
      final currentPaths = <String>{
        for (final r in current)
          if (r.instancePath != null) r.instancePath!,
      };
      final toDelete = original
          .where((r) =>
              r.instancePath != null && !currentPaths.contains(r.instancePath))
          .toList();
      for (final r in toDelete.reversed) {
        final result = await PortForwarding.delete(_usp, [r.instancePath!]);
        tally.record('Delete', UspResultParser.parseDeleteResult(result));
      }

      // 2. Update (single batch call), before Add: a rule moved off a port
      // frees it, and an Add sent first would find the port still taken.
      // FW 2.0.3 stores such an Add with ExternalPort = 0 (FWDEV#204).
      final originalByPath = <String, PortForwardingRuleUIModel>{
        for (final r in original)
          if (r.instancePath != null) r.instancePath!: r,
      };
      final toUpdate = <PortForwardingRuleUpdate>[];
      for (final cur in current) {
        if (cur.instancePath == null) continue;
        final orig = originalByPath[cur.instancePath!];
        if (orig == null) continue;
        if (cur != orig) {
          toUpdate.add(PortForwardingRuleUpdate(
            instancePath: cur.instancePath!,
            enabled: cur.enabled,
            externalPort: cur.externalPort,
            externalPortEndRange: cur.externalPortEndRange,
            internalPort: _internalPortFor(cur),
            internalClient: cur.internalClient,
            protocol: cur.protocol,
            description: cur.description,
          ));
        }
      }
      if (toUpdate.isNotEmpty) {
        final result = await PortForwarding.update(_usp, toUpdate);
        tally.record('Update', UspResultParser.parseSetResult(result));
      }

      // 3. Add (single batch call)
      final toAdd = current.where((r) => r.instancePath == null).toList();
      if (toAdd.isNotEmpty) {
        final result = await PortForwarding.add(
          _usp,
          toAdd
              .map((r) => {
                    'Enable': r.enabled,
                    'ExternalPort': r.externalPort,
                    'ExternalPortEndRange': r.externalPortEndRange,
                    'InternalPort': _internalPortFor(r),
                    'InternalClient': r.internalClient,
                    'Protocol': r.protocol,
                    'Description': r.description,
                  })
              .toList(),
        );
        tally.record('Add', UspResultParser.parseAddResult(result));
      }

      tally.throwIfAnyFailed();

      return (
        added: toAdd.length,
        updated: toUpdate.length,
        deleted: toDelete.length,
      );
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Save — Port Triggering (batch)
  // ---------------------------------------------------------------------------

  /// Batch save port triggering rules: diff original vs current.
  ///
  /// Lenient mode: partial success is acceptable (log warning),
  /// only throws if ALL operations fail.
  Future<({int added, int updated, int deleted})> saveTriggeringBatch({
    required List<PortTriggeringRuleUIModel> original,
    required List<PortTriggeringRuleUIModel> current,
  }) async {
    try {
      final tally = _BatchTally('[PortTriggering]');

      // 1. Delete (sequential, reverse order to avoid firmware renumbering)
      final currentPaths = <String>{
        for (final r in current)
          if (r.instancePath != null) r.instancePath!,
      };
      final toDelete = original
          .where((r) =>
              r.instancePath != null && !currentPaths.contains(r.instancePath))
          .toList();
      for (final r in toDelete.reversed) {
        final result = await PortTriggering.delete(_usp, [r.instancePath!]);
        tally.record('Delete', UspResultParser.parseDeleteResult(result));
      }

      // 2. Update parent-level fields AND reconcile nested forward rules,
      // before Add, for the same reason as forwarding: a trigger moved off a
      // port frees it for a trigger Added in the same save (FWDEV#204).
      //
      // The parent Set (PortTrigger.{i}) only carries the trigger fields
      // (Enable/Description/Port/PortEndRange/Protocol). The forwarded ports
      // live in a separate sub-table (PortTrigger.{i}.Rule.{j}) and MUST be
      // reconciled with their own Add / Set / Delete calls — otherwise edits
      // to the forwarded ports are silently dropped (#1061).
      final originalByPath = <String, PortTriggeringRuleUIModel>{
        for (final r in original)
          if (r.instancePath != null) r.instancePath!: r,
      };
      final toUpdate = <PortTriggerUpdate>[];
      for (final cur in current) {
        if (cur.instancePath == null) continue;
        final orig = originalByPath[cur.instancePath!];
        if (orig == null) continue;
        if (cur == orig) continue;

        // 2a. Parent-level trigger fields.
        if (cur.enabled != orig.enabled ||
            cur.description != orig.description ||
            cur.triggerPort != orig.triggerPort ||
            cur.triggerPortEndRange != orig.triggerPortEndRange ||
            cur.triggerProtocol != orig.triggerProtocol) {
          toUpdate.add(PortTriggerUpdate(
            instancePath: cur.instancePath!,
            enabled: cur.enabled,
            description: cur.description,
            triggerPort: cur.triggerPort,
            triggerPortEndRange: cur.triggerPortEndRange,
            triggerProtocol: cur.triggerProtocol,
          ));
        }

        // 2b. Nested forwarded-port rules.
        if (cur.forwardRules != orig.forwardRules) {
          await _reconcileForwardRules(
            tally,
            parentPath: cur.instancePath!,
            original: orig.forwardRules,
            current: cur.forwardRules,
          );
        }
      }
      if (toUpdate.isNotEmpty) {
        final result = await PortTriggering.update(_usp, toUpdate);
        tally.record('Update', UspResultParser.parseSetResult(result));
      }

      // 3. Add (parent + forward rules)
      final toAdd = current.where((r) => r.instancePath == null).toList();
      for (final r in toAdd) {
        final result = await PortTriggering.add(
          _usp,
          [
            {
              'Enable': r.enabled,
              'Description': r.description,
              'Port': r.triggerPort,
              'PortEndRange': r.triggerPortEndRange,
              'Protocol': r.triggerProtocol,
            }
          ],
        );

        // Extract instance path from structured response
        final parsedResult = UspResultParser.parseAddResult(result);
        tally.record('Add parent', parsedResult);
        String? parentPath;
        switch (parsedResult) {
          case UspSuccess():
            final createdInstances = parsedResult.allCreatedInstances;
            if (createdInstances.isNotEmpty) {
              parentPath = createdInstances.first.affectedPath;
            }
          case UspPartialSuccess():
            final createdInstances = parsedResult.successes
                .expand((s) => s.createdInstances ?? <UspCreatedInstance>[])
                .toList();
            if (createdInstances.isNotEmpty) {
              parentPath = createdInstances.first.affectedPath;
            }
          case UspFailure():
            break;
        }

        // Add forward rules only if parent was created. A parent Add that
        // succeeded without naming its instance leaves them unwritable, which
        // is a failed save, not a skipped step.
        if (parentPath == null && parsedResult is! UspFailure) {
          tally.recordMissing('Add parent',
              'no instance path returned for trigger ${r.triggerPortDisplay}');
        }
        if (parentPath != null) {
          for (final fr in r.forwardRules) {
            final fwd = await PortTriggering.addPortTriggerForwardRule(
              _usp,
              parentPath,
              forwardPort: fr.forwardPort,
              forwardPortEndRange: fr.forwardPortEndRange,
              forwardProtocol: fr.forwardProtocol,
            );
            tally.record('Add forward', UspResultParser.parseAddResult(fwd));
          }
        }
      }

      tally.throwIfAnyFailed();

      return (
        added: toAdd.length,
        updated: toUpdate.length,
        deleted: toDelete.length,
      );
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Reconcile the nested forwarded-port sub-rules of a single existing
  /// port trigger (parent already persisted at [parentPath]).
  ///
  /// Diffs [original] vs [current] forward rules and issues the minimal set of
  /// Add / Set / Delete calls against the `Rule.{j}` sub-table. Existing rules
  /// (non-null instancePath) whose values changed are updated in place via
  /// [UspClient.set]; rules that vanished are deleted; brand-new rules
  /// (null instancePath) are added. Every result goes into [tally], so a
  /// refused forward rule fails the whole save.
  Future<void> _reconcileForwardRules(
    _BatchTally tally, {
    required String parentPath,
    required List<PortTriggerForwardRuleUIModel> original,
    required List<PortTriggerForwardRuleUIModel> current,
  }) async {
    // 1. Delete forward rules that no longer exist in current.
    final currentPaths = <String>{
      for (final r in current)
        if (r.instancePath != null) r.instancePath!,
    };
    final toDelete = original
        .where((r) =>
            r.instancePath != null && !currentPaths.contains(r.instancePath))
        .toList();
    for (final r in toDelete.reversed) {
      final result = await PortTriggering.deletePortTriggerForwardRule(
          _usp, r.instancePath!);
      tally.record('Delete forward', UspResultParser.parseDeleteResult(result));
    }

    // 2. Update existing forward rules whose values changed (in-place Set).
    final originalByPath = <String, PortTriggerForwardRuleUIModel>{
      for (final r in original)
        if (r.instancePath != null) r.instancePath!: r,
    };
    final updateParams = <String, dynamic>{};
    for (final cur in current) {
      if (cur.instancePath == null) continue;
      final orig = originalByPath[cur.instancePath!];
      if (orig == null) continue;
      if (cur == orig) continue;
      updateParams['${cur.instancePath}Port'] = cur.forwardPort;
      updateParams['${cur.instancePath}PortEndRange'] = cur.forwardPortEndRange;
      updateParams['${cur.instancePath}Protocol'] = cur.forwardProtocol;
    }
    if (updateParams.isNotEmpty) {
      final result = await _usp.set(updateParams);
      tally.record('Update forward', UspResultParser.parseSetResult(result));
    }

    // 3. Add brand-new forward rules (null instancePath).
    final toAdd = current.where((r) => r.instancePath == null).toList();
    for (final fr in toAdd) {
      final result = await PortTriggering.addPortTriggerForwardRule(
        _usp,
        parentPath,
        forwardPort: fr.forwardPort,
        forwardPortEndRange: fr.forwardPortEndRange,
        forwardProtocol: fr.forwardProtocol,
      );
      tally.record('Add forward', UspResultParser.parseAddResult(result));
    }
  }
}

/// The outcome of every step in one batch save.
///
/// Any step that failed, partly or fully, fails the save: the batch used to
/// throw only when *every* step failed, so a save that left a rule behind on
/// the router still reported "saved". The router's own error for the first
/// failure is what the user is shown.
class _BatchTally {
  /// [_tag] is the grep-friendly log prefix, `[PortForwarding]` or
  /// `[PortTriggering]`.
  _BatchTally(this._tag);

  final String _tag;
  final List<UspErrorDetail> _failures = [];
  int _steps = 0;
  int _failedSteps = 0;

  void record(String step, UspOperationResult<dynamic> result) {
    _steps++;
    final List<UspErrorDetail> failures;
    switch (result) {
      case UspSuccess():
        return;
      case UspPartialSuccess(failures: final f):
        failures = f;
      case UspFailure(errors: final e):
        _failedSteps++;
        failures = e;
    }
    _failures.addAll(failures);
    logger.w('$_tag: $step failed: '
        '${failures.map((f) => f.errorMessage).join('; ')}');
  }

  /// A step whose result said success but left the save unable to go on.
  void recordMissing(String step, String why) {
    _steps++;
    _failedSteps++;
    _failures.add(UspErrorDetail(
      requestedPath: '',
      errorCode: 0,
      errorMessage: why,
    ));
    logger.w('$_tag: $step failed: $why');
  }

  void throwIfAnyFailed() {
    if (_failures.isEmpty) return;
    final summary = '$_tag batch: ${_failures.first.errorMessage}';
    if (_failedSteps == _steps) {
      throw UspCompleteFailureError(summary: summary, failures: _failures);
    }
    throw UspPartialFailureError(
      summary: summary,
      successPaths: const [],
      failures: _failures,
    );
  }
}
