import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/generated/port_forwarding.g.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/_shared/services/usp_device_service.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';

/// Shared data provider for Port Forwarding rules.
///
/// NOT autoDispose — persists across tab switches.
/// SSE: listens for [InvalidationDomain.portForwarding].
final portForwardingDataProvider =
    AsyncNotifierProvider<PortForwardingDataNotifier, PortForwardingData>(
  PortForwardingDataNotifier.new,
);

class PortForwardingData extends Equatable {
  final PortForwarding raw;
  final List<PortForwardingRuleUIModel> ruleModels;

  const PortForwardingData({
    required this.raw,
    required this.ruleModels,
  });

  @override
  List<Object?> get props => [raw.items.length, ruleModels.length];
}

class PortForwardingDataNotifier extends AsyncNotifier<PortForwardingData> {
  Timer? _debounce;

  @override
  Future<PortForwardingData> build() async {
    // SSE invalidation
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain == InvalidationDomain.portForwarding) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          ref.invalidateSelf();
        });
      }
    });
    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<PortForwardingData> _fetch() async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    final raw = await PortForwarding.fetch(usp);
    final svc = ref.read(uspDeviceServiceProvider);
    return PortForwardingData(
      raw: raw,
      ruleModels: svc.buildPortForwardingRuleUIModels(raw),
    );
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> toggleRule(String instancePath, bool enabled) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortForwarding.update(
        usp,
        PortForwardingRuleUpdate(instancePath: instancePath, enabled: enabled),
      );
      ref.invalidateSelf();
    });
  }

  Future<void> addRule({
    required int externalPort,
    required int internalPort,
    required String internalClient,
    required String protocol,
    String description = '',
    bool enabled = true,
    int externalPortEndRange = 0,
  }) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortForwarding.add(
        usp,
        enabled: enabled,
        externalPort: externalPort,
        externalPortEndRange: externalPortEndRange,
        internalPort: internalPort,
        internalClient: internalClient,
        protocol: protocol,
        description: description,
      );
      ref.invalidateSelf();
    });
  }

  Future<void> updateRule({
    required String instancePath,
    bool? enabled,
    int? externalPort,
    int? externalPortEndRange,
    int? internalPort,
    String? internalClient,
    String? protocol,
    String? description,
  }) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortForwarding.update(
        usp,
        PortForwardingRuleUpdate(
          instancePath: instancePath,
          enabled: enabled,
          externalPort: externalPort,
          externalPortEndRange: externalPortEndRange,
          internalPort: internalPort,
          internalClient: internalClient,
          protocol: protocol,
          description: description,
        ),
      );
      ref.invalidateSelf();
    });
  }

  Future<void> deleteRule(String instancePath) async {
    await ref.read(uspMutationLockProvider).withLock(() async {
      final usp = _usp;
      await PortForwarding.delete(usp, instancePath);
      ref.invalidateSelf();
    });
  }

  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }
}
