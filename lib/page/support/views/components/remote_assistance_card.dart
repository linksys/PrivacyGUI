import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/device_credentials_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/remote_assistance/views/remote_assistance_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The support page's entry point for *requesting* remote assistance.
///
/// Was private to `usp_support_view.dart` until #1497; it is public and on its
/// own now so `SurfaceStrategy.assistanceEntryCard()` can name it, which is what
/// replaced the page's inverted `GlobalConfig.remote` gate. A support session
/// does not offer to start another one, so the remote surface simply has no card
/// here.
class RemoteAssistanceCard extends ConsumerWidget {
  const RemoteAssistanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final credentials = ref.watch(deviceCredentialsProvider);
    final available = credentials != null;

    return LayoutBlock(
      identifier: 'support-remote-assistance',
      onTap: available
          ? () =>
              showRemoteAssistanceDialog(context, ref, credentials: credentials)
          : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: available
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppIcon.font(
              Icons.support_agent,
              size: 24,
              color: available
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(
                  loc(context).remoteAssistance,
                  color: available ? null : colorScheme.onSurfaceVariant,
                ),
                // The unavailable subtitle is the whole point of the state: this
                // row used to look identical whether or not it could be pressed,
                // so a router that cannot supply its cloud UUID produced a row
                // that silently ignored taps. See PrivacyGUI#1582.
                AppText.bodySmall(
                  available
                      ? 'Get help from Linksys support'
                      : loc(context).notAvailable,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          // No chevron when there is nowhere to go.
          if (available)
            AppIcon.font(
              Icons.chevron_right,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }
}
