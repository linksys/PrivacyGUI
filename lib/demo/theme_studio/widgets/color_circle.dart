import 'package:flutter/material.dart';
import 'package:ui_kit_library/ui_kit.dart';

class ColorCircle extends StatelessWidget {
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;
  final bool showLabel;
  final bool isCustomIcon;

  const ColorCircle({
    super.key,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.label,
    this.showLabel = true,
    this.isCustomIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color ?? Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isCustomIcon
                ? Icon(Icons.add,
                    color: Theme.of(context).colorScheme.onSurface)
                : (color == null
                    ? Icon(Icons.colorize,
                        size: 20, color: Colors.grey.withValues(alpha: 0.5))
                    : null),
          ),
          if (showLabel && label != null) ...[
            const SizedBox(height: 4),
            AppText.bodySmall(label!),
          ],
        ],
      ),
    );
  }
}
