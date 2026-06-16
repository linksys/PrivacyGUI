import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/route/constants.dart';

import '../health_dimension.dart';

/// Health dimension for firmware status.
///
/// Evaluates:
/// - Whether firmware is up to date
/// - Whether there's an available update bank
///
/// Score mapping:
/// - 100: Running latest or no update info available
/// - 60: Update available (not critical but recommended)
class FirmwareHealthDimension extends HealthDimension {
  @override
  HealthDimensionType get type => HealthDimensionType.firmware;

  @override
  String get displayName => 'Firmware';

  @override
  IconData get icon => Icons.system_update;

  @override
  Set<InvalidationDomain> get watchedDomains => const {};

  @override
  int evaluate(HealthEvaluationContext context) {
    final firmware = context.firmware;
    if (firmware == null) return 100;

    final available = firmware.availableBank;
    if (available != null) {
      return 60; // Update available
    }

    return 100; // Up to date
  }

  @override
  DimensionSummary getSummary(HealthEvaluationContext context) {
    final firmware = context.firmware;
    if (firmware == null) {
      return const DimensionSummary(
        status: 'Loading...',
        hint: 'Tap for actions',
      );
    }

    final active = firmware.activeBank;
    final available = firmware.availableBank;

    String status;
    if (available != null) {
      status = 'Update Available';
    } else {
      status = 'Up to Date';
    }

    final items = <SummaryItem>[];

    if (active != null) {
      items.add(SummaryItem('Current', active.version));
    }

    if (available != null) {
      items.add(SummaryItem('Available', available.version));
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
        id: 'firmware_update',
        label: 'Firmware Update',
        icon: Icons.system_update,
        routeName: RouteNamed.uspFirmwareUpdate,
      ),
    ];
  }
}
