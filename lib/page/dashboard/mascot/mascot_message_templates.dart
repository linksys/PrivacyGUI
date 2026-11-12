import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Message category for mascot random speech.
enum MascotMessageCategory {
  /// Feature guidance - tells users where to find functionality
  guidance,

  /// System status - dynamic messages based on current state
  status,

  /// Network tips - security and knowledge sharing
  tips,
}

/// Context data for generating dynamic messages.
///
/// Populated from L1 dashboard providers when generating status messages.
class MascotMessageContext {
  final int? cpuPercent;
  final int? memoryPercent;
  final String? uptime;
  final int? onlineDeviceCount;
  final int? totalDeviceCount;
  final int? meshNodeCount;
  final bool? wanConnected;
  final String? wanIp;
  final int? enabledRadioCount;
  final int? totalRadioCount;

  const MascotMessageContext({
    this.cpuPercent,
    this.memoryPercent,
    this.uptime,
    this.onlineDeviceCount,
    this.totalDeviceCount,
    this.meshNodeCount,
    this.wanConnected,
    this.wanIp,
    this.enabledRadioCount,
    this.totalRadioCount,
  });

  const MascotMessageContext.empty() : this();
}

/// A message template that can generate dynamic text.
///
/// [builder] is handed the strings for the app's locale, so a bubble is in the
/// user's language (#1312).
class MascotMessageTemplate {
  final String id;
  final MascotMessageCategory category;
  final String Function(MascotMessageContext ctx, AppLocalizations l10n)
      builder;
  final bool Function(MascotMessageContext ctx)? condition;
  final MascotAnimationKey? suggestedAnimation;

  const MascotMessageTemplate({
    required this.id,
    required this.category,
    required this.builder,
    this.condition,
    this.suggestedAnimation,
  });

  /// Check if this template should be used given the context.
  bool shouldShow(MascotMessageContext ctx) {
    return condition == null || condition!(ctx);
  }

  /// Generate the message text from context, in [l10n]'s language.
  String generate(MascotMessageContext ctx, AppLocalizations l10n) =>
      builder(ctx, l10n);
}

/// Generated message ready for display.
class MascotMessage {
  final String text;
  final MascotMessageCategory category;
  final MascotAnimationKey? suggestedAnimation;

  const MascotMessage({
    required this.text,
    required this.category,
    this.suggestedAnimation,
  });

  /// What the mascot says before the dashboard has loaded.
  static MascotMessage fallback(AppLocalizations l10n) => MascotMessage(
        text: l10n.mascotTipHere,
        category: MascotMessageCategory.tips,
      );
}

/// Category weight distribution for random selection.
const categoryWeights = <MascotMessageCategory, int>{
  MascotMessageCategory.status: 50,
  MascotMessageCategory.tips: 30,
  MascotMessageCategory.guidance: 20,
};

// =============================================================================
// GUIDANCE TEMPLATES (Static)
// =============================================================================

/// Tips that tell the user where something is.
///
/// Every name in them is the app's own key for that menu, page or card, so a
/// tip names what the user actually sees, in their language. Each one also
/// points where the thing really is: Firewall is under Advanced Settings, not
/// in the sidebar, and firmware is the OTA Update card on the Administration
/// page (#1312).
final guidanceTemplates = <MascotMessageTemplate>[
  MascotMessageTemplate(
    id: 'guide_wifi',
    category: MascotMessageCategory.guidance,
    builder: (_, l10n) => l10n.mascotGuideWifi(l10n.menuWifiSettings),
  ),
  MascotMessageTemplate(
    id: 'guide_devices',
    category: MascotMessageCategory.guidance,
    builder: (_, l10n) => l10n.mascotGuideDevices(l10n.devices),
  ),
  MascotMessageTemplate(
    id: 'guide_firmware',
    category: MascotMessageCategory.guidance,
    builder: (_, l10n) => l10n.mascotGuideFirmware(
      l10n.mascotMenuPath(l10n.administration, l10n.otaUpdate),
    ),
  ),
  MascotMessageTemplate(
    id: 'guide_security',
    category: MascotMessageCategory.guidance,
    builder: (_, l10n) => l10n.mascotGuideSecurity(
      l10n.mascotMenuPath(l10n.advancedSettings, l10n.firewall),
    ),
  ),
  MascotMessageTemplate(
    id: 'guide_guest',
    category: MascotMessageCategory.guidance,
    builder: (_, l10n) => l10n.mascotGuideGuest(
      l10n.mascotMenuPath(l10n.menuWifiSettings, l10n.guest),
    ),
  ),
];

// =============================================================================
// STATUS TEMPLATES (Dynamic + Conditional)
// =============================================================================

