import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

import '../mascot_config.dart';
import 'health_dimension.dart';
import 'health_dimension_registry.dart';
import 'health_score.dart';

/// Configuration for the health evaluation system.
class SystemHealthConfig {
  /// Interval between periodic evaluations.
  final Duration evaluationInterval;

  /// Debounce delay for SSE-triggered evaluations.
  final Duration debounceDelay;

  const SystemHealthConfig({
    this.evaluationInterval = kHealthEvaluationInterval,
    this.debounceDelay = kHealthDebounceDelay,
  });
}

/// Provider for system health configuration.
final systemHealthConfigProvider = Provider<SystemHealthConfig>((ref) {
  return const SystemHealthConfig();
});

/// Provider for health evaluation context.
///
/// Aggregates all L1 data providers into a single snapshot for dimension
/// evaluation and summary display. This eliminates duplication across
/// widgets and notifiers.
final healthEvaluationContextProvider =
    Provider<HealthEvaluationContext>((ref) {
  return HealthEvaluationContext(
    wan: ref.watch(wanDataProvider).valueOrNull,
    wifi: ref.watch(wifiDataProvider).valueOrNull,
    devices: ref.watch(devicesDataProvider).valueOrNull,
    firewall: ref.watch(firewallDataProvider).valueOrNull,
    systemInfo: ref.watch(systemInfoDataProvider).valueOrNull,
    firmware: ref.watch(firmwareBanksDataProvider).valueOrNull,
  );
});

/// Aggregated system health state provider.
///
/// Evaluates all registered health dimensions and provides:
/// 1. Initial evaluation when dashboard is ready
/// 2. Periodic re-evaluation (default: every 5 minutes)
/// 3. SSE-triggered re-evaluation (debounced)
final systemHealthProvider =
    AsyncNotifierProvider<SystemHealthNotifier, SystemHealthState>(
  SystemHealthNotifier.new,
);

class SystemHealthNotifier extends AsyncNotifier<SystemHealthState> {
  Timer? _periodicTimer;
  Timer? _debounceTimer;

  @override
  Future<SystemHealthState> build() async {
    final config = ref.watch(systemHealthConfigProvider);

    _listenToSseEvents();
    _startPeriodicEvaluation(config.evaluationInterval);

    ref.onDispose(() {
      _periodicTimer?.cancel();
      _debounceTimer?.cancel();
    });

    final isDashboardReady = ref.watch(dashboardDomainReadyProvider).hasValue;
    if (!isDashboardReady) {
      return const SystemHealthState.initial();
    }

    return _evaluate();
  }

  void _listenToSseEvents() {
    ref.listen(sseInvalidationProvider, (prev, next) {
      final domain = next.valueOrNull;
      if (domain != null && _shouldReEvaluate(domain)) {
        _debouncedReEvaluate();
      }
    });
  }

  bool _shouldReEvaluate(InvalidationDomain domain) {
    return HealthDimensions.allWatchedDomains.contains(domain);
  }

  void _debouncedReEvaluate() {
    final config = ref.read(systemHealthConfigProvider);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(config.debounceDelay, () {
      _reEvaluate();
    });
  }

  void _startPeriodicEvaluation(Duration interval) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      _reEvaluate();
    });
  }

  Future<void> _reEvaluate() async {
    if (!state.hasValue) return;

    final newState = await _evaluate();
    state = AsyncData(newState);
  }

  Future<SystemHealthState> _evaluate() async {
    final context = _buildContext();
    final now = DateTime.now();

    final scores = <HealthDimensionType, HealthScore>{};

    for (final dimension in HealthDimensions.all) {
      final score = dimension.evaluate(context);
      scores[dimension.type] = HealthScore(
        dimension: dimension.type,
        score: score,
        evaluatedAt: now,
      );
    }

    debugPrint('[Mascot][Health]: Evaluated ${scores.length} dimensions — '
        'overall=${_calculateOverall(scores)}');

    return SystemHealthState(
      scores: scores,
      lastEvaluated: now,
      isEvaluating: false,
    );
  }

  int _calculateOverall(Map<HealthDimensionType, HealthScore> scores) {
    if (scores.isEmpty) return 100;
    final total = scores.values.map((s) => s.score).reduce((a, b) => a + b);
    return total ~/ scores.length;
  }

  HealthEvaluationContext _buildContext() {
    return ref.read(healthEvaluationContextProvider);
  }

  /// Force immediate re-evaluation.
  Future<void> refresh() async {
    state = AsyncData(state.valueOrNull?.copyWith(isEvaluating: true) ??
        const SystemHealthState.initial());
    await _reEvaluate();
  }
}
