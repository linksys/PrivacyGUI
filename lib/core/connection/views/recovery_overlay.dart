import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/connection/models/app_connection_state.dart';
import 'package:privacy_gui/core/connection/providers/app_connection_state_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

class RecoveryOverlay extends ConsumerWidget {
  const RecoveryOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(appConnectionStateProvider);

    return Stack(
      children: [
        child,
        if (connectionState == AppConnectionState.waitingForRecovery)
          _RecoveryModal(
            onReturnToLogin: () {
              ref.read(appConnectionStateProvider.notifier).exitToLogout();
            },
          ),
      ],
    );
  }
}

class _RecoveryModal extends StatelessWidget {
  const _RecoveryModal({required this.onReturnToLogin});

  final VoidCallback onReturnToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.router_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 24),
                AppText(
                  'Waiting for router...',
                  variant: AppTextVariant.titleLarge,
                ),
                const SizedBox(height: 8),
                AppText(
                  'The router is restarting. The app will reconnect automatically.',
                  variant: AppTextVariant.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(),
                const SizedBox(height: 48),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 16),
                AppButton.text(
                  label: 'Return to login page',
                  onTap: onReturnToLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
