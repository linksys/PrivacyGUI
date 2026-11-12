import 'package:flutter/material.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';

import '../../mascot_config.dart';
import '../health_dimension.dart';

/// Health dimension for connected devices.
///
/// Evaluates:
/// - Ratio of online devices to total devices
/// - Presence of mesh nodes (bonus)
///
/// Score mapping:
/// - 100: All devices online or no devices
/// - 80: > 80% online
/// - 60: > 50% online
/// - 40: > 20% online
/// - 20: <= 20% online
class DevicesHealthDimension extends HealthDimension {
  @override
  HealthDimensionType get type => HealthDimensionType.devices;

  @override
  String displayName(AppLocalizations l10n) => l10n.devices;

  @override
  IconData get icon => Icons.devices;

  @override
  Set<InvalidationDomain> get watchedDomains => {
        InvalidationDomain.connectedDevices,
        InvalidationDomain.wifiClients,
      };

  @override
  int evaluate(HealthEvaluationContext context) {
    final devices = context.devices;
    if (devices == null) return 100;

    final total = devices.totalClientCount;
    if (total == 0) return 100;

    final online = devices.onlineClientCount;
    final ratio = online / total;

    if (ratio >= DevicesThresholds.excellent) return 100;
    if (ratio >= DevicesThresholds.good) return 80;
    if (ratio >= DevicesThresholds.fair) return 60;
    if (ratio >= 0.2) return 40;
    return 20;
  }

  @override
  DimensionSummary getSummary(
    HealthEvaluationContext context,
    AppLocalizations l10n,
  ) {
    final devices = context.devices;
    if (devices == null) {
      return DimensionSummary(
        status: l10n.loadingEllipsis,
        hint: l10n.mascotTapForActions,
      );
    }

    final online = devices.onlineClientCount;
    final total = devices.totalClientCount;
    final meshNodes = devices.nodes.where((n) => !n.isMaster).length;

    String status;
    if (total == 0) {
      status = l10n.mascotDevicesNone;
    } else if (online == total) {
      status = l10n.mascotDevicesAllOnline;
    } else {
      status = l10n.mascotDevicesOnlineCount(online);
    }

    final items = <SummaryItem>[
      SummaryItem(l10n.connected, '$online/$total'),
    ];

    if (meshNodes > 0) {
      items.add(SummaryItem(l10n.mascotDevicesMeshNodes, '$meshNodes'));
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
        id: 'view_devices',
        label: loc(context).viewDevices,
        icon: Icons.devices,
        routeName: RouteNamed.uspDeviceList,
      ),
      HealthAction(
        id: 'network_topology',
        label: loc(context).networkTopology,
        icon: Icons.hub,
        routeName: RouteNamed.uspTopology,
      ),
    ];
  }
}
