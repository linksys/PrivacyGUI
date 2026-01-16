import 'dart:convert';
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

  // Granular Material Colors (Standard Layer)
  final Color? primary;
  final Color? secondary;
  final Color? tertiary;
  final Color? outline;
  final Color? surface;
  final Color? error;

  // Advanced Overrides (Semantic & Component Layer)
  final AppThemeOverrides? overrides;

  const DemoThemeConfig({
    this.style = 'glass',
    this.globalOverlay,
    this.visualEffects = AppThemeConfig.effectAll,
    this.seedColor,
    this.primary,
    this.secondary,
    this.tertiary,
    this.outline,
    this.surface,
    this.error,
    this.overrides,
  });

  /// Creates a copy of this config with the given fields replaced.
  DemoThemeConfig copyWith({
    String? style,
    GlobalOverlayType? globalOverlay,
    bool clearOverlay = false,
    int? visualEffects,
    Color? seedColor,
    bool clearSeedColor = false,
    Color? primary,
    bool clearPrimary = false,
    Color? secondary,
    bool clearSecondary = false,
    Color? tertiary,
    bool clearTertiary = false,
    Color? outline,
    bool clearOutline = false,
    Color? surface,
    bool clearSurface = false,
    Color? error,
    bool clearError = false,
    AppThemeOverrides? overrides,
    bool clearOverrides = false,
  }) {
    return DemoThemeConfig(
      style: style ?? this.style,
      globalOverlay:
          clearOverlay ? null : (globalOverlay ?? this.globalOverlay),
      visualEffects: visualEffects ?? this.visualEffects,
      seedColor: clearSeedColor ? null : (seedColor ?? this.seedColor),
      primary: clearPrimary ? null : (primary ?? this.primary),
      secondary: clearSecondary ? null : (secondary ?? this.secondary),
      tertiary: clearTertiary ? null : (tertiary ?? this.tertiary),
      outline: clearOutline ? null : (outline ?? this.outline),
      surface: clearSurface ? null : (surface ?? this.surface),
      error: clearError ? null : (error ?? this.error),
      overrides: clearOverrides ? null : (overrides ?? this.overrides),
    );
  }

  /// Serialize to JSON for export
  Map<String, dynamic> toJson() {
    String? colorToHex(Color? color) {
      if (color == null) return null;
      return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
    }

    return {
      'style': style,
      'globalOverlay': globalOverlay?.name,
      'visualEffects': visualEffects,
      'seedColor': colorToHex(seedColor),
      'primary': colorToHex(primary),
      'secondary': colorToHex(secondary),
      'tertiary': colorToHex(tertiary),
      'outline': colorToHex(outline),
      'surface': colorToHex(surface),
      'error': colorToHex(error),
      'overrides': overrides?.toJson(),
    };
  }

  /// deserialize from JSON for import
  factory DemoThemeConfig.fromJson(Map<String, dynamic> json) {
    Color? parseHex(dynamic value) {
      if (value is String) {
        try {
          final hex = value.replaceAll('#', '');
          if (hex.length == 6) {
            return Color(int.parse('FF$hex', radix: 16));
          } else if (hex.length == 8) {
            return Color(int.parse(hex, radix: 16));
          }
        } catch (_) {}
      }
      return null;
    }

    // Parse overrides using UI Kit's native structure logic would be ideal,
    // but AppThemeConfig.fromJson logic is internal.
    // We can reconstruct AppThemeOverrides manually or depend on its fromJson.
    // Checking AppThemeOverrides.fromJson... it exists in UI Kit.
    // We need to parse the map carefully.
    AppThemeOverrides? parsedOverrides;
    if (json['overrides'] is Map<String, dynamic>) {
      final ovJson = json['overrides'] as Map<String, dynamic>;
      // Reconstruct sub-objects (assuming UI Kit classes have fromJson or we use helper)
      // Actually standard usage allows AppThemeOverrides.fromJson(ovJson)
      try {
        parsedOverrides = AppThemeOverrides.fromJson(ovJson);
      } catch (_) {
        // Fallback manual parsing if needed, but lets rely on standard
        final semanticJson = ovJson['semantic'] as Map<String, dynamic>?;
        final paletteJson = ovJson['palette'] as Map<String, dynamic>?;
        final surfaceJson = ovJson['surface'] as Map<String, dynamic>?;
        final componentJson = ovJson['component'] as Map<String, dynamic>?;

        parsedOverrides = AppThemeOverrides(
          semantic: semanticJson != null
              ? SemanticOverrides.fromJson(semanticJson)
              : null,
          palette: paletteJson != null
              ? PaletteColorOverride.fromJson(paletteJson)
              : null,
          surface: surfaceJson != null
              ? SurfaceOverrides.fromJson(surfaceJson)
              : null,
          component: componentJson != null
              ? ComponentOverrides.fromJson(componentJson)
              : null,
        );
      }
    }

    return DemoThemeConfig(
      style: json['style'] as String? ?? 'glass',
      globalOverlay: json['globalOverlay'] != null
          ? GlobalOverlayType.values.firstWhere(
              (e) => e.name == json['globalOverlay'],
              orElse: () => GlobalOverlayType.none,
            )
          : null,
      visualEffects: json['visualEffects'] as int? ?? AppThemeConfig.effectAll,
      seedColor: parseHex(json['seedColor']),
      primary: parseHex(json['primary']),
      secondary: parseHex(json['secondary']),
      tertiary: parseHex(json['tertiary']),
      outline: parseHex(json['outline']),
      surface: parseHex(json['surface']),
      error: parseHex(json['error']),
      overrides: parsedOverrides,
    );
  }
}

