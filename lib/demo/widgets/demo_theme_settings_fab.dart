import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Provider for dynamic theme configuration in demo mode.
final demoThemeConfigProvider =
    StateNotifierProvider<DemoThemeConfigNotifier, DemoThemeConfig>((ref) {
  return DemoThemeConfigNotifier();
});

/// Demo theme configuration state.
class DemoThemeConfig {
  final String style;
  final GlobalOverlayType? globalOverlay;
  final int visualEffects;
  final Color? seedColor;

  const DemoThemeConfig({
    this.style = 'glass',
    this.globalOverlay,
    this.visualEffects = AppThemeConfig.effectAll,
    this.seedColor,
  });

  DemoThemeConfig copyWith({
    String? style,
    GlobalOverlayType? globalOverlay,
    bool clearOverlay = false,
    int? visualEffects,
    Color? seedColor,
    bool clearSeedColor = false,
  }) {
    return DemoThemeConfig(
      style: style ?? this.style,
      globalOverlay:
          clearOverlay ? null : (globalOverlay ?? this.globalOverlay),
      visualEffects: visualEffects ?? this.visualEffects,
      seedColor: clearSeedColor ? null : (seedColor ?? this.seedColor),
    );
  }
}

/// Notifier for demo theme configuration.
class DemoThemeConfigNotifier extends StateNotifier<DemoThemeConfig> {
  DemoThemeConfigNotifier() : super(const DemoThemeConfig());

  void setStyle(String style) {
    state = state.copyWith(style: style);
  }

  void setGlobalOverlay(GlobalOverlayType? overlay) {
    if (overlay == null) {
      state = state.copyWith(clearOverlay: true);
    } else {
      state = state.copyWith(globalOverlay: overlay);
    }
  }

  void setVisualEffects(int effects) {
    state = state.copyWith(visualEffects: effects);
  }

  void toggleVisualEffect(int flag) {
    final current = state.visualEffects;
    final newEffects = (current & flag) != 0
        ? current & ~flag // Remove flag
        : current | flag; // Add flag
    state = state.copyWith(visualEffects: newEffects);
  }

  void setSeedColor(Color? color) {
    if (color == null) {
      state = state.copyWith(clearSeedColor: true);
    } else {
      state = state.copyWith(seedColor: color);
    }
  }
}

/// A floating action button for theme settings in demo mode.
class DemoThemeSettingsFab extends ConsumerStatefulWidget {
  const DemoThemeSettingsFab({super.key});

  @override
  ConsumerState<DemoThemeSettingsFab> createState() =>
      _DemoThemeSettingsFabState();
}

class _DemoThemeSettingsFabState extends ConsumerState<DemoThemeSettingsFab> {
  bool _isExpanded = false;

