import 'package:flutter/material.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
  String displayName(AppLocalizations l10n) => l10n.system;

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
  DimensionSummary getSummary(
    HealthEvaluationContext context,
    AppLocalizations l10n,
  ) {
    final info = context.systemInfo;
    if (info == null) {
      return DimensionSummary(
        status: l10n.loadingEllipsis,
        hint: l10n.mascotTapForActions,
      );
    }

    final model = info.model;
    final cpu = model.cpuPercent;
    final memory = model.memoryPercent;
    final maxUsage = cpu > memory ? cpu : memory;

    String status;
    if (maxUsage < SystemThresholds.excellent) {
      status = l10n.healthy;
    } else if (maxUsage < SystemThresholds.good) {
      status = l10n.mascotSystemNormal;
    } else if (maxUsage < SystemThresholds.fair) {
      status = l10n.mascotSystemModerateLoad;
    } else {
      status = l10n.mascotSystemHighLoad;
    }

    final items = <SummaryItem>[
      SummaryItem(l10n.cpu, '$cpu%'),
      SummaryItem(l10n.memory, '$memory%'),
    ];

    if (model.formattedUptime.isNotEmpty) {
      items.add(SummaryItem(l10n.uptime, model.formattedUptime));
    }

    return DimensionSummary(
      status: status,
      items: items,
      hint: l10n.mascotTapForActions,
    );
  }

  @override
  List<HealthAction> getActions(BuildContext context) {
    return [
      HealthAction(
        id: 'reboot_router',
        label: loc(context).rebootRouter,
        icon: Icons.restart_alt,
        routeName: RouteNamed.uspAdmin,
      ),
      HealthAction(
        id: 'system_info',
        label: loc(context).systemInformation,
        icon: Icons.info_outline,
        routeName: RouteNamed.uspAdmin,
      ),
    ];
  }
}
