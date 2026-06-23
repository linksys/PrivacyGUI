import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Banner for Remote Assistance PENDING state.
///
/// Shows PIN code with copy button and End Session action.
/// Tapping the banner opens the full dialog.
class RemoteAssistanceBanner extends ConsumerWidget {
  const RemoteAssistanceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remoteClientProvider);
    final status = state.sessionInfo?.status;

    // Only show for PENDING status with PIN
    if (status != GRASessionStatus.pending || state.pin == null) {
      return const SizedBox.shrink();
    }

    return _BannerContent(state: state);
  }
}

class _BannerContent extends ConsumerWidget {
  final RemoteClientState state;

  const _BannerContent({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pin = state.pin ?? '';
    final countdown = state.expiredCountdown ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          onTap: () => _openDialog(context, ref),
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
                        loc(context).remoteAssistance,
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
                    _CopyButton(pin: pin, colorScheme: colorScheme),
                    AppGap.sm(),
                    _EndSessionButton(
                      onTap: () => _endSession(context, ref),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDialog(BuildContext context, WidgetRef ref) {
    showAppDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _ExistingSessionDialog(),
    );
  }

  Future<void> _endSession(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: AppText.titleMedium(loc(context).endSessionQuestion),
        content: AppText.bodyMedium(
          'Are you sure you want to end the Remote Assistance session?',
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () => Navigator.of(context).pop(false),
          ),
          AppButton.danger(
            label: loc(context).endSession,
            size: AppButtonSize.small,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(remoteClientProvider.notifier).endRemoteAssistance();
    }
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
  final String pin;
  final ColorScheme colorScheme;

  const _CopyButton({required this.pin, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Clipboard.setData(ClipboardData(text: pin));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc(context).pinCopied),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
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
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _EndSessionButton({required this.onTap, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
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

/// Dialog for viewing existing session (opened from banner).
class _ExistingSessionDialog extends ConsumerWidget {
  const _ExistingSessionDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remoteClientProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final status = state.sessionInfo?.status;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _StatusIcon(
              icon: Icons.support_agent,
              color: colorScheme.primary,
              backgroundColor: colorScheme.primaryContainer,
            ),
            AppGap.lg(),
            AppText.titleLarge(loc(context).remoteAssistance),
            AppGap.xl(),
            // Content
            if (status == GRASessionStatus.pending)
              _PendingDialogContent(state: state)
            else if (status == GRASessionStatus.active)
              _ActiveDialogContent(state: state)
            else
              AppText.bodyMedium(loc(context).sessionNotFound),
            AppGap.xl(),
            // Actions
            if (status == GRASessionStatus.active)
              SizedBox(
                width: double.infinity,
                child: AppButton.danger(
                  label: loc(context).endSession,
                  onTap: () async {
                    await ref
                        .read(remoteClientProvider.notifier)
                        .endRemoteAssistance();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: AppButton.text(
                  label: loc(context).close,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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

class _PendingDialogContent extends StatelessWidget {
  final RemoteClientState state;

  const _PendingDialogContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pin = state.pin ?? '';
    final countdown = state.expiredCountdown ?? 0;

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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...pin.split('').map((digit) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AppText.displaySmall(
                      digit,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  )),
            ],
          ),
        ),
        AppGap.lg(),
        _CountdownChip(seconds: countdown),
      ],
    );
  }
}

class _ActiveDialogContent extends StatelessWidget {
  final RemoteClientState state;

  const _ActiveDialogContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final countdown = state.expiredCountdown ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        _CountdownChip(
            seconds: countdown, label: loc(context).sessionExpiresIn),
      ],
    );
  }
}

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
