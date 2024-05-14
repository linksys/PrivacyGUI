import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class LightInfoTile extends StatelessWidget {
  final Color color;
  final Widget content;
  const LightInfoTile({
    super.key,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return _createLightInfoTile(context, color, content);
  }

  Widget _createLightInfoTile(
      BuildContext context, Color color, Widget content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _createLightCircle(context, color),
        const AppGap.regular(),
        Flexible(
          child: content,
        )
      ],
    );
  }

  Widget _createLightCircle(BuildContext context, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              width: 3, color: Theme.of(context).colorScheme.outline)),
    );
  }
}
