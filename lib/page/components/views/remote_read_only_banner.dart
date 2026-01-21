import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade900,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Remote View Mode - Setting changes are disabled',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