  // Preset color palette
  static const List<Color> _presetColors = [
    Color(0xFF0870EA), // Blue (default)
    Color(0xFF8E08EA), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFFFF5722), // Deep Orange
    Color(0xFFFF9800), // Orange
    Color(0xFF4CAF50), // Green
    Color(0xFF009688), // Teal
    Color(0xFF00BCD4), // Cyan
    Color(0xFF3F51B5), // Indigo
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
    Color(0xFF9E9E9E), // Grey
  ];

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(demoThemeConfigProvider);

    return AppDraggable(
      initialPosition: Alignment.bottomRight,
      enableSnapping: true,
      padding: const EdgeInsets.all(16.0),
      builder: (context, isDragging, alignment) {
        // Adapt layout based on side (Left aligned -> Panel starts at left)
        final isLeft = alignment.x < 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            // Expanded menu
            if (_isExpanded) ...[
              _buildSettingsPanel(context, config),
              const SizedBox(height: 8),
            ],
            // Main FAB
            AppIconButton.primary(
              icon: AppIcon.font(
                _isExpanded ? AppFontIcons.close : AppFontIcons.widgets,
              ),
              onTap: () => setState(() => _isExpanded = !_isExpanded),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsPanel(BuildContext context, DemoThemeConfig config) {
    return SizedBox(
      width: 300,
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const AppText(
                'Theme Settings',
                variant: AppTextVariant.titleMedium,
                fontWeight: FontWeight.bold,
              ),
              const SizedBox(height: 12),
              const AppDivider(),
              const SizedBox(height: 12),

              // Seed Color selector
              AppText.labelMedium('Seed Color'),
              const SizedBox(height: 8),
              _buildSeedColorSelector(context, config),
              const SizedBox(height: 16),

              // Style selector
              AppText.labelMedium('Style'),
              const SizedBox(height: 8),
              _buildStyleSelector(context, config),
              const SizedBox(height: 16),

              // Global Overlay selector
              AppText.labelMedium('Global Overlay'),
              const SizedBox(height: 8),
              _buildOverlaySelector(context, config),
              const SizedBox(height: 16),

              // Visual Effects toggles
              AppText.labelMedium('Visual Effects'),
              const SizedBox(height: 8),
              _buildVisualEffectsToggles(context, config),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeedColorSelector(BuildContext context, DemoThemeConfig config) {
    final currentColor = config.seedColor;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Default option (use JSON config)
        _ColorCircle(
          color: null,
          isSelected: currentColor == null,
          label: 'Default',
          onTap: () {
            ref.read(demoThemeConfigProvider.notifier).setSeedColor(null);
          },
        ),
        // Preset colors
        ..._presetColors.map((color) {
          return _ColorCircle(
            color: color,
            isSelected: currentColor?.toARGB32() == color.toARGB32(),
            onTap: () {
              ref.read(demoThemeConfigProvider.notifier).setSeedColor(color);
            },
          );
        }),
      ],
    );
  }

  Widget _buildStyleSelector(BuildContext context, DemoThemeConfig config) {
    final styles = ['glass', 'aurora', 'brutal', 'flat', 'neumorphic', 'pixel'];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: styles.map((style) {
        final isSelected = config.style == style;
        return AppTag(
          label: style[0].toUpperCase() + style.substring(1),
          isSelected: isSelected,
          onTap: () {
            ref.read(demoThemeConfigProvider.notifier).setStyle(style);
          },
        );
      }).toList(),
    );
  }

  Widget _buildOverlaySelector(BuildContext context, DemoThemeConfig config) {
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
      spacing: 6,
      runSpacing: 6,
      children: overlays.map((item) {
        final (overlay, label) = item;
        final isSelected = config.globalOverlay == overlay;
        return AppTag(
          label: label,
          isSelected: isSelected,
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
      BuildContext context, DemoThemeConfig config) {
    // Use actual effect constants from AppThemeConfig
    final effects = [
      (AppThemeConfig.effectDirectionalShadow, 'Shadow'),
      (AppThemeConfig.effectGradientBorder, 'Gradient'),
      (AppThemeConfig.effectBlur, 'Blur'),
      (AppThemeConfig.effectNoiseTexture, 'Noise'),
      (AppThemeConfig.effectShimmer, 'Shimmer'),
      (AppThemeConfig.effectTopologyAnimation, 'Topology'),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
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

/// A circular color selector widget.
class _ColorCircle extends StatelessWidget {
  final Color? color;
  final bool isSelected;
  final String? label;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    const size = 28.0;
    final isDefault = color == null;
    final colorScheme = Theme.of(context).colorScheme;

    // Calculate effective styles based on selection state
    final borderColor = isSelected
        ? colorScheme.primary
        : (isDefault ? colorScheme.outline : color!.withValues(alpha: 0.5));

    final borderWidth = isSelected ? 3.0 : 1.0;

    return AppInteractionSensor(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDefault ? Colors.transparent : color,
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
        ),
        child: isDefault
            ? Center(
                child: AppIcon.font(
                  Icons.auto_fix_high,
                  size: 14,
                  color: colorScheme.outline,
                ),
              )
            : null,
      ),
    );
  }
}
