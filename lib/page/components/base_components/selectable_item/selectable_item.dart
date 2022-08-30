import 'package:flutter/material.dart';

class SelectableItem extends StatelessWidget {
  final String text;
  final String? description;
  final bool isSelected;
  final double? height;

  const SelectableItem(
      {Key? key,
      required this.text,
      this.isSelected = false,
      this.height,
      this.description})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
    children.add(Text(
      text,
      style: Theme.of(context).textTheme.headline4?.copyWith(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface),
    ));

    if (description != null) {
      children.add(const SizedBox(height: 4,));
      children.add(Text(
        description!,
        // TODO: check text size
        style: Theme.of(context).textTheme.headline4?.copyWith(
            color: Theme.of(context).colorScheme.surface),
      ));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
