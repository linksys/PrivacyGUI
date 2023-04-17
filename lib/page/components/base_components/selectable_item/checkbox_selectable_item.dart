import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckboxSelectableItem extends ConsumerWidget {
  // TODO: Support right to left layout
  final String title;
  final bool isSelected;
  final double? weight;
  final double? height;

  const CheckboxSelectableItem({
    Key? key,
    required this.title,
    this.isSelected = false,
    this.weight,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 19),
      width: weight ?? double.infinity,
      height: height,
      child: Row(
        children: [
          checkBox(isSelected),
          const SizedBox(width: 10),
          Text(title),
          // const Spacer(),
        ],
      ),
    );
  }

  Widget checkBox(bool isSelected) {
    return isSelected
        ? const Icon(Icons.check_box_outlined)
        : const Icon(Icons.check_box_outline_blank);
  }
}
