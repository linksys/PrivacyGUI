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
      viewName: 'remote_assistance_dialog',
      view: () => const _DialogContentWrapper(),
      shell: ShellType.scaffold,
      height: 520,
      states: {
        'initiate': (overrides) =>
            overrides.addAll(remoteAssistanceOverrides(initiateState)),
        'pending': (overrides) =>
            overrides.addAll(remoteAssistanceOverrides(pendingState)),
        'pending_generating': (overrides) =>
            overrides.addAll(remoteAssistanceOverrides(pendingNoPinState)),
        'active': (overrides) =>
            overrides.addAll(remoteAssistanceOverrides(activeState)),
        'invalid': (overrides) =>
            overrides.addAll(remoteAssistanceOverrides(invalidState)),
      },
    ),
  );
}

/// Wrapper widget that displays dialog content directly for golden testing.
class _DialogContentWrapper extends ConsumerWidget {
  const _DialogContentWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remoteClientProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final status = state.sessionInfo?.status;

    return Center(
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 380,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon
              _buildHeader(context, status, colorScheme),
              AppGap.xl(),
              // Content
              _buildContent(context, state, colorScheme),
              AppGap.xl(),
              // Actions
              _buildActions(context, state, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, GRASessionStatus? status, ColorScheme colorScheme) {
    final isActive = status == GRASessionStatus.active;
    final isInvalid = status == GRASessionStatus.invalid;

    return Column(
      children: [
        if (isActive)
          _ActiveIconStatic(colorScheme: colorScheme)
        else if (isInvalid)
          _StatusIcon(
            icon: Icons.error_outline,
            color: colorScheme.error,
            backgroundColor: colorScheme.errorContainer,
          )
        else
          _StatusIcon(
            icon: Icons.support_agent,
            color: colorScheme.primary,
            backgroundColor: colorScheme.primaryContainer,
          ),
        AppGap.lg(),
        AppText.titleLarge('Remote Assistance'),
      ],
    );
  }

  Widget _buildContent(
      BuildContext context, RemoteClientState state, ColorScheme colorScheme) {
    final status = state.sessionInfo?.status ?? GRASessionStatus.initiate;

    return switch (status) {
      GRASessionStatus.initiate => const _InitiateContent(),
      GRASessionStatus.pending => _PendingContent(state: state),
      GRASessionStatus.active => _ActiveContent(state: state),
      GRASessionStatus.invalid => const _InvalidContent(),
    };
  }

  Widget _buildActions(
      BuildContext context, RemoteClientState state, ColorScheme colorScheme) {
    final status = state.sessionInfo?.status;

    if (status == GRASessionStatus.active) {
      return SizedBox(
        width: double.infinity,
        child: AppButton.danger(
          label: 'End Session',
          onTap: () {},
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AppButton.text(
        label: 'Close',
        onTap: () {},
      ),
    );
  }
}

// =============================================================================
// Status Icon
// =============================================================================

class _StatusIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatusIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Icon(icon, size: 40, color: color),
    );
  }
}

// =============================================================================
// Active Icon Static (for golden test - no animation)
// =============================================================================

class _ActiveIconStatic extends StatelessWidget {
  final ColorScheme colorScheme;

  const _ActiveIconStatic({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static ripple rings
          ...List.generate(3, (index) {
            final scale = 0.5 + (index * 0.25);
            final opacity = (1.0 - (index * 0.3)) * 0.3;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: opacity),
                    width: 2,
                  ),
                ),
              ),
            );
          }),
          // Center icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.support_agent,
              size: 32,
              color: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Initiate Content
// =============================================================================

class _InitiateContent extends StatelessWidget {
  const _InitiateContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.bodyMedium(
          'To take advantage of Remote Assistance, you must first contact a phone support agent. Go to linksys.com/support and click on Phone Call to get started.',
          textAlign: TextAlign.center,
        ),
        AppGap.xl(),
        // Status indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              ),
              AppGap.sm(),
              AppText.labelMedium(
                'Waiting for agent...',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Pending Content
// =============================================================================

class _PendingContent extends StatelessWidget {
  final RemoteClientState state;

  const _PendingContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pin = state.pin;
    final countdown = state.expiredCountdown ?? 0;

    if (pin == null || pin.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          AppGap.lg(),
          AppText.bodyMedium(
            'Generating PIN...',
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.bodyMedium(
          'Share this PIN with your support agent:',
          color: colorScheme.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
        AppGap.lg(),
        // PIN display
        _PinDisplay(pin: pin),
        AppGap.lg(),
        // Countdown chip
        _CountdownChip(seconds: countdown),
      ],
    );
  }
}

class _PinDisplay extends StatelessWidget {
  final String pin;

  const _PinDisplay({required this.pin});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // PIN digits with spacing
          ...pin.split('').map((digit) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AppText.displaySmall(
                  digit,
                  color: colorScheme.onPrimaryContainer,
                ),
              )),
          AppGap.lg(),
          // Copy icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.copy_rounded,
              size: 18,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Active Content
// =============================================================================

class _ActiveContent extends StatelessWidget {
  final RemoteClientState state;

  const _ActiveContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final countdown = state.expiredCountdown ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              AppGap.xs(),
              AppText.labelMedium(
                'Connected',
                color: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
        AppGap.lg(),
        AppText.bodyMedium(
          'A support agent is currently connected to your router. Please do not close this window.',
          color: colorScheme.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
        AppGap.lg(),
        _CountdownChip(seconds: countdown, label: 'Session expires in'),
      ],
    );
  }
}

// =============================================================================
// Invalid Content
// =============================================================================

class _InvalidContent extends StatelessWidget {
  const _InvalidContent();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.bodyMedium(
          'The session has expired or been terminated. Please contact support again if you need further assistance.',
          color: colorScheme.onSurfaceVariant,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// =============================================================================
// Countdown Chip
// =============================================================================

class _CountdownChip extends StatelessWidget {
  final int seconds;
  final String label;

  const _CountdownChip({
    required this.seconds,
    this.label = 'Expires in',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUrgent = seconds < 300;

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    String timeStr;
    if (hours > 0) {
      timeStr = '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      timeStr = '${minutes}m ${secs}s';
    } else {
      timeStr = '${secs}s';
    }

    final bgColor = isUrgent
        ? colorScheme.errorContainer
        : colorScheme.surfaceContainerHigh;
    final fgColor =
        isUrgent ? colorScheme.onErrorContainer : colorScheme.onSurfaceVariant;
    final timeColor = isUrgent ? colorScheme.error : colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: fgColor),
          AppGap.xs(),
          AppText.labelSmall('$label ', color: fgColor),
          AppText.labelMedium(timeStr, color: timeColor),
        ],
      ),
    );
  }
}
