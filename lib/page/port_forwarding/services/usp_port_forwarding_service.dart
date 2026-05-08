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
          message: 'USP service not available');
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
            failedPaths: f.map((e) => e.requestedPath).toList(),
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'Toggle forwarding failed: ${e.first.errorMessage}',
            failedPaths: e.map((e) => e.requestedPath).toList(),
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
            failedPaths: f.map((e) => e.requestedPath).toList(),
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'Add forwarding failed: ${e.first.errorMessage}',
            failedPaths: e.map((e) => e.requestedPath).toList(),
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
            failedPaths: f.map((e) => e.requestedPath).toList(),
          );
        case UspFailure(errors: final e):
          throw UspCompleteFailureError(
            summary: 'Toggle triggering failed: ${e.first.errorMessage}',
            failedPaths: e.map((e) => e.requestedPath).toList(),
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
  Future<({int added, int updated, int deleted})> saveForwardingBatch({
    required List<PortForwardingRuleUIModel> original,
    required List<PortForwardingRuleUIModel> current,
  }) async {
    try {
      int totalOps = 0;
      int failedOps = 0;

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
        totalOps++;
        final result = await PortForwarding.delete(_usp, [r.instancePath!]);
        final parsed = UspResultParser.parseDeleteResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(failures: final f):
            logger
                .w('[PortForwarding] Delete partial: ${f.first.errorMessage}');
          case UspFailure(errors: final e):
            failedOps++;
            logger
                .w('[PortForwarding]: Delete failed: ${e.first.errorMessage}');
        }
      }

      // 2. Add (single batch call)
      final toAdd = current.where((r) => r.instancePath == null).toList();
      if (toAdd.isNotEmpty) {
        totalOps++;
        final result = await PortForwarding.add(
          _usp,
          toAdd
              .map((r) => {
                    'Enable': r.enabled,
                    'ExternalPort': r.externalPort,
                    'ExternalPortEndRange': r.externalPortEndRange,
                    'InternalPort': r.internalPort,
                    'InternalClient': r.internalClient,
                    'Protocol': r.protocol,
                    'Description': r.description,
                  })
              .toList(),
        );
        final parsed = UspResultParser.parseAddResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(failures: final f):
            logger.w('[PortForwarding]: Add partial: ${f.first.errorMessage}');
          case UspFailure(errors: final e):
            failedOps++;
            logger.w('[PortForwarding]: Add failed: ${e.first.errorMessage}');
        }
      }

      // 3. Update (single batch call)
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
            internalPort: cur.internalPort,
            internalClient: cur.internalClient,
            protocol: cur.protocol,
            description: cur.description,
          ));
        }
      }
      if (toUpdate.isNotEmpty) {
        totalOps++;
        final result = await PortForwarding.update(_usp, toUpdate);
        final parsed = UspResultParser.parseSetResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(failures: final f):
            logger
                .w('[PortForwarding] Update partial: ${f.first.errorMessage}');
          case UspFailure(errors: final e):
            failedOps++;
            logger
                .w('[PortForwarding]: Update failed: ${e.first.errorMessage}');
        }
      }

      // All operations failed → throw
      if (totalOps > 0 && failedOps == totalOps) {
        throw UspCompleteFailureError(
          summary: 'All forwarding batch operations failed',
          failedPaths: [],
        );
      }

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
      int totalOps = 0;
      int failedOps = 0;

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
        totalOps++;
        final result = await PortTriggering.delete(_usp, [r.instancePath!]);
        final parsed = UspResultParser.parseDeleteResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(failures: final f):
            logger
                .w('[PortTriggering]: Delete partial: ${f.first.errorMessage}');
          case UspFailure(errors: final e):
            failedOps++;
            logger
                .w('[PortTriggering]: Delete failed: ${e.first.errorMessage}');
        }
      }

      // 2. Add (parent + forward rules)
      final toAdd = current.where((r) => r.instancePath == null).toList();
      for (final r in toAdd) {
        totalOps++;
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
        String? parentPath;
        switch (parsedResult) {
          case UspSuccess():
            final createdInstances = parsedResult.allCreatedInstances;
            if (createdInstances.isNotEmpty) {
              parentPath = createdInstances.first.affectedPath;
            }
          case UspPartialSuccess(failures: final f):
            logger.w(
                '[PortTriggering]: Add parent partial: ${f.first.errorMessage}');
            final createdInstances = parsedResult.successes
                .expand((s) => s.createdInstances ?? <UspCreatedInstance>[])
                .toList();
            if (createdInstances.isNotEmpty) {
              parentPath = createdInstances.first.affectedPath;
            }
          case UspFailure(errors: final e):
            failedOps++;
            logger.w(
                '[PortTriggering]: Add parent failed: ${e.first.errorMessage}');
        }

        // Add forward rules only if parent was created
        if (parentPath != null) {
          for (final fr in r.forwardRules) {
            await PortTriggering.addPortTriggerForwardRule(
              _usp,
              parentPath,
              forwardPort: fr.forwardPort,
              forwardPortEndRange: fr.forwardPortEndRange,
              forwardProtocol: fr.forwardProtocol,
            );
          }
        }
      }

      // 3. Update (parent-level only)
      final originalByPath = <String, PortTriggeringRuleUIModel>{
        for (final r in original)
          if (r.instancePath != null) r.instancePath!: r,
      };
      final toUpdate = <PortTriggerUpdate>[];
      for (final cur in current) {
        if (cur.instancePath == null) continue;
        final orig = originalByPath[cur.instancePath!];
        if (orig == null) continue;
        if (cur != orig) {
          toUpdate.add(PortTriggerUpdate(
            instancePath: cur.instancePath!,
            enabled: cur.enabled,
            description: cur.description,
            triggerPort: cur.triggerPort,
            triggerPortEndRange: cur.triggerPortEndRange,
            triggerProtocol: cur.triggerProtocol,
          ));
        }
      }
      if (toUpdate.isNotEmpty) {
        totalOps++;
        final result = await PortTriggering.update(_usp, toUpdate);
        final parsed = UspResultParser.parseSetResult(result);
        switch (parsed) {
          case UspSuccess():
            break;
          case UspPartialSuccess(failures: final f):
            logger
                .w('[PortTriggering]: Update partial: ${f.first.errorMessage}');
          case UspFailure(errors: final e):
            failedOps++;
            logger
                .w('[PortTriggering]: Update failed: ${e.first.errorMessage}');
        }
      }

      // All operations failed → throw
      if (totalOps > 0 && failedOps == totalOps) {
        throw UspCompleteFailureError(
          summary: 'All triggering batch operations failed',
          failedPaths: [],
        );
      }

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
}
