import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_data_service.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_triggering_data_service.dart';

final uspPortForwardingServiceProvider = Provider<UspPortForwardingService>(
  (ref) {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      throw const ServiceNotInitializedError(
          message: 'USP service not available');
    }
    return UspPortForwardingService(
      usp,
      ref.read(uspPortForwardingDataServiceProvider),
      ref.read(uspPortTriggeringDataServiceProvider),
    );
  },
);

/// Service layer for Port Forwarding + Port Triggering — encapsulates codegen CRUD + transform.
class UspPortForwardingService {
  final UspService _usp;
  final UspPortForwardingDataService _fwdDataSvc;
  final UspPortTriggeringDataService _trgDataSvc;

  UspPortForwardingService(this._usp, this._fwdDataSvc, this._trgDataSvc);

  // ---------------------------------------------------------------------------
  // Fetch (reuse L1 Service transform)
  // ---------------------------------------------------------------------------

  /// Fetch port forwarding rules and transform to UI models.
  Future<List<PortForwardingRuleUIModel>> fetchForwardingRules() async {
    try {
      final raw = await PortForwarding.fetch(_usp);
      return _fwdDataSvc.buildUIModels(raw);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Fetch port triggering rules and transform to UI models.
  Future<List<PortTriggeringRuleUIModel>> fetchTriggeringRules() async {
    try {
      final raw = await PortTriggering.fetch(_usp);
      return _trgDataSvc.buildUIModels(raw);
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
      await PortForwarding.update(
        _usp,
        PortForwardingRuleUpdate(instancePath: instancePath, enabled: enabled),
      );
    } catch (e) {
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
      await PortForwarding.add(
        _usp,
        enabled: enabled,
        externalPort: externalPort,
        externalPortEndRange: externalPortEndRange,
        internalPort: internalPort,
        internalClient: internalClient,
        protocol: protocol,
        description: description,
      );
    } catch (e) {
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
      await PortTriggering.update(
        _usp,
        PortTriggerUpdate(instancePath: instancePath, enabled: enabled),
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Save — Port Forwarding (batch)
  // ---------------------------------------------------------------------------

  /// Batch save port forwarding rules: diff original vs current.
  Future<({int added, int updated, int deleted})> saveForwardingBatch({
    required List<PortForwardingRuleUIModel> original,
    required List<PortForwardingRuleUIModel> current,
  }) async {
    try {
      // 1. Delete
      final currentPaths = <String>{
        for (final r in current)
          if (r.instancePath != null) r.instancePath!,
      };
      final toDelete = original
          .where((r) =>
              r.instancePath != null && !currentPaths.contains(r.instancePath))
          .toList();
      for (var i = 0; i < toDelete.length; i++) {
        if (i > 0) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        await PortForwarding.delete(_usp, toDelete[i].instancePath!);
      }

      // 2. Add
      final toAdd = current.where((r) => r.instancePath == null).toList();
      for (var i = 0; i < toAdd.length; i++) {
        if (i > 0) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        final r = toAdd[i];
        await PortForwarding.add(
          _usp,
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
        await PortForwarding.updateMany(_usp, toUpdate);
      }

      return (
        added: toAdd.length,
        updated: toUpdate.length,
        deleted: toDelete.length,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Save — Port Triggering (batch)
  // ---------------------------------------------------------------------------

  /// Batch save port triggering rules: diff original vs current.
  Future<({int added, int updated, int deleted})> saveTriggeringBatch({
    required List<PortTriggeringRuleUIModel> original,
    required List<PortTriggeringRuleUIModel> current,
  }) async {
    try {
      // 1. Delete
      final currentPaths = <String>{
        for (final r in current)
          if (r.instancePath != null) r.instancePath!,
      };
      final toDelete = original
          .where((r) =>
              r.instancePath != null && !currentPaths.contains(r.instancePath))
          .toList();
      for (var i = 0; i < toDelete.length; i++) {
        if (i > 0) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        await PortTriggering.delete(_usp, toDelete[i].instancePath!);
      }

      // 2. Add (parent + forward rules)
      final toAdd = current.where((r) => r.instancePath == null).toList();
      for (final r in toAdd) {
        final parentPath = await PortTriggering.add(
          _usp,
          enabled: r.enabled,
          description: r.description,
          triggerPort: r.triggerPort,
          triggerPortEndRange: r.triggerPortEndRange,
          triggerProtocol: r.triggerProtocol,
        );
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
        await PortTriggering.updateMany(_usp, toUpdate);
      }

      return (
        added: toAdd.length,
        updated: toUpdate.length,
        deleted: toDelete.length,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }
}
