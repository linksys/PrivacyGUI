import 'package:flutter/material.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_state.dart';
import '../../models/recommendation_catalog.dart';

class RecommendationCard extends StatelessWidget {
  final RecommendationUIModel rec;

  const RecommendationCard({super.key, required this.rec});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Block(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: colorScheme.tertiary,
              size: 24,
            ),
            AppGap.md(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.titleSmall(RecommendationCatalog.title(rec.titleKey)),
                  AppGap.xs(),
                  AppText.bodySmall(
                      RecommendationCatalog.description(rec.descriptionKey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
