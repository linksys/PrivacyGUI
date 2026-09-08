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

    return LayoutBlock(
      identifier: 'support-remote-assistance',
      onTap: credentials != null
          ? () =>
              showRemoteAssistanceDialog(context, ref, credentials: credentials)
          : null,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: AppIcon.font(
              Icons.support_agent,
              size: 24,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelLarge(loc(context).remoteAssistance),
                AppText.bodySmall(
                  'Get help from Linksys support',
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
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
