import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../models/diagnostic_state.dart';
import '../../providers/unified_diagnostics_notifier.dart';
import 'problem_card.dart';

class DiagnosticProblemSelector extends ConsumerWidget {
  const DiagnosticProblemSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(unifiedDiagnosticsProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText.headlineSmall('What issue are you experiencing?'),
        AppGap.xl(),

        // Option 1: No Internet
        ProblemCard(
          icon: Icons.wifi_off,
          title: 'No Internet Connection',
          description:
              'Unable to connect to the internet. Pages won\'t load and apps can\'t connect.',
          color: colorScheme.error,
          onTap: () => notifier.selectProblem(ProblemType.noInternet),
        ),
        AppGap.lg(),

        // Option 2: Slow Network
        ProblemCard(
          icon: Icons.speed,
          title: 'Slow Network',
          description:
              'Internet is connected but experiencing slow speeds or poor performance.',
          color: colorScheme.tertiary,
          onTap: () => notifier.selectProblem(ProblemType.slowNetwork),
        ),
        AppGap.xxxl(),

        Center(
          child: AppButton.text(
            label: 'Cancel',
            onTap: () => notifier.cancel(),
          ),
        ),
      ],
    );
  }
}
