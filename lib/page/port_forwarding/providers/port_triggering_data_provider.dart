import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/port_triggering.g.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';

/// Shared data provider for Port Triggering rules.
///
/// NOT autoDispose — persists across tab switches.
/// No SSE invalidation domain defined for port triggering.
final portTriggeringDataProvider =
    AsyncNotifierProvider<PortTriggeringDataNotifier, PortTriggeringData>(
  PortTriggeringDataNotifier.new,
);

class PortTriggeringData extends Equatable {
  final PortTriggering raw;
  final List<PortTriggeringRuleUIModel> ruleModels;

  const PortTriggeringData({
    required this.raw,
    required this.ruleModels,
  });

  @override
  List<Object?> get props => [raw.items.length, ruleModels.length];
}

class PortTriggeringDataNotifier extends AsyncNotifier<PortTriggeringData> {
  @override
  Future<PortTriggeringData> build() async {
    return _fetch();
  }

  Future<PortTriggeringData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    final raw = await PortTriggering.fetch(usp);
    final svc = ref.read(uspDeviceServiceProvider);
    return PortTriggeringData(
      raw: raw,
      ruleModels: svc.buildPortTriggeringRuleUIModels(raw),
    );
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> toggleRule(String instancePath, bool enabled) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortTriggering.update(
        usp,
        PortTriggerUpdate(instancePath: instancePath, enabled: enabled),
      );
      ref.invalidateSelf();
    });
  }

  Future<void> addRule({
    required int triggerPort,
    required String triggerProtocol,
    int triggerPortEndRange = 0,
    String description = '',
    bool enabled = true,
    int? forwardPort,
    int? forwardPortEndRange,
    String? forwardProtocol,
  }) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      final parentPath = await PortTriggering.add(
        usp,
        enabled: enabled,
        triggerPort: triggerPort,
        triggerPortEndRange: triggerPortEndRange,
        triggerProtocol: triggerProtocol,
        description: description,
      );
      if (forwardPort != null) {
        await PortTriggering.addPortTriggerForwardRule(
          usp,
          parentPath,
          forwardPort: forwardPort,
          forwardPortEndRange: forwardPortEndRange,
          forwardProtocol: forwardProtocol,
        );
      }
      ref.invalidateSelf();
    });
  }

  Future<void> updateRule({
    required String instancePath,
    bool? enabled,
    int? triggerPort,
    int? triggerPortEndRange,
    String? triggerProtocol,
    String? description,
  }) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortTriggering.update(
        usp,
        PortTriggerUpdate(
          instancePath: instancePath,
          enabled: enabled,
          triggerPort: triggerPort,
          triggerPortEndRange: triggerPortEndRange,
          triggerProtocol: triggerProtocol,
          description: description,
        ),
      );
      ref.invalidateSelf();
    });
  }

  Future<void> deleteRule(String instancePath) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortTriggering.delete(usp, instancePath);
      ref.invalidateSelf();
    });
  }

  Future<void> addForwardRule({
    required String parentInstancePath,
    required int forwardPort,
    int forwardPortEndRange = 0,
    String forwardProtocol = 'TCP',
  }) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortTriggering.addPortTriggerForwardRule(
        usp,
        parentInstancePath,
        forwardPort: forwardPort,
        forwardPortEndRange: forwardPortEndRange,
        forwardProtocol: forwardProtocol,
      );
      ref.invalidateSelf();
    });
  }

  Future<void> deleteForwardRule(String instancePath) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortTriggering.deletePortTriggerForwardRule(usp, instancePath);
      ref.invalidateSelf();
    });
  }

  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }
}
