import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Why a list's Add button is disabled: the list is at FWDEV#204's rule limit.
///
/// Its own row under the tab header rather than beside the Add button, so a
/// long locale cannot push the button off the edge the way the header title
/// once did at 320px (#1377).
class RuleLimitNote extends StatelessWidget {
  const RuleLimitNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: AppText.bodySmall(
        loc(context).maxRulesReached,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
