import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
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
  String get displayName => 'Devices';

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
  DimensionSummary getSummary(HealthEvaluationContext context) {
    final devices = context.devices;
    if (devices == null) {
      return const DimensionSummary(
        status: 'Loading...',
        hint: 'Tap for actions',
      );
    }

    final online = devices.onlineClientCount;
    final total = devices.totalClientCount;
    final meshNodes = devices.nodeModels.where((n) => !n.isMaster).length;

    String status;
    if (total == 0) {
      status = 'No devices';
    } else if (online == total) {
      status = 'All Online';
    } else {
      status = '$online Online';
    }

    final items = <SummaryItem>[
      SummaryItem('Connected', '$online/$total'),
    ];

    if (meshNodes > 0) {
      items.add(SummaryItem('Mesh Nodes', '$meshNodes'));
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
        id: 'view_devices',
        label: 'View Devices',
        icon: Icons.devices,
        routeName: RouteNamed.uspDeviceList,
      ),
      HealthAction(
        id: 'network_topology',
        label: 'Network Topology',
        icon: Icons.hub,
        routeName: RouteNamed.uspTopology,
      ),
    ];
  }
}
