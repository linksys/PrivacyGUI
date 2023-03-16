import 'package:flutter/material.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class HiddenPasswordWidget extends StatefulWidget {
  final String password;
  const HiddenPasswordWidget({Key? key, required this.password})
      : super(key: key);

  @override
  State<HiddenPasswordWidget> createState() => _HiddenPasswordWidgetState();
}

class _HiddenPasswordWidgetState extends State<HiddenPasswordWidget> {
  bool isPwSecure = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LinksysText.descriptionSub(
          _getPasswordContent(),
        ),
        const LinksysGap.semiSmall(),
        AppIconButton(
          icon: isPwSecure
              ? getCharactersIcons(context).showDefault
              : getCharactersIcons(context).hideDefault,
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
