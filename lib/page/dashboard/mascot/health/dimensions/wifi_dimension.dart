import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/route/constants.dart';

import '../health_dimension.dart';

/// Health dimension for WiFi status.
///
/// Evaluates:
/// - Number of enabled radios vs total radios
/// - Radio health (all enabled = healthy)
///
/// Score mapping:
/// - 100: All radios enabled
/// - 70: Some radios enabled
/// - 30: All radios disabled
class WifiHealthDimension extends HealthDimension {
  @override
  HealthDimensionType get type => HealthDimensionType.wifi;

  @override
  String get displayName => 'WiFi';

  @override
  IconData get icon => Icons.wifi;

  @override
  Set<InvalidationDomain> get watchedDomains => {
        InvalidationDomain.wifiRadios,
        InvalidationDomain.wifiSsids,
        InvalidationDomain.wifiAccessPoints,
      };

  @override
  int evaluate(HealthEvaluationContext context) {
    final wifi = context.wifi;
    if (wifi == null) return 100;

    final radios = wifi.radioModels;
    if (radios.isEmpty) return 100;

    final enabledCount = radios.where((r) => r.enable).length;
    final totalCount = radios.length;

    if (enabledCount == totalCount) return 100;
    if (enabledCount == 0) return 30;
    return 70; // Partial
  }

  @override
  DimensionSummary getSummary(HealthEvaluationContext context) {
    final wifi = context.wifi;
    if (wifi == null) {
      return const DimensionSummary(
        status: 'Loading...',
        hint: 'Tap for actions',
      );
    }

    final radios = wifi.radioModels;
    if (radios.isEmpty) {
      return const DimensionSummary(
        status: 'No radios',
        hint: 'Tap for actions',
      );
    }

    final enabledCount = radios.where((r) => r.enable).length;
    final totalCount = radios.length;

    String status;
    if (enabledCount == totalCount) {
      status = 'All Active';
    } else if (enabledCount == 0) {
      status = 'All Disabled';
    } else {
      status = 'Partial';
    }

    final items = <SummaryItem>[
      SummaryItem('Radios', '$enabledCount/$totalCount enabled'),
    ];

    for (final radio in radios) {
      final state = radio.enable ? 'On' : 'Off';
      items.add(SummaryItem(radio.band, state));
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
        id: 'wifi_settings',
        label: loc(context).menuWifiSettings,
        icon: Icons.wifi,
        routeName: RouteNamed.uspWifiSettings,
      ),
      HealthAction(
        id: 'wifi_guest',
        label: loc(context).guestNetwork,
        icon: Icons.people,
        routeName: RouteNamed.uspWifiSettings,
      ),
    ];
  }
}
