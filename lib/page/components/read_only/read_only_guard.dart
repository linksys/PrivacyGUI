import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';

/// Helpers for the controls that write to the router directly, without going
/// through a page's Save bar.
///
/// Those are the only ones that need read-only code of their own; everything
/// that commits through PageBottomBar or showSubmitAppDialog is covered there.
/// Keeping them behind these two names makes every such site greppable.
extension ReadOnlyGuard on WidgetRef {
  /// [callback], or null in a read-only build - which disables the control.
  T? readOnlyGuard<T extends Function>(T? callback) =>
      watch(readOnlyModeProvider) ? null : callback;
}

/// Explains, on hover or long press, why [child] is disabled in a read-only
/// build. A plain pass-through otherwise.
class ReadOnlyTooltip extends ConsumerWidget {
  const ReadOnlyTooltip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(readOnlyModeProvider)) return child;
    return Tooltip(
      message: loc(context).readOnlyModeUnavailable,
      child: child,
    );
  }
}
