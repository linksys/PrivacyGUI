import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/demo_theme_config_provider.dart';
import '../widgets/section_header.dart';

class DesignTab extends ConsumerWidget {
  const DesignTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(demoThemeConfigProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Visual Style'),
        const SizedBox(height: 8),
        _buildStyleSelector(context, ref, config),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Global Overlay'),
        const SizedBox(height: 8),
        _buildOverlaySelector(context, ref, config),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Visual Effects'),
        const SizedBox(height: 8),
        _buildVisualEffectsToggles(context, ref, config),
      ],
    );
  }

  Widget _buildStyleSelector(
      BuildContext context, WidgetRef ref, DemoThemeConfig config) {
    final styles = ['glass', 'aurora', 'brutal', 'flat', 'neumorphic', 'pixel'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((style) {
        return AppTag(
          label: style[0].toUpperCase() + style.substring(1),
          isSelected: config.style == style,
          onTap: () {
            ref.read(demoThemeConfigProvider.notifier).setStyle(style);
          },
        );
      }).toList(),
    );
  }

  Widget _buildOverlaySelector(
      BuildContext context, WidgetRef ref, DemoThemeConfig config) {
    final overlays = [
      (null, 'None'),
      (GlobalOverlayType.snow, 'Snow'),
      (GlobalOverlayType.hacker, 'Matrix'),
      (GlobalOverlayType.noiseOverlay, 'Noise'),
      (GlobalOverlayType.crtShader, 'CRT'),
      (GlobalOverlayType.auroraGlow, 'Aurora'),
      (GlobalOverlayType.liquid, 'Liquid'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: overlays.map((item) {
        final (overlay, label) = item;
        return AppTag(
          label: label,
          isSelected: config.globalOverlay == overlay,
          onTap: () {
            ref
                .read(demoThemeConfigProvider.notifier)
                .setGlobalOverlay(overlay);
          },
        );
      }).toList(),
    );
  }

  Widget _buildVisualEffectsToggles(
      BuildContext context, WidgetRef ref, DemoThemeConfig config) {
    final effects = [
      (AppThemeConfig.effectDirectionalShadow, 'Shadow'),
      (AppThemeConfig.effectGradientBorder, 'Gradient'),
      (AppThemeConfig.effectBlur, 'Blur'),
      (AppThemeConfig.effectNoiseTexture, 'Noise'),
      (AppThemeConfig.effectShimmer, 'Shimmer'),
      (AppThemeConfig.effectTopologyAnimation, 'Topology'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: effects.map((item) {
        final (flag, label) = item;
        final isEnabled = (config.visualEffects & flag) != 0;
        return AppTag(
          label: label,
          isSelected: isEnabled,
          onTap: () {
            ref.read(demoThemeConfigProvider.notifier).toggleVisualEffect(flag);
          },
        );
      }).toList(),
    );
  }
}
