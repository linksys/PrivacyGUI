import 'package:privacygui_widgets/widgets/_widgets.dart';
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
      title: const AppText.titleMedium('Force reconnect?'),
      content: AppText.bodyMedium(
          '$displayName will briefly lose its WiFi connection and reconnect '
          'automatically within a few seconds, which may improve its '
          'connection quality.'),
      actions: [
        AppTextButton('Cancel',
                onTap: () => Navigator.pop(ctx, false)),
        AppFilledButton('Reconnect',
                onTap: () => Navigator.pop(ctx, true)),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  onProgress?.call(true);
  try {
    await ref.read(instantVerifyPivotProvider.notifier).deauthClient(mac);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: AppText.bodyMedium(
            'The reconnect request could not be confirmed. Check the device connection before trying again.',
            color: Theme.of(context).colorScheme.onInverseSurface),
      ));
    }
    return false;
  } finally {
    if (context.mounted) onProgress?.call(false);
  }
  if (!context.mounted) return true;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: AppText.bodyMedium(
          '$displayName disconnected — it should reconnect in a moment.',
          color: Theme.of(context).colorScheme.onInverseSurface),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ),
  );
  return true;
}
