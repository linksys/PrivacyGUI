import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@Deprecated('Use #package:privacygui_widgets/panel/AppSection instead')
class SectionTile extends ConsumerWidget {
  const SectionTile({
    Key? key,
    this.enabled = true,
    required this.header,
    required this.child,
  }) : super(key: key);

  final bool enabled;
  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Opacity(
          opacity: enabled ? 1 : 0.4,
          child: AbsorbPointer(
            absorbing: !enabled,
            child: child,
          ),
        ),
      ],
    );
  }
}
