import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/compact_color_picker.dart';

class ComponentsTab extends ConsumerWidget {
  const ComponentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(demoThemeConfigProvider);
    final components = config.overrides?.component;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Loader ---
        const SectionHeader(title: 'Loader Style'),
        const SizedBox(height: 16),

        // Circular Loaders
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelMedium('Circular Types'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LoaderType.values
                        .where((t) => t.isCircularType)
                        .map((type) {
                      final isSelected = components?.loader?.type == type;
                      return AppTag(
                        label: type.name.toUpperCase(),
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(demoThemeConfigProvider.notifier)
                              .updateLoaderColors(type: type);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Circular Preview
            Column(
              children: [
                AppText.bodySmall('Circular'),
                const SizedBox(height: 4),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: AppLoader(variant: LoaderVariant.circular),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Linear Loaders
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelMedium('Linear Types'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LoaderType.values
                        .where((t) => t.isLinearType)
                        .map((type) {
                      final isSelected = components?.loader?.type == type;
                      return AppTag(
                        label: type.name.toUpperCase(),
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(demoThemeConfigProvider.notifier)
                              .updateLoaderColors(type: type);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Linear Preview
            Column(
              children: [
                AppText.bodySmall('Linear'),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: AppLoader(variant: LoaderVariant.linear),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),
        // Loader Colors (Shared)
        Row(
          children: [
            CompactColorPicker(
              label: 'Primary',
              color: components?.loader?.primaryColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateLoaderColors(primaryColor: c),
            ),
            const SizedBox(width: 8),
            CompactColorPicker(
              label: 'Background',
              color: components?.loader?.backgroundColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateLoaderColors(backgroundColor: c),
            ),
          ],
        ),

        // --- Skeleton ---
        const SectionHeader(title: 'Skeleton Style'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SkeletonAnimationType.values.map((type) {
            final isSelected = components?.skeleton?.animationType == type;
            return AppTag(
              label: type.name.toUpperCase(),
              isSelected: isSelected,
              onTap: () {
                ref
                    .read(demoThemeConfigProvider.notifier)
                    .updateSkeletonColors(animationType: type);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CompactColorPicker(
              label: 'Base',
              color: components?.skeleton?.baseColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateSkeletonColors(baseColor: c),
            ),
            const SizedBox(width: 12),
            CompactColorPicker(
              label: 'Highlight',
              color: components?.skeleton?.highlightColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateSkeletonColors(highlightColor: c),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Live Preview
        AppCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              AppSkeleton(width: 120, height: 16),
              SizedBox(height: 8),
              AppSkeleton(width: double.infinity, height: 12),
              SizedBox(height: 4),
              AppSkeleton(width: 200, height: 12),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // --- Toggle ---
        const SectionHeader(title: 'Toggle Style'),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelSmall('Active'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CompactColorPicker(
                      label: 'Track',
                      color: components?.toggle?.activeTrackColor,
                      onChanged: (c) => ref
                          .read(demoThemeConfigProvider.notifier)
                          .updateToggleColors(activeTrackColor: c),
                    ),
                    const SizedBox(width: 8),
                    CompactColorPicker(
                      label: 'Thumb',
                      color: components?.toggle?.activeThumbColor,
                      onChanged: (c) => ref
                          .read(demoThemeConfigProvider.notifier)
                          .updateToggleColors(activeThumbColor: c),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.labelSmall('Inactive'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    CompactColorPicker(
                      label: 'Track',
                      color: components?.toggle?.inactiveTrackColor,
                      onChanged: (c) => ref
                          .read(demoThemeConfigProvider.notifier)
                          .updateToggleColors(inactiveTrackColor: c),
                    ),
                    const SizedBox(width: 8),
                    CompactColorPicker(
                      label: 'Thumb',
                      color: components?.toggle?.inactiveThumbColor,
                      onChanged: (c) => ref
                          .read(demoThemeConfigProvider.notifier)
                          .updateToggleColors(inactiveThumbColor: c),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            AppSwitch(value: true, onChanged: null),
            SizedBox(width: 16),
            AppSwitch(value: false, onChanged: null),
          ],
        ),
        const SizedBox(height: 24),

        // --- Toast ---
        const SectionHeader(title: 'Toast Style'),
        const SizedBox(height: 8),
        Row(
          children: [
            CompactColorPicker(
              label: 'Background',
              color: components?.toast?.backgroundColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateToastColors(backgroundColor: c),
            ),
            const SizedBox(width: 12),
            CompactColorPicker(
              label: 'Text',
              color: components?.toast?.textColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateToastColors(textColor: c),
            ),
            const SizedBox(width: 12),
            CompactColorPicker(
              label: 'Border',
              color: components?.toast?.borderColor,
              onChanged: (c) => ref
                  .read(demoThemeConfigProvider.notifier)
                  .updateToastColors(borderColor: c),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
