import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';

/// Shared "force reconnect" (deauth) flow used by every Instant-Test surface
/// that can reconnect a device — the My Devices detail sheet and the Help Me
/// Fix It device flow. Shows a confirmation dialog, calls the single source of
/// truth `provider.deauthClient(mac)`, then shows a success snackbar.
///
/// [onProgress] is invoked with `true` when the deauth call starts and `false`
/// when it finishes, so a caller can drive a local spinner (e.g. the detail
/// sheet's "Disconnecting…" button). Returns true if the deauth ran.
Future<bool> confirmAndDeauth(
  BuildContext context,
  WidgetRef ref, {
  required String mac,
  required String displayName,
  ValueChanged<bool>? onProgress,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Force reconnect?'),
      content: Text(
          '$displayName will briefly lose its WiFi connection and reconnect '
          'automatically within a few seconds, which may improve its '
          'connection quality.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Reconnect'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  onProgress?.call(true);
  await ref.read(instantVerifyPivotProvider.notifier).deauthClient(mac);
  onProgress?.call(false);
  if (!context.mounted) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$displayName disconnected — it should reconnect in a moment.'),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
  return true;
}