/// Lines about the router's current state.
///
/// Every count is an ICU plural in the ARB file, not string arithmetic, so
/// "1 of 1 device connected" agrees in English and each locale gets its own
/// plural forms.
final statusTemplates = <MascotMessageTemplate>[
  // CPU status
  MascotMessageTemplate(
    id: 'status_cpu_high',
    category: MascotMessageCategory.status,
    condition: (ctx) => (ctx.cpuPercent ?? 0) > 80,
    builder: (ctx, l10n) => l10n.mascotStatusCpuHigh(ctx.cpuPercent!),
    suggestedAnimation: MascotAnimationKey.think,
  ),
  MascotMessageTemplate(
    id: 'status_cpu_normal',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.cpuPercent != null && ctx.cpuPercent! <= 80,
    builder: (ctx, l10n) => l10n.mascotStatusCpuNormal(ctx.cpuPercent!),
    suggestedAnimation: MascotAnimationKey.idle,
  ),

  // Memory status
  MascotMessageTemplate(
    id: 'status_memory_high',
    category: MascotMessageCategory.status,
    condition: (ctx) => (ctx.memoryPercent ?? 0) > 80,
    builder: (ctx, l10n) => l10n.mascotStatusMemoryHigh(ctx.memoryPercent!),
    suggestedAnimation: MascotAnimationKey.think,
  ),

  // Device count
  MascotMessageTemplate(
    id: 'status_devices',
    category: MascotMessageCategory.status,
    // Both counts come from the same `DevicesData`, so they are null together.
    condition: (ctx) =>
        ctx.onlineDeviceCount != null && ctx.totalDeviceCount != null,
    builder: (ctx, l10n) => l10n.mascotStatusDevices(
      ctx.onlineDeviceCount!,
      ctx.totalDeviceCount!,
    ),
  ),

  // Mesh nodes
  MascotMessageTemplate(
    id: 'status_mesh',
    category: MascotMessageCategory.status,
    condition: (ctx) => (ctx.meshNodeCount ?? 0) > 0,
    builder: (ctx, l10n) => l10n.mascotStatusMesh(ctx.meshNodeCount!),
    suggestedAnimation: MascotAnimationKey.celebrate,
  ),

  // WAN status
  MascotMessageTemplate(
    id: 'status_wan_up',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.wanConnected == true,
    builder: (_, l10n) => l10n.mascotStatusWanUp,
    suggestedAnimation: MascotAnimationKey.idle,
  ),
  MascotMessageTemplate(
    id: 'status_wan_down',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.wanConnected == false,
    builder: (_, l10n) => l10n.mascotStatusWanDown,
    suggestedAnimation: MascotAnimationKey.sad,
  ),

  // WiFi radios
  MascotMessageTemplate(
    id: 'status_wifi_all',
    category: MascotMessageCategory.status,
    condition: (ctx) =>
        ctx.totalRadioCount != null &&
        ctx.enabledRadioCount == ctx.totalRadioCount,
    builder: (ctx, l10n) => l10n.mascotStatusWifiAll(ctx.totalRadioCount!),
  ),
  MascotMessageTemplate(
    id: 'status_wifi_partial',
    category: MascotMessageCategory.status,
    condition: (ctx) =>
        ctx.totalRadioCount != null &&
        ctx.enabledRadioCount != null &&
        ctx.enabledRadioCount! < ctx.totalRadioCount!,
    builder: (ctx, l10n) => l10n.mascotStatusWifiPartial(
      ctx.enabledRadioCount!,
      ctx.totalRadioCount!,
    ),
  ),

  // Uptime
  MascotMessageTemplate(
    id: 'status_uptime',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.uptime != null && ctx.uptime!.isNotEmpty,
    builder: (ctx, l10n) => l10n.mascotStatusUptime(ctx.uptime!),
  ),
];

// =============================================================================
// TIPS TEMPLATES (Static)
// =============================================================================

final tipsTemplates = <MascotMessageTemplate>[
  MascotMessageTemplate(
    id: 'tip_password',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipPassword,
  ),
  MascotMessageTemplate(
    id: 'tip_firmware',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipFirmware,
  ),
  MascotMessageTemplate(
    id: 'tip_guest',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipGuest,
  ),
  MascotMessageTemplate(
    id: 'tip_wpa3',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipWpa3,
  ),
  MascotMessageTemplate(
    id: 'tip_placement',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipPlacement,
  ),
  MascotMessageTemplate(
    id: 'tip_reboot',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipReboot,
  ),
  MascotMessageTemplate(
    id: 'tip_interference',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipInterference,
  ),
  MascotMessageTemplate(
    id: 'tip_5ghz',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTip5Ghz,
  ),
  MascotMessageTemplate(
    id: 'tip_here',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipHere,
    suggestedAnimation: MascotAnimationKey.greet,
  ),
  MascotMessageTemplate(
    id: 'tip_tap',
    category: MascotMessageCategory.tips,
    builder: (_, l10n) => l10n.mascotTipTap,
    suggestedAnimation: MascotAnimationKey.greet,
  ),
];

/// Get all templates for a category.
List<MascotMessageTemplate> getTemplatesForCategory(
    MascotMessageCategory category) {
  return switch (category) {
    MascotMessageCategory.guidance => guidanceTemplates,
    MascotMessageCategory.status => statusTemplates,
    MascotMessageCategory.tips => tipsTemplates,
  };
}
