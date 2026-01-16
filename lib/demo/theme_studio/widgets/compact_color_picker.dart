import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'color_picker_dialog.dart';

class CompactColorPicker extends StatelessWidget {
  final String label;
  final Color? color;
  final ValueChanged<Color> onChanged;

  const CompactColorPicker({
    super.key,
    required this.label,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showColorPickerDialog(
          context: context,
          currentColor: color,
          onPick: onChanged,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color ?? Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: color == null ? const Icon(Icons.colorize, size: 14) : null,
          ),
          const SizedBox(width: 8),
          AppText.bodySmall(label),
        ],
      ),
    );
  }
}
