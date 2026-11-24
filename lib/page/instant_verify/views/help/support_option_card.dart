import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

/// A tappable card with an icon, a title and a description.
///
/// Moved here from `dashboard_support_view.dart`, which dev-1.3.x deleted in
/// #1849 together with the unreachable support-page PIN flow. Instant Test's
/// help journeys were its only remaining user.
class SupportOptionCard extends StatelessWidget {
  final Icon icon;
  final String title;
  final String description;
  final VoidCallback? tapAction;

  const SupportOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.tapAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        onTap: tapAction,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            icon,
            const AppGap.small2(),
            AppText.titleSmall(title),
            const AppGap.small2(),
            AppText.bodyMedium(description),
          ],
        ),
      ),
    );
  }
}
