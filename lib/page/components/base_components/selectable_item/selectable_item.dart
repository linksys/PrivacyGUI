import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class SelectableItem extends ConsumerWidget {
  final String text;
  final bool isSelected;
  final double? height;

  const SelectableItem(
      {Key? key, required this.text, this.isSelected = false, this.height})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      height: height,
      decoration: BoxDecoration(
          border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface)),
      child: Row(
        children: [
          message(context),
          const Spacer(),
          Container(
            child: isSelected
                ? Image.asset('assets/images/icon_check_white.png')
                : null,
          ),
        ],
      ),
    );
  }

  Widget message(BuildContext context) {
    List<Widget> children = [];
    children.add(LinksysText.label(
      text,
      color: isSelected
          ? AppTheme.of(context).colors.ctaPrimary
          : AppTheme.of(context).colors.tertiaryText,
    ));

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
