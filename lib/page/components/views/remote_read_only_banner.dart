import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';

/// A banner widget that displays when the application is in remote read-only mode.
///
/// This banner appears at the top of the application to inform users that
/// router configuration changes are disabled when accessing remotely.
class RemoteReadOnlyBanner extends ConsumerWidget {
  const RemoteReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReadOnly = ref.watch(
      remoteAccessProvider.select((state) => state.isRemoteReadOnly),
    );

    if (!isReadOnly) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.error.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: colorScheme.onErrorContainer,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              loc(context).remoteViewModeActive,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
