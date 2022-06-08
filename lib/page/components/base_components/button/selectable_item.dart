import 'package:flutter/material.dart';

class SelectableItem extends StatelessWidget {
  final String text;
  final bool isSelected;
  final double height;

  const SelectableItem(
      {Key? key, required this.text, this.isSelected = false, this.height = 79})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      height: height,
      decoration: BoxDecoration(
          border: Border.all(
              color: isSelected
                  ? Theme
                  .of(context)
                  .colorScheme
                  .primary
                  : Theme
                  .of(context)
                  .colorScheme
                  .surface)),
      child: Row(
        children: [
          Text(
            text,
            style: Theme
                .of(context)
                .textTheme
                .headline4
                ?.copyWith(
                color: isSelected
                    ? Theme
                    .of(context)
                    .colorScheme
                    .primary
                    : Theme
                    .of(context)
                    .colorScheme
                    .surface),
          ),
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
}
