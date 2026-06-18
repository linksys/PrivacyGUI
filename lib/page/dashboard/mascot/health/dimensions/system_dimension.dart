import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/route/constants.dart';

import '../../mascot_config.dart';
import '../health_dimension.dart';

/// Health dimension for system resources (CPU, Memory).
///
/// Evaluates:
/// - CPU usage percentage
/// - Memory usage percentage
///
/// Score mapping (uses the worse of CPU/Memory):
/// - 100: Both < 50%
/// - 80: Both < 70%
/// - 60: Both < 85%
/// - 40: Either >= 85%
/// - 20: Either >= 95%
class SystemHealthDimension extends HealthDimension {
  @override
  HealthDimensionType get type => HealthDimensionType.system;

  @override
  String get displayName => 'System';

  @override
  IconData get icon => Icons.memory;

  @override
  Set<InvalidationDomain> get watchedDomains => const {};

  @override
  int evaluate(HealthEvaluationContext context) {
    final info = context.systemInfo;
    if (info == null) return 100;

    final cpu = info.model.cpuPercent;
    final memory = info.model.memoryPercent;
    final maxUsage = cpu > memory ? cpu : memory;

    if (maxUsage < SystemThresholds.excellent) return 100;
    if (maxUsage < SystemThresholds.good) return 80;
    if (maxUsage < SystemThresholds.fair) return 60;
    if (maxUsage < SystemThresholds.poor) return 40;
    return 20;
  }

  @override
  DimensionSummary getSummary(HealthEvaluationContext context) {
    final info = context.systemInfo;
    if (info == null) {
      return const DimensionSummary(
        status: 'Loading...',
        hint: 'Tap for actions',
      );
    }

    final model = info.model;
    final cpu = model.cpuPercent;
    final memory = model.memoryPercent;
    final maxUsage = cpu > memory ? cpu : memory;

    String status;
    if (maxUsage < SystemThresholds.excellent) {
      status = 'Healthy';
    } else if (maxUsage < SystemThresholds.good) {
      status = 'Normal';
    } else if (maxUsage < SystemThresholds.fair) {
      status = 'Moderate Load';
    } else {
      status = 'High Load';
    }

    final items = <SummaryItem>[
      SummaryItem('CPU', '$cpu%'),
      SummaryItem('Memory', '$memory%'),
    ];

    if (model.formattedUptime.isNotEmpty) {
      items.add(SummaryItem('Uptime', model.formattedUptime));
    }

    return DimensionSummary(
      status: status,
      items: items,
      hint: 'Tap for actions',
    );
  }

  @override
  List<HealthAction> getActions(BuildContext context) {
    return [
      HealthAction(
        id: 'reboot_router',
        label: 'Reboot Router',
        icon: Icons.restart_alt,
        routeName: RouteNamed.uspAdmin,
      ),
      HealthAction(
        id: 'system_info',
        label: 'System Information',
        icon: Icons.info_outline,
        routeName: RouteNamed.uspAdmin,
      ),
    ];
  }
}
