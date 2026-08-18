import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Port forwarding rules section.
///
/// Displays a list of port forwarding rules with description, port, protocol.
class PortForwardingSection extends StatelessWidget {
  final List<Map<String, dynamic>>? rules;

  const PortForwardingSection({
    super.key,
    this.rules,
  });

  @override
  Widget build(BuildContext context) {
    if (rules == null || rules!.isEmpty) {
      return AppText.body(loc(context).noPortForwardingRulesConfigured);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final rule in rules!) _buildRuleRow(context, rule),
      ],
    );
  }

  Widget _buildRuleRow(BuildContext context, Map<String, dynamic> rule) {
    final description =
        rule['description'] as String? ?? loc(context).unnamedRule;
    final port = rule['port'];
    final protocol = rule['protocol'] as String? ?? 'TCP';
    final enabled = rule['enabled'] as bool? ?? true;
    final internalIp = rule['internalIp'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.grey,
            size: 18,
          ),
          AppGap.sm(),
          Expanded(
            flex: 3,
            child: AppText.body(description),
          ),
          SizedBox(
            width: 80,
            child: AppText.bodySmall('$port/$protocol'),
          ),
          if (internalIp != null)
            SizedBox(
              width: 100,
              child: AppText.bodySmall(internalIp),
            ),
        ],
      ),
    );
  }
}
