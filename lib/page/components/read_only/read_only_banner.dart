import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

/// Tells the viewer, on every dashboard page, that nothing here can be saved.
///
/// Renders nothing in a writable build.
class ReadOnlyBanner extends ConsumerWidget {
  const ReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(readOnlyModeProvider)) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      identifier: 'now-read-only-banner',
      child: Container(
        width: double.infinity,
        color: colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.visibility_outlined,
                size: 20, color: colorScheme.onSecondaryContainer),
            const AppGap.small2(),
            Expanded(
              child: AppText.labelMedium(
                loc(context).readOnlyModeBanner,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
