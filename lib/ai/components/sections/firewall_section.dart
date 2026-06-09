import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import '../ai_info_row.dart';

/// Firewall status section.
///
/// Displays firewall enable state, IPv4/IPv6 status, rule count, and DMZ.
class FirewallSection extends StatelessWidget {
  final bool enabled;
  final bool? ipv4Enabled;
  final bool? ipv6Enabled;
  final int? ruleCount;
  final bool? dmzEnabled;

  const FirewallSection({
    super.key,
    required this.enabled,
    this.ipv4Enabled,
    this.ipv6Enabled,
    this.ruleCount,
    this.dmzEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            AppText.labelLarge('Firewall'),
            AppGap.sm(),
            AppBadge(
              label: enabled ? 'Enabled' : 'Disabled',
            ),
          ],
        ),
        AppGap.sm(),
        if (ipv4Enabled != null)
          AiInfoRow(
            label: 'IPv4 Firewall',
            value: ipv4Enabled! ? 'Enabled' : 'Disabled',
          ),
        if (ipv6Enabled != null)
          AiInfoRow(
            label: 'IPv6 Firewall',
            value: ipv6Enabled! ? 'Enabled' : 'Disabled',
          ),
        if (ruleCount != null)
          AiInfoRow(label: 'Active Rules', value: '$ruleCount'),
        if (dmzEnabled != null)
          AiInfoRow(label: 'DMZ', value: dmzEnabled! ? 'Enabled' : 'Disabled'),
      ],
    );
  }
}
