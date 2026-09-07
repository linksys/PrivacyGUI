import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
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
            AppText.labelLarge(loc(context).firewall),
            AppGap.sm(),
            AppBadge(
              label: enabled ? loc(context).enabled : loc(context).disabled,
            ),
          ],
        ),
        AppGap.sm(),
        if (ipv4Enabled != null)
          AiInfoRow(
            label: loc(context).ipv4Firewall,
            value: ipv4Enabled! ? loc(context).enabled : loc(context).disabled,
          ),
        if (ipv6Enabled != null)
          AiInfoRow(
            label: loc(context).ipv6Firewall,
            value: ipv6Enabled! ? loc(context).enabled : loc(context).disabled,
          ),
        if (ruleCount != null)
          AiInfoRow(label: loc(context).activeRules, value: '$ruleCount'),
        if (dmzEnabled != null)
          AiInfoRow(
            label: loc(context).dmz,
            value: dmzEnabled! ? loc(context).enabled : loc(context).disabled,
          ),
      ],
    );
  }
}
