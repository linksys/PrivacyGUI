import 'package:flutter/cupertino.dart';

class EnabledOpacityWidget extends StatelessWidget {
  const EnabledOpacityWidget(
      {super.key, required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: !enabled,
      child: Opacity(opacity: enabled ? 1 : 0.5, child: child),
    );
  }
}
