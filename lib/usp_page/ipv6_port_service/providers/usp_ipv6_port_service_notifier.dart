import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/ipv6port_service.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp_page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/usp_page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class UspIpv6PortServiceState extends Equatable {
  final List<Ipv6PortServiceRuleUIModel> rules;
  final bool isMutating;

  const UspIpv6PortServiceState({
    required this.rules,
    this.isMutating = false,
  });

  UspIpv6PortServiceState copyWith({
    List<Ipv6PortServiceRuleUIModel>? rules,
    bool? isMutating,
  }) {
    return UspIpv6PortServiceState(
      rules: rules ?? this.rules,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [rules, isMutating];
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final uspIpv6PortServiceProvider = AsyncNotifierProvider.autoDispose<
    UspIpv6PortServiceNotifier, UspIpv6PortServiceState>(
  UspIpv6PortServiceNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspIpv6PortServiceNotifier
    extends AutoDisposeAsyncNotifier<UspIpv6PortServiceState> {
  @override
  Future<UspIpv6PortServiceState> build() async {
    final usp = ref.watch(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');

    final data = await Ipv6PortService.fetch(usp);
    final svc = ref.read(uspIpv6PortServiceServiceProvider);
    final rules = svc.buildRuleUIModels(data);

    logger.d('[USP][Firewall][IPv6Port]Ipv6PortService fetched — '
        'total: ${data.items.length}, ipv6: ${rules.length}');

    return UspIpv6PortServiceState(rules: rules);
  }

  Future<void> _refreshRules() async {
    final usp = ref.read(uspServiceProvider)!;
    final data = await Ipv6PortService.fetch(usp);
    final svc = ref.read(uspIpv6PortServiceServiceProvider);
    final rules = svc.buildRuleUIModels(data);
    state = AsyncData(UspIpv6PortServiceState(rules: rules));
  }

  /// Add a new IPv6 port service rule.
  Future<void> addRule({
    required String description,
    required String ipv6Address,
    required int protocol,
    required int startPort,
    required int endPort,
    bool enabled = true,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(isMutating: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      await Ipv6PortService.add(
        usp,
        enable: enabled,
        description: description,
        ipVersion: 6,
        destIp: ipv6Address,
        destPort: startPort,
        destPortRangeMax: endPort,
        protocol: protocol,
        target: 'Accept',
      );
      logger.d(
          '[USP][Firewall][IPv6Port]Ipv6PortServiceRule added — $description');
      await _refreshRules();
    } catch (e) {
      state = AsyncData(s.copyWith(isMutating: false));
      rethrow;
    }
  }

  /// Update an existing rule.
  Future<void> updateRule({
    required String instancePath,
    required String description,
    required String ipv6Address,
    required int protocol,
    required int startPort,
    required int endPort,
    bool? enabled,
  }) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(isMutating: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      await Ipv6PortService.update(
        usp,
        Ipv6PortServiceRuleUpdate(
          instancePath: instancePath,
          enable: enabled,
          description: description,
          destIp: ipv6Address,
          destPort: startPort,
          destPortRangeMax: endPort,
          protocol: protocol,
          target: 'Accept',
        ),
      );
      logger.d(
          '[USP][Firewall][IPv6Port]Ipv6PortServiceRule updated — $instancePath');
      await _refreshRules();
    } catch (e) {
      state = AsyncData(s.copyWith(isMutating: false));
      rethrow;
    }
  }

  /// Toggle enable/disable on a single rule.
  Future<void> toggleRule(String instancePath, bool enabled) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(isMutating: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      await Ipv6PortService.update(
        usp,
        Ipv6PortServiceRuleUpdate(instancePath: instancePath, enable: enabled),
      );
      logger.d(
          '[USP][Firewall][IPv6Port]Ipv6PortServiceRule toggled — $instancePath → $enabled');
      await _refreshRules();
    } catch (e) {
      state = AsyncData(s.copyWith(isMutating: false));
      rethrow;
    }
  }

  /// Delete a rule.
  Future<void> deleteRule(String instancePath) async {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(s.copyWith(isMutating: true));
    try {
      final usp = ref.read(uspServiceProvider)!;
      await Ipv6PortService.delete(usp, instancePath);
      logger.d(
          '[USP][Firewall][IPv6Port]Ipv6PortServiceRule deleted — $instancePath');
      await _refreshRules();
    } catch (e) {
      state = AsyncData(s.copyWith(isMutating: false));
      rethrow;
    }
  }
}
