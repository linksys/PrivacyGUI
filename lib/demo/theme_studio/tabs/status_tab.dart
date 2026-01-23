import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/color_circle.dart';
import '../widgets/color_picker_dialog.dart';

class StatusTab extends ConsumerWidget {
  const StatusTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(demoThemeConfigProvider);
    final semantics = config.overrides?.semantic;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Status Colors'),
        const SizedBox(height: 16),
        _buildColorOverrideRow(
          context: context,
          label: 'Success',
          color: semantics?.success,
          onChanged: (c) => ref
              .read(demoThemeConfigProvider.notifier)
              .updateSemanticOverrides(success: c),
        ),
        const SizedBox(height: 12),
        _buildColorOverrideRow(
          context: context,
          label: 'Warning',
          color: semantics?.warning,
          onChanged: (c) => ref
              .read(demoThemeConfigProvider.notifier)
              .updateSemanticOverrides(warning: c),
        ),
        const SizedBox(height: 12),
        _buildColorOverrideRow(
          context: context,
          label: 'Danger',
          color: semantics?.error,
          onChanged: (c) => ref
              .read(demoThemeConfigProvider.notifier)
              .updateSemanticOverrides(danger: c),
        ),
        const SizedBox(height: 12),
        _buildColorOverrideRow(
          context: context,
          label: 'Info',
          color: semantics?.info,
          onChanged: (c) => ref
              .read(demoThemeConfigProvider.notifier)
              .updateSemanticOverrides(info: c),
        ),
      ],
    );
  }

  Widget _buildColorOverrideRow({
    required BuildContext context,
    required String label,
    required Color? color,
    required ValueChanged<Color?> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: AppText.labelMedium(label),
        ),
        ColorCircle(
          key: ValueKey('color-override-$label'),
          color: color,
          isSelected: true,
          showLabel: false,
          onTap: () => showColorPickerDialog(
            context: context,
            currentColor: color,
            onPick: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        if (color != null)
          AppIconButton.icon(
            icon: const Icon(Icons.close, size: 16),
            onTap: () => onChanged(null),
          ),
        if (color == null)
          AppText.bodySmall(
            'Default',
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
