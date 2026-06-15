import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/route/constants.dart';

import '../health_dimension.dart';

/// Health dimension for security settings.
///
/// Evaluates:
/// - IPv4 firewall enabled (required)
/// - IPv6 firewall enabled (bonus)
/// - DMZ disabled (security risk if enabled)
///
/// Score mapping:
/// - 100: IPv4 + IPv6 firewall on, DMZ off
/// - 80: IPv4 firewall on, DMZ off
/// - 50: IPv4 firewall on, DMZ on (security risk)
/// - 30: IPv4 firewall off
class SecurityHealthDimension extends HealthDimension {
  @override
  HealthDimensionType get type => HealthDimensionType.security;

  @override
  String get displayName => 'Security';

  @override
  IconData get icon => Icons.security;

  @override
  Set<InvalidationDomain> get watchedDomains => {
        InvalidationDomain.firewallRules,
        InvalidationDomain.dmz,
      };

  @override
  int evaluate(HealthEvaluationContext context) {
    final firewall = context.firewall;
    if (firewall == null) return 100;

    final ipv4On = firewall.firewallModel.isIPv4FirewallEnabled;
    final ipv6On = firewall.firewallModel.isIPv6FirewallEnabled;
    final dmzOn = firewall.dmzModel.isEnabled;

    if (!ipv4On) return 30; // Critical: no firewall

    if (dmzOn) return 50; // Warning: DMZ exposes device

    if (ipv4On && ipv6On) return 100;
    return 80; // IPv4 only
  }

  @override
  DimensionSummary getSummary(HealthEvaluationContext context) {
    final firewall = context.firewall;
    if (firewall == null) {
      return const DimensionSummary(
        status: 'Loading...',
        hint: 'Tap for actions',
      );
    }

    final ipv4On = firewall.firewallModel.isIPv4FirewallEnabled;
    final ipv6On = firewall.firewallModel.isIPv6FirewallEnabled;
    final dmzOn = firewall.dmzModel.isEnabled;

    String status;
    if (!ipv4On) {
      status = 'At Risk';
    } else if (dmzOn) {
      status = 'DMZ Active';
    } else if (ipv4On && ipv6On) {
      status = 'Protected';
    } else {
      status = 'Basic';
    }

    final items = <SummaryItem>[
      SummaryItem('IPv4 Firewall', ipv4On ? 'On' : 'Off'),
      SummaryItem('IPv6 Firewall', ipv6On ? 'On' : 'Off'),
      SummaryItem('DMZ', dmzOn ? 'Enabled' : 'Disabled'),
    ];

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
        id: 'firewall_settings',
        label: 'Firewall Settings',
        icon: Icons.shield,
        routeName: RouteNamed.uspFirewall,
      ),
      HealthAction(
        id: 'dmz_settings',
        label: 'DMZ Settings',
        icon: Icons.public_off,
        routeName: RouteNamed.uspDmz,
      ),
    ];
  }
}
