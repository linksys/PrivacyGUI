import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/demo/providers/theme_studio_config_provider.dart';
import 'package:privacy_gui/providers/theme_config_provider.dart';
import '../widgets/section_header.dart';

class DesignTab extends ConsumerWidget {
  const DesignTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(themeStudioConfigProvider);

    // Base theme (device / THEME_JSON) — used as the display fallback when the
    // studio config still inherits (style / visualEffects are null).
    final baseJson =
        ref.watch(themeConfigProvider).valueOrNull?.lightJson ?? const {};
    final baseStyle = baseJson['style'] as String?;
    final baseVisualEffects = baseJson['visualEffects'] as int?;

    // Effective values shown in the panel: explicit studio value if set,
    // otherwise the inherited base value.
    final effectiveStyle = config.style ?? baseStyle;
    final effectiveVisualEffects =
        config.visualEffects ?? baseVisualEffects ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Visual Style'),
        const SizedBox(height: 8),
        _buildStyleSelector(context, ref, effectiveStyle),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Global Overlay'),
        const SizedBox(height: 8),
        _buildOverlaySelector(context, ref, config),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Visual Effects'),
        const SizedBox(height: 8),
        _buildVisualEffectsToggles(context, ref, effectiveVisualEffects),
      ],
    );
  }

  Widget _buildStyleSelector(
      BuildContext context, WidgetRef ref, String? effectiveStyle) {
    final styles = [
      'glass',
      'aurora',
      'brutal',
      'flat',
      'neumorphic',
      'pixel',
      'claymorphism',
      'layered_elevation',
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styles.map((style) {
        return AppTag(
          label: _formatStyleLabel(style),
          isSelected: effectiveStyle == style,
          onTap: () {
            ref.read(themeStudioConfigProvider.notifier).setStyle(style);
          },
        );
      }).toList(),
    );
  }

  String _formatStyleLabel(String style) {
    return style
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildOverlaySelector(
      BuildContext context, WidgetRef ref, ThemeStudioConfig config) {
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
                .read(themeStudioConfigProvider.notifier)
                .setGlobalOverlay(overlay);
          },
        );
      }).toList(),
    );
  }

  Widget _buildVisualEffectsToggles(
      BuildContext context, WidgetRef ref, int effectiveVisualEffects) {
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
        final isEnabled = (effectiveVisualEffects & flag) != 0;
        return AppTag(
          label: label,
          isSelected: isEnabled,
          onTap: () {
            ref
                .read(themeStudioConfigProvider.notifier)
                .toggleVisualEffect(flag);
          },
        );
      }).toList(),
    );
  }
}
