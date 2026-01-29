import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/color_circle.dart';
import '../widgets/color_picker_dialog.dart';

class PaletteTab extends ConsumerWidget {
  const PaletteTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(demoThemeConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Seed Color (Base Palette)'),
        const SizedBox(height: 8),
        _buildSeedColorSelector(context, ref, config),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Advanced Overrides'),
        const SizedBox(height: 16),
        _buildColorOverrideRow(
          context: context,
          label: 'Primary',
          color: config.primary,
          onChanged: (c) =>
              ref.read(demoThemeConfigProvider.notifier).setPrimary(c),
        ),
        const SizedBox(height: 12),
        _buildColorOverrideRow(
          context: context,
          label: 'Secondary',
          color: config.secondary,
          onChanged: (c) =>
              ref.read(demoThemeConfigProvider.notifier).setSecondary(c),
        ),
        const SizedBox(height: 12),
        _buildColorOverrideRow(
          context: context,
          label: 'Tertiary',
          color: config.tertiary,
          onChanged: (c) =>
              ref.read(demoThemeConfigProvider.notifier).setTertiary(c),
        ),
        const SizedBox(height: 12),
        _buildColorOverrideRow(
          context: context,
          label: 'Surface',
          color: config.surface,
          onChanged: (c) =>
              ref.read(demoThemeConfigProvider.notifier).setSurface(c),
        ),
        const SizedBox(height: 12),
        _buildColorOverrideRow(
          context: context,
          label: 'Outline',
          color: config.outline,
          onChanged: (c) =>
              ref.read(demoThemeConfigProvider.notifier).setOutline(c),
        ),
        const SizedBox(height: 12),
        _buildColorOverrideRow(
          context: context,
          label: 'Error',
          color: config.error,
          onChanged: (c) =>
              ref.read(demoThemeConfigProvider.notifier).setError(c),
        ),
      ],
    );
  }

  Widget _buildSeedColorSelector(
      BuildContext context, WidgetRef ref, DemoThemeConfig config) {
    final presetColors = [
      const Color(0xFF0870EA), // Blue (default)
      const Color(0xFF8E08EA), // Purple
      const Color(0xFFE91E63), // Pink
      const Color(0xFFFF5722), // Deep Orange
      const Color(0xFFFF9800), // Orange
      const Color(0xFF4CAF50), // Green
      const Color(0xFF009688), // Teal
      const Color(0xFF607D8B), // Blue Grey
    ];

    final isCustom =
        config.seedColor != null && !presetColors.contains(config.seedColor);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ColorCircle(
          color: null,
          isSelected: config.seedColor == null,
          label: 'Default',
          onTap: () =>
              ref.read(demoThemeConfigProvider.notifier).setSeedColor(null),
        ),
        ...presetColors.map((color) {
          return ColorCircle(
            color: color,
            isSelected: config.seedColor == color,
            onTap: () =>
                ref.read(demoThemeConfigProvider.notifier).setSeedColor(color),
          );
        }),
        ColorCircle(
          key: const ValueKey('seed-custom'),
          color: isCustom ? config.seedColor : null,
          isSelected: isCustom,
          label: 'Custom',
          onTap: () => showColorPickerDialog(
            context: context,
            currentColor: config.seedColor ?? Colors.blue,
            onPick: (c) {
              ref.read(demoThemeConfigProvider.notifier).setSeedColor(c);
            },
          ),
          isCustomIcon: true,
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
