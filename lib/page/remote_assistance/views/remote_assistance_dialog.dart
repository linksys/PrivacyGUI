import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/url_links.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shows the Remote Assistance dialog for device owners (client-side).
void showRemoteAssistanceDialog(
  BuildContext context,
  WidgetRef ref, {
  required DeviceCredentials credentials,
}) {
  showAppDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RemoteAssistanceDialog(credentials: credentials),
  );
}

class _RemoteAssistanceDialog extends ConsumerStatefulWidget {
  final DeviceCredentials credentials;

  const _RemoteAssistanceDialog({required this.credentials});

  @override
  ConsumerState<_RemoteAssistanceDialog> createState() =>
      _RemoteAssistanceDialogState();
}

class _RemoteAssistanceDialogState
    extends ConsumerState<_RemoteAssistanceDialog> {
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initiate();
  }

  Future<void> _initiate() async {
    try {
      final notifier = ref.read(remoteClientProvider.notifier);
      notifier.setCredentials(widget.credentials);
      await notifier.initiateRemoteAssistance();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } on ServiceError catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'An unexpected error occurred';
        });
      }
    }
  }

  Future<void> _endSession() async {
    await ref.read(remoteClientProvider.notifier).endRemoteAssistance();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(remoteClientProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final status = state.sessionInfo?.status;

    // Listen for session becoming invalid while ACTIVE and auto-show message
    ref.listen(remoteClientProvider, (prev, next) {
      final prevStatus = prev?.sessionInfo?.status;
      final nextStatus = next.sessionInfo?.status;

      // Only trigger if status was ACTIVE and changed TO invalid
      if (prevStatus == GRASessionStatus.active &&
          nextStatus == GRASessionStatus.invalid) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remote assistance session has ended'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            _buildHeader(context, status, colorScheme),
            AppGap.xl(),
            // Content
            if (_isLoading)
              const _LoadingContent()
            else if (_error != null)
              _ErrorContent(error: _error!)
            else
              _buildContent(state, colorScheme),
            AppGap.xl(),
            // Actions
            _buildActions(context, state, colorScheme),
          ],
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
          const _ActiveAnimatedIcon()
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
        AppText.titleLarge(loc(context).remoteAssistance),
      ],
    );
  }

  Widget _buildContent(RemoteClientState state, ColorScheme colorScheme) {
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
          onTap: _endSession,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: AppButton.text(
        label: loc(context).close,
        onTap: () {
          ref.read(remoteClientProvider.notifier).endRemoteAssistance();
          Navigator.of(context).pop();
        },
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
// Active Animated Icon - Ripple effect
// =============================================================================

class _ActiveAnimatedIcon extends StatefulWidget {
  const _ActiveAnimatedIcon();

  @override
  State<_ActiveAnimatedIcon> createState() => _ActiveAnimatedIconState();
}

class _ActiveAnimatedIconState extends State<_ActiveAnimatedIcon>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple rings
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _rippleController,
              builder: (context, child) {
                final delay = index * 0.33;
                final value =
                    ((_rippleController.value + delay) % 1.0).clamp(0.0, 1.0);
                final scale = 0.5 + (value * 0.8);
                final opacity = (1.0 - value) * 0.4;

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
              },
            );
          }),
          // Center icon with pulse
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
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
              );
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Loading Content
// =============================================================================

class _LoadingContent extends StatelessWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// =============================================================================
// Error Content
// =============================================================================

class _ErrorContent extends StatelessWidget {
  final String error;

  const _ErrorContent({required this.error});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppText.bodyMedium(
          error,
          color: colorScheme.error,
          textAlign: TextAlign.center,
        ),
      ],
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
        AppStyledText(
          text:
              'To take advantage of Remote Assistance, you must first contact a phone support agent. Go to {{support:linksys.com/support}} and click on Phone Call to get started.',
          textAlign: TextAlign.center,
          onTapHandlers: {
            'support': () => gotoOfficialWebUrl(linkSupport),
          },
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

    return InkWell(
      onTap: () => _copyPin(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
      ),
    );
  }

  void _copyPin(BuildContext context) {
    Clipboard.setData(ClipboardData(text: pin));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
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

// =============================================================================
// Public Dialog for Restored Active Session
// =============================================================================

/// Dialog shown when an ACTIVE RA session is restored after page refresh.
///
/// This is a blocking dialog that only allows ending the session.
/// Automatically closes when the session becomes INVALID (e.g., CA ended it).
class RemoteAssistanceActiveDialog extends ConsumerWidget {
  const RemoteAssistanceActiveDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remoteClientProvider);
    final status = state.sessionInfo?.status;

    // Listen for session becoming invalid and auto-close
    ref.listen(remoteClientProvider, (prev, next) {
      final prevStatus = prev?.sessionInfo?.status;
      final nextStatus = next.sessionInfo?.status;

      // Only trigger if status changed TO invalid (not initial)
      if (prevStatus != null &&
          prevStatus != GRASessionStatus.invalid &&
          nextStatus == GRASessionStatus.invalid) {
        // Show snackbar and close dialog
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remote assistance session has ended'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    });

    // If already invalid when dialog opens (edge case), show invalid UI
    final isInvalid = status == GRASessionStatus.invalid;

    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            if (isInvalid)
              _StatusIcon(
                icon: Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
              )
            else
              const _ActiveAnimatedIcon(),
            AppGap.lg(),
            AppText.titleLarge(loc(context).remoteAssistance),
            AppGap.xl(),
            // Content
            if (isInvalid)
              const _InvalidContent()
            else
              _ActiveContent(state: state),
            AppGap.xl(),
            // Actions
            SizedBox(
              width: double.infinity,
              child: isInvalid
                  ? AppButton.text(
                      label: loc(context).close,
                      onTap: () => Navigator.of(context).pop(),
                    )
                  : AppButton.danger(
                      label: 'End Session',
                      onTap: () async {
                        await ref
                            .read(remoteClientProvider.notifier)
                            .endRemoteAssistance();
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
