import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

/// Home-page entry card for Instant-Test.
///
/// Reusable: pass [onTap] so it can route to the real `menuInstantTest` from
/// the dashboard home, or into the single-page prototype during exploration.
class InstantTestCard extends StatelessWidget {
  const InstantTestCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.all(Spacing.large2),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: scheme.primary),
              const AppGap.small2(),
              AppText.titleMedium('Instant-Test'),
              const Spacer(),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
          const AppGap.medium(),
          AppText.bodyMedium(
            'Check your WiFi and internet health in one tap — and get '
            'guided help to fix any issues.',
          ),
        ],
      ),
    );
  }
}