/// Notifier for demo theme configuration.
class DemoThemeConfigNotifier extends StateNotifier<DemoThemeConfig> {
  DemoThemeConfigNotifier() : super(const DemoThemeConfig());

  // === Import / Export ===

  void importConfig(Map<String, dynamic> json) {
    try {
      state = DemoThemeConfig.fromJson(json);
    } catch (e) {
      debugPrint('Error importing theme config: $e');
      // In a real app we might want to throw or return false
    }
  }

  void importConfigString(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr);
      importConfig(json);
    } catch (e) {
      debugPrint('Error parsing theme config json: $e');
    }
  }

  void reset() {
    state = const DemoThemeConfig();
  }

  // === Basic ===

  void setStyle(String style) {
    state = state.copyWith(style: style);
  }

  void setGlobalOverlay(GlobalOverlayType? overlay) {
    state = state.copyWith(
      globalOverlay: overlay,
      clearOverlay: overlay == null,
    );
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
    state = state.copyWith(
      seedColor: color,
      clearSeedColor: color == null,
    );
  }

  // === Granular Colors ===

  void setPrimary(Color? color) {
    state = state.copyWith(
      primary: color,
      clearPrimary: color == null,
    );
  }

  void setSecondary(Color? color) {
    state = state.copyWith(
      secondary: color,
      clearSecondary: color == null,
    );
  }

  void setTertiary(Color? color) {
    state = state.copyWith(
      tertiary: color,
      clearTertiary: color == null,
    );
  }

  void setOutline(Color? color) {
    state = state.copyWith(
      outline: color,
      clearOutline: color == null,
    );
  }

  void setSurface(Color? color) {
    state = state.copyWith(
      surface: color,
      clearSurface: color == null,
    );
  }

  void setError(Color? color) {
    state = state.copyWith(
      error: color,
      clearError: color == null,
    );
  }

  // === Semantics ===

  void updateSemanticOverrides({
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
  }) {
    final currentSemantics = state.overrides?.semantic;
    final newSemantics = SemanticOverrides(
      success: success ?? currentSemantics?.success,
      warning: warning ?? currentSemantics?.warning,
      error: danger ?? currentSemantics?.error,
      info: info ?? currentSemantics?.info,
    );

    state = state.copyWith(
      overrides: AppThemeOverrides(
        semantic: newSemantics,
        palette: state.overrides?.palette,
        surface: state.overrides?.surface,
        component: state.overrides?.component,
      ),
    );
  }

  // === Component Overrides ===

  void updateLoaderColors({
    Color? primaryColor,
    Color? backgroundColor,
    LoaderType? type,
  }) {
    final current = state.overrides?.component?.loader;
    final newLoader = LoaderColorOverride(
      type: type ?? current?.type,
      primaryColor: primaryColor ?? current?.primaryColor,
      backgroundColor: backgroundColor ?? current?.backgroundColor,
    );
    _updateComponent((c) => ComponentOverrides(
          loader: newLoader,
          skeleton: c?.skeleton,
          topology: c?.topology,
          toggle: c?.toggle,
          toast: c?.toast,
          input: c?.input,
          button: c?.button,
          dialog: c?.dialog,
          navigation: c?.navigation,
          tabs: c?.tabs,
          menu: c?.menu,
          appBar: c?.appBar,
          stepper: c?.stepper,
          breadcrumb: c?.breadcrumb,
          chipGroup: c?.chipGroup,
          carousel: c?.carousel,
          expansionPanel: c?.expansionPanel,
          table: c?.table,
          slideAction: c?.slideAction,
          sheet: c?.sheet,
          badge: c?.badge,
          avatar: c?.avatar,
          card: c?.card,
          divider: c?.divider,
          pinInput: c?.pinInput,
          passwordInput: c?.passwordInput,
          rangeInput: c?.rangeInput,
          styledText: c?.styledText,
          bottomBar: c?.bottomBar,
          pageMenu: c?.pageMenu,
        ));
  }

  void updateSkeletonColors({
    Color? baseColor,
    Color? highlightColor,
    SkeletonAnimationType? animationType,
  }) {
    final current = state.overrides?.component?.skeleton;
    final newSkeleton = SkeletonColorOverride(
      animationType: animationType ?? current?.animationType,
      baseColor: baseColor ?? current?.baseColor,
      highlightColor: highlightColor ?? current?.highlightColor,
    );
    _updateComponent((c) => ComponentOverrides(
          skeleton: newSkeleton,
          loader: c?.loader,
          topology: c?.topology,
          toggle: c?.toggle,
          toast: c?.toast,
          input: c?.input,
          button: c?.button,
          dialog: c?.dialog,
          navigation: c?.navigation,
          tabs: c?.tabs,
          menu: c?.menu,
          appBar: c?.appBar,
          stepper: c?.stepper,
          breadcrumb: c?.breadcrumb,
          chipGroup: c?.chipGroup,
          carousel: c?.carousel,
          expansionPanel: c?.expansionPanel,
          table: c?.table,
          slideAction: c?.slideAction,
          sheet: c?.sheet,
          badge: c?.badge,
          avatar: c?.avatar,
          card: c?.card,
          divider: c?.divider,
          pinInput: c?.pinInput,
          passwordInput: c?.passwordInput,
          rangeInput: c?.rangeInput,
          styledText: c?.styledText,
          bottomBar: c?.bottomBar,
          pageMenu: c?.pageMenu,
        ));
  }

  void updateToggleColors({
    Color? activeTrackColor,
    Color? activeThumbColor,
    Color? inactiveTrackColor,
    Color? inactiveThumbColor,
  }) {
    final current = state.overrides?.component?.toggle;
    final newToggle = ToggleColorOverride(
      activeTrackColor: activeTrackColor ?? current?.activeTrackColor,
      activeThumbColor: activeThumbColor ?? current?.activeThumbColor,
      inactiveTrackColor: inactiveTrackColor ?? current?.inactiveTrackColor,
      inactiveThumbColor: inactiveThumbColor ?? current?.inactiveThumbColor,
    );
    _updateComponent((c) => ComponentOverrides(
          toggle: newToggle,
          loader: c?.loader,
          skeleton: c?.skeleton,
          topology: c?.topology,
          toast: c?.toast,
          input: c?.input,
          button: c?.button,
          dialog: c?.dialog,
          navigation: c?.navigation,
          tabs: c?.tabs,
          menu: c?.menu,
          appBar: c?.appBar,
          stepper: c?.stepper,
          breadcrumb: c?.breadcrumb,
          chipGroup: c?.chipGroup,
          carousel: c?.carousel,
          expansionPanel: c?.expansionPanel,
          table: c?.table,
          slideAction: c?.slideAction,
          sheet: c?.sheet,
          badge: c?.badge,
          avatar: c?.avatar,
          card: c?.card,
          divider: c?.divider,
          pinInput: c?.pinInput,
          passwordInput: c?.passwordInput,
          rangeInput: c?.rangeInput,
          styledText: c?.styledText,
          bottomBar: c?.bottomBar,
          pageMenu: c?.pageMenu,
        ));
  }

  void updateToastColors({
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
  }) {
    final current = state.overrides?.component?.toast;
    final newToast = ToastColorOverride(
      backgroundColor: backgroundColor ?? current?.backgroundColor,
      textColor: textColor ?? current?.textColor,
      borderColor: borderColor ?? current?.borderColor,
    );
    _updateComponent((c) => ComponentOverrides(
          toast: newToast,
          loader: c?.loader,
          skeleton: c?.skeleton,
          topology: c?.topology,
          toggle: c?.toggle,
          input: c?.input,
          button: c?.button,
          dialog: c?.dialog,
          navigation: c?.navigation,
          tabs: c?.tabs,
          menu: c?.menu,
          appBar: c?.appBar,
          stepper: c?.stepper,
          breadcrumb: c?.breadcrumb,
          chipGroup: c?.chipGroup,
          carousel: c?.carousel,
          expansionPanel: c?.expansionPanel,
          table: c?.table,
          slideAction: c?.slideAction,
          sheet: c?.sheet,
          badge: c?.badge,
          avatar: c?.avatar,
          card: c?.card,
          divider: c?.divider,
          pinInput: c?.pinInput,
          passwordInput: c?.passwordInput,
          rangeInput: c?.rangeInput,
          styledText: c?.styledText,
          bottomBar: c?.bottomBar,
          pageMenu: c?.pageMenu,
        ));
  }

  void updateTopologyColors({
    Color? gatewayNormalBackgroundColor,
    Color? gatewayNormalBorderColor,
    Color? gatewayNormalIconColor,
    Color? gatewayNormalGlowColor,
    Color? extenderNormalBackgroundColor,
    Color? extenderNormalBorderColor,
    Color? extenderNormalIconColor,
    Color? extenderNormalGlowColor,
    Color? clientNormalBackgroundColor,
    Color? clientNormalBorderColor,
    Color? clientNormalIconColor,
    Color? clientNormalGlowColor,
    Color? ethernetLinkColor,
    Color? wifiStrongColor,
    Color? wifiMediumColor,
    Color? wifiWeakColor,
    LinkAnimationType? ethernetAnimationType,
    LinkAnimationType? wifiAnimationType,
    MeshNodeRendererType? gatewayRenderer,
    MeshNodeRendererType? extenderRenderer,
    MeshNodeRendererType? clientRenderer,
  }) {
    final current = state.overrides?.component?.topology;
    final newTopology = TopologyColorOverride(
      gatewayRenderer: gatewayRenderer ?? current?.gatewayRenderer,
      extenderRenderer: extenderRenderer ?? current?.extenderRenderer,
      clientRenderer: clientRenderer ?? current?.clientRenderer,
      gatewayNormalBackgroundColor:
          gatewayNormalBackgroundColor ?? current?.gatewayNormalBackgroundColor,
      gatewayNormalBorderColor:
          gatewayNormalBorderColor ?? current?.gatewayNormalBorderColor,
      gatewayNormalIconColor:
          gatewayNormalIconColor ?? current?.gatewayNormalIconColor,
      gatewayNormalGlowColor:
          gatewayNormalGlowColor ?? current?.gatewayNormalGlowColor,
      extenderNormalBackgroundColor: extenderNormalBackgroundColor ??
          current?.extenderNormalBackgroundColor,
      extenderNormalBorderColor:
          extenderNormalBorderColor ?? current?.extenderNormalBorderColor,
      extenderNormalIconColor:
          extenderNormalIconColor ?? current?.extenderNormalIconColor,
      extenderNormalGlowColor:
          extenderNormalGlowColor ?? current?.extenderNormalGlowColor,
      clientNormalBackgroundColor:
          clientNormalBackgroundColor ?? current?.clientNormalBackgroundColor,
      clientNormalBorderColor:
          clientNormalBorderColor ?? current?.clientNormalBorderColor,
      clientNormalIconColor:
          clientNormalIconColor ?? current?.clientNormalIconColor,
      clientNormalGlowColor:
          clientNormalGlowColor ?? current?.clientNormalGlowColor,
      ethernetLinkColor: ethernetLinkColor ?? current?.ethernetLinkColor,
      wifiStrongColor: wifiStrongColor ?? current?.wifiStrongColor,
      wifiMediumColor: wifiMediumColor ?? current?.wifiMediumColor,
      wifiWeakColor: wifiWeakColor ?? current?.wifiWeakColor,
      ethernetAnimationType:
          ethernetAnimationType ?? current?.ethernetAnimationType,
      wifiAnimationType: wifiAnimationType ?? current?.wifiAnimationType,
    );
    _updateComponent((c) => ComponentOverrides(
          topology: newTopology,
          loader: c?.loader,
          skeleton: c?.skeleton,
          toggle: c?.toggle,
          toast: c?.toast,
          input: c?.input,
          button: c?.button,
          dialog: c?.dialog,
          navigation: c?.navigation,
          tabs: c?.tabs,
          menu: c?.menu,
          appBar: c?.appBar,
          stepper: c?.stepper,
          breadcrumb: c?.breadcrumb,
          chipGroup: c?.chipGroup,
          carousel: c?.carousel,
          expansionPanel: c?.expansionPanel,
          table: c?.table,
          slideAction: c?.slideAction,
          sheet: c?.sheet,
          badge: c?.badge,
          avatar: c?.avatar,
          card: c?.card,
          divider: c?.divider,
          pinInput: c?.pinInput,
          passwordInput: c?.passwordInput,
          rangeInput: c?.rangeInput,
          styledText: c?.styledText,
          bottomBar: c?.bottomBar,
          pageMenu: c?.pageMenu,
        ));
  }

  void _updateComponent(
      ComponentOverrides Function(ComponentOverrides? current) builder) {
    state = state.copyWith(
      overrides: AppThemeOverrides(
        semantic: state.overrides?.semantic,
        palette: state.overrides?.palette,
        surface: state.overrides?.surface,
        component: builder(state.overrides?.component),
      ),
    );
  }
}
