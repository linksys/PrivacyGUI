import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../providers/unified_diagnostics_notifier.dart';

class DiagnosticStartView extends ConsumerWidget {
  const DiagnosticStartView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGap.xxl(),
        // Hero section
        Icon(
          Icons.network_check,
          size: 100,
          color: colorScheme.primary,
        ),
        AppGap.xl(),
        AppText.headlineMedium(
          'Network Diagnostics',
          textAlign: TextAlign.center,
        ),
        AppGap.md(),
        AppText.bodyMedium(
          'Keep your connection fast and reliable with our automated health check.',
          textAlign: TextAlign.center,
          color: colorScheme.onSurfaceVariant,
        ),
        AppGap.xxxl(),

        // Primary Action: Full Diagnostic
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AppCard(
            child: InkWell(
              onTap: () => notifier.runFullDiagnostic(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    Icon(Icons.rocket_launch,
                        size: 48, color: colorScheme.primary),
                    AppGap.lg(),
                    AppText.titleLarge('Run Full Diagnostic'),
                    AppGap.sm(),
                    AppText.bodySmall(
                      'Automatically check every component of your network to find and fix issues.',
                      textAlign: TextAlign.center,
                    ),
                    AppGap.xl(),
                    AppButton(
                      label: 'Start Now',
                      onTap: () => notifier.runFullDiagnostic(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AppGap.xl(),

        // Secondary Action: Choose Specific Issue
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child:
                  AppText.bodySmall('OR', color: colorScheme.onSurfaceVariant),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        AppGap.xl(),

        AppCard(
          child: InkWell(
            onTap: () => notifier.startWithPreQualifier(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.search, color: colorScheme.secondary),
                  ),
                  AppGap.lg(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.titleMedium('Choose Specific Issue'),
                        AppText.bodySmall(
                          'Experiencing a specific problem? Select from common scenarios.',
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        AppGap.xxxl(),
      ],
    );
  }
}
