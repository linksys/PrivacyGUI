import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';

import '../health_dimension.dart';

/// Health dimension for Internet/WAN connectivity.
///
/// Evaluates:
/// - WAN link status (up/down)
/// - Connection stability
///
/// Score mapping:
/// - 100: WAN up and stable
/// - 50: WAN up but unstable (if detectable)
/// - 0: WAN down
class InternetHealthDimension extends HealthDimension {
  @override
  HealthDimensionType get type => HealthDimensionType.internet;

  @override
  String get displayName => 'Internet';

  @override
  IconData get icon => Icons.public;

  @override
  Set<InvalidationDomain> get watchedDomains => {
        InvalidationDomain.wanStatus,
      };

  @override
  int evaluate(HealthEvaluationContext context) {
    final wan = context.wan;
    if (wan == null) return 100; // No data = assume healthy

    final isUp = wan.model.isUp;
    if (!isUp) return 0;

    // TODO: Add stability detection if available
    return 100;
  }

  @override
  DimensionSummary getSummary(HealthEvaluationContext context) {
    final wan = context.wan;
    if (wan == null) {
      return const DimensionSummary(
        status: 'Loading...',
        hint: 'Tap for actions',
      );
    }

    final model = wan.model;
    final isUp = model.isUp;
    final items = <SummaryItem>[];

    if (model.ipAddress.isNotEmpty) {
      items.add(SummaryItem('IP', model.ipAddress));
    }
    if (model.gateway.isNotEmpty) {
      items.add(SummaryItem('Gateway', model.gateway));
    }
    if (model.addressingType.isNotEmpty) {
      items.add(SummaryItem('Type', model.addressingType));
    }

    return DimensionSummary(
      status: isUp ? 'Connected' : 'Disconnected',
      items: items,
      hint: 'Tap for actions',
    );
  }

  @override
  List<HealthAction> getActions(BuildContext context) {
    return [
      HealthAction(
        id: 'diagnose_internet',
        label: loc(context).runDiagnosticsTitle,
        icon: Icons.network_check,
        routeName: RouteNamed.uspUnifiedDiagnostics,
      ),
      HealthAction(
        id: 'internet_settings',
        label: loc(context).internetSettings,
        icon: Icons.settings,
        routeName: RouteNamed.uspInternetSettings,
      ),
    ];
  }
}
