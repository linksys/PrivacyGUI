import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';

import '../health_dimension.dart';

/// Health dimension for firmware status.
///
/// Evaluates:
/// - Whether the router reports a newer firmware version it can download
///
/// Score mapping:
/// - 100: Running latest or no update info available
/// - 60: Update available (not critical but recommended)
///
/// "Update available" is the virtual OTA instance, never a free NAND bank: the
/// spare bank reports `Available=1` on every healthy router, so reading it here
/// pinned this dimension at 60 permanently.
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

    final ota = firmware.otaInstance;
    if (ota != null && ota.available) {
      return 60; // Update available
    }

    return 100; // Up to date, or the router reports no update information
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
    final ota = firmware.otaInstance;
    final hasUpdate = ota != null && ota.available;

    String status;
    if (hasUpdate) {
      status = 'Update Available';
    } else {
      status = 'Up to Date';
    }

    final items = <SummaryItem>[];

    if (active != null) {
      items.add(SummaryItem('Current', active.version));
    }

    if (hasUpdate) {
      items.add(SummaryItem('Available', ota.version));
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
        label: loc(context).firmwareUpdate,
        icon: Icons.system_update,
        routeName: RouteNamed.uspFirmwareUpdate,
      ),
    ];
  }
}
