import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class HiddenPasswordWidget extends ConsumerStatefulWidget {
  final String password;
  const HiddenPasswordWidget({Key? key, required this.password})
      : super(key: key);

  @override
  ConsumerState<HiddenPasswordWidget> createState() =>
      _HiddenPasswordWidgetState();
}

class _HiddenPasswordWidgetState extends ConsumerState<HiddenPasswordWidget> {
  bool isPwSecure = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppText.headlineMedium(
          _getPasswordContent(),
        ),
        const AppGap.semiSmall(),
        AppIconButton(
          icon: isPwSecure
              ? LinksysIcons.visibility
              : LinksysIcons.visibilityOff,
          onTap: () {
            setState(() {
              isPwSecure = !isPwSecure;
            });
          },
        ),
      ],
    );
  }

  String _getPasswordContent() {
    String result = widget.password;
    if (isPwSecure) {
      for (var i = 0; i < result.length - 2; i++) {
        result = result.replaceRange(i, i + 1, '*');
      }
    }
    return result;
  }
}