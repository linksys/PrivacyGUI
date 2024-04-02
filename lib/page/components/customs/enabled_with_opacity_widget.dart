import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnabledOpacityWidget extends ConsumerWidget {
  const EnabledOpacityWidget(
      {super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AbsorbPointer(
      absorbing: !enabled,
      child: Opacity(opacity: enabled ? 1 : 0.5, child: child),
    );
  }
}
