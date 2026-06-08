import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';

/// Shared router-restart confirmation used across all Instant-Test surfaces
/// (Help Me Fix It, Instant-Test overview, My Network).
///
/// Enforces the once-per-session singleton (PRD B-5) and the confirmation
/// dialog (PRD D-23), then calls the single source of truth
/// `provider.restartRouter()`. Pass [onRestarted] for any surface-specific
/// follow-up (e.g. the overview tab's restart countdown).
Future<void> confirmAndRestart(BuildContext context, WidgetRef ref,
    {VoidCallback? onRestarted}) async {
  final state = ref.read(instantVerifyPivotProvider);
  if (state.hasRestartedThisSession) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'You\'ve already restarted this session. If the issue persists, contact Linksys Support.'),
        behavior: SnackBarBehavior.floating,
      ));
    }
    return;
  }
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restart your router?'),
      content: const Text(
          'All devices will disconnect for about 2 minutes.\n\n'
          'If you\'re on WiFi, this page will go blank. '
          'Wait 2 minutes, reconnect to your WiFi, then return to 192.168.1.1.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Restart'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(instantVerifyPivotProvider.notifier).restartRouter();
    onRestarted?.call();
  }
}
