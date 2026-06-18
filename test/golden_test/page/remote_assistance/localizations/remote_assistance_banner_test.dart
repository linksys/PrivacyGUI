import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/mocks/mock_remote_assistance.dart';
import '../fixtures/remote_assistance_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'remote_assistance_banner',
      view: () => const _BannerTestWrapper(),
      shell: ShellType.scaffold,
      height: 140,
      states: {
        'pending': (overrides) =>
            overrides.addAll(remoteAssistanceOverrides(pendingState)),
        'pending_urgent': (overrides) =>
            overrides.addAll(remoteAssistanceOverrides(pendingUrgentState)),
      },
    ),
  );
}

/// Wrapper widget that displays banner content directly for golden testing.
class _BannerTestWrapper extends ConsumerWidget {
  const _BannerTestWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remoteClientProvider);
    final status = state.sessionInfo?.status;

    // Only show for PENDING status with PIN
    if (status != GRASessionStatus.pending || state.pin == null) {
      return const Center(child: Text('No banner to display'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _BannerContent(state: state),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final RemoteClientState state;

  const _BannerContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pin = state.pin ?? '';
    final countdown = state.expiredCountdown ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.support_agent,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                AppGap.md(),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText.labelLarge(
                        'Remote Assistance',
                        color: colorScheme.onPrimaryContainer,
                      ),
                      AppGap.xs(),
                      Row(
                        children: [
                          AppText.bodySmall(
                            'PIN: ',
                            color: colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                          _PinChip(pin: pin, colorScheme: colorScheme),
                          AppGap.sm(),
                          _CountdownBadge(
                              seconds: countdown, colorScheme: colorScheme),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CopyButton(colorScheme: colorScheme),
                    AppGap.sm(),
                    _EndSessionButton(colorScheme: colorScheme),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinChip extends StatelessWidget {
  final String pin;
  final ColorScheme colorScheme;

  const _PinChip({required this.pin, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: AppText.labelMedium(
        pin,
        color: colorScheme.primary,
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final int seconds;
  final ColorScheme colorScheme;

  const _CountdownBadge({required this.seconds, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isUrgent = seconds < 300;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    final timeStr = '$minutes:${secs.toString().padLeft(2, '0')}';

    final color = isUrgent ? colorScheme.error : colorScheme.onPrimaryContainer;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined,
            size: 12, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 2),
        AppText.labelSmall(timeStr, color: color),
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  final ColorScheme colorScheme;

  const _CopyButton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Icon(
        Icons.copy_rounded,
        size: 20,
        color: colorScheme.onPrimaryContainer,
      ),
      tooltip: 'Copy PIN',
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
      ),
    );
  }
}

class _EndSessionButton extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EndSessionButton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Icon(
        Icons.close_rounded,
        size: 20,
        color: colorScheme.error,
      ),
      tooltip: 'End Session',
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.error.withValues(alpha: 0.1),
      ),
    );
  }
}
