import 'package:flutter/material.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class LightInfoImageTile extends StatelessWidget {
  final Widget image;
  final Widget content;

  const LightInfoImageTile({
    super.key,
    required this.image,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return _createLightInfoTile(context, image, content);
  }

  Widget _createLightInfoTile(
      BuildContext context, Widget image, Widget content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        const AppGap.medium(),
        Flexible(
          child: content,
        )
      ],
    );
  }
}


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
        const AppGap.medium(),
        Flexible(
          child: content,
        )
      ],
    );
  }

  Widget _createLightCircle(BuildContext context, Color color) {
    return Semantics(
      label: 'light circle',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                width: 3, color: Theme.of(context).colorScheme.outline)),
      ),
    );
  }
}
