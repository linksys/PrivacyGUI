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
class MascotMessageTemplate {
  final String id;
  final MascotMessageCategory category;
  final String Function(MascotMessageContext ctx) builder;
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

  /// Generate the message text from context.
  String generate(MascotMessageContext ctx) => builder(ctx);
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

  static const fallback = MascotMessage(
    text: "I'm here if you need help!",
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

final guidanceTemplates = <MascotMessageTemplate>[
  MascotMessageTemplate(
    id: 'guide_wifi',
    category: MascotMessageCategory.guidance,
    builder: (_) => "WiFi settings are in the sidebar under 'WiFi Settings'",
  ),
  MascotMessageTemplate(
    id: 'guide_devices',
    category: MascotMessageCategory.guidance,
    builder: (_) => "Tap 'Devices' to see all connected devices",
  ),
  MascotMessageTemplate(
    id: 'guide_diagnostics',
    category: MascotMessageCategory.guidance,
    builder: (_) =>
        "Run diagnostics by tapping me and selecting 'Run Diagnostics'",
    suggestedAnimation: MascotAnimationKey.greet,
  ),
  MascotMessageTemplate(
    id: 'guide_firmware',
    category: MascotMessageCategory.guidance,
    builder: (_) => "Check for firmware updates in 'Administration > Firmware'",
  ),
  MascotMessageTemplate(
    id: 'guide_security',
    category: MascotMessageCategory.guidance,
    builder: (_) => "Security settings are under 'Firewall' in the sidebar",
  ),
  MascotMessageTemplate(
    id: 'guide_guest',
    category: MascotMessageCategory.guidance,
    builder: (_) => "Create a guest network in 'WiFi Settings > Guest Network'",
  ),
];

// =============================================================================
// STATUS TEMPLATES (Dynamic + Conditional)
// =============================================================================

final statusTemplates = <MascotMessageTemplate>[
  // CPU status
  MascotMessageTemplate(
    id: 'status_cpu_high',
    category: MascotMessageCategory.status,
    condition: (ctx) => (ctx.cpuPercent ?? 0) > 80,
    builder: (ctx) => "Your router is working hard! CPU at ${ctx.cpuPercent}%",
    suggestedAnimation: MascotAnimationKey.think,
  ),
  MascotMessageTemplate(
    id: 'status_cpu_normal',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.cpuPercent != null && ctx.cpuPercent! <= 80,
    builder: (ctx) => "System running smoothly, CPU at ${ctx.cpuPercent}%",
    suggestedAnimation: MascotAnimationKey.idle,
  ),

  // Memory status
  MascotMessageTemplate(
    id: 'status_memory_high',
    category: MascotMessageCategory.status,
    condition: (ctx) => (ctx.memoryPercent ?? 0) > 80,
    builder: (ctx) => "Memory usage is getting high (${ctx.memoryPercent}%)",
    suggestedAnimation: MascotAnimationKey.think,
  ),

  // Device count
  MascotMessageTemplate(
    id: 'status_devices',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.onlineDeviceCount != null,
    builder: (ctx) =>
        "${ctx.onlineDeviceCount} of ${ctx.totalDeviceCount} devices connected",
  ),

  // Mesh nodes
  MascotMessageTemplate(
    id: 'status_mesh',
    category: MascotMessageCategory.status,
    condition: (ctx) => (ctx.meshNodeCount ?? 0) > 0,
    builder: (ctx) =>
        "Your mesh network has ${ctx.meshNodeCount} node${ctx.meshNodeCount == 1 ? '' : 's'} active",
    suggestedAnimation: MascotAnimationKey.celebrate,
  ),

  // WAN status
  MascotMessageTemplate(
    id: 'status_wan_up',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.wanConnected == true,
    builder: (_) => "Internet connection is stable",
    suggestedAnimation: MascotAnimationKey.idle,
  ),
  MascotMessageTemplate(
    id: 'status_wan_down',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.wanConnected == false,
    builder: (_) => "Internet connection appears to be down",
    suggestedAnimation: MascotAnimationKey.sad,
  ),

  // WiFi radios
  MascotMessageTemplate(
    id: 'status_wifi_all',
    category: MascotMessageCategory.status,
    condition: (ctx) =>
        ctx.totalRadioCount != null &&
        ctx.enabledRadioCount == ctx.totalRadioCount,
    builder: (ctx) => "All ${ctx.totalRadioCount} WiFi radios are active",
  ),
  MascotMessageTemplate(
    id: 'status_wifi_partial',
    category: MascotMessageCategory.status,
    condition: (ctx) =>
        ctx.totalRadioCount != null &&
        ctx.enabledRadioCount != null &&
        ctx.enabledRadioCount! < ctx.totalRadioCount!,
    builder: (ctx) =>
        "${ctx.enabledRadioCount} of ${ctx.totalRadioCount} WiFi radios enabled",
  ),

  // Uptime
  MascotMessageTemplate(
    id: 'status_uptime',
    category: MascotMessageCategory.status,
    condition: (ctx) => ctx.uptime != null && ctx.uptime!.isNotEmpty,
    builder: (ctx) => "Router uptime: ${ctx.uptime}",
  ),
];

// =============================================================================
// TIPS TEMPLATES (Static)
// =============================================================================

final tipsTemplates = <MascotMessageTemplate>[
  MascotMessageTemplate(
    id: 'tip_password',
    category: MascotMessageCategory.tips,
    builder: (_) =>
        "Tip: Change your WiFi password regularly for better security",
  ),
  MascotMessageTemplate(
    id: 'tip_firmware',
    category: MascotMessageCategory.tips,
    builder: (_) => "Keep your router firmware up to date for security patches",
  ),
  MascotMessageTemplate(
    id: 'tip_guest',
    category: MascotMessageCategory.tips,
    builder: (_) =>
        "Use a guest network for visitors to keep your main network secure",
  ),
  MascotMessageTemplate(
    id: 'tip_wpa3',
    category: MascotMessageCategory.tips,
    builder: (_) => "WPA3 offers the strongest WiFi encryption available",
  ),
  MascotMessageTemplate(
    id: 'tip_placement',
    category: MascotMessageCategory.tips,
    builder: (_) => "Place your router in a central location for best coverage",
  ),
  MascotMessageTemplate(
    id: 'tip_reboot',
    category: MascotMessageCategory.tips,
    builder: (_) =>
        "Rebooting your router occasionally can improve performance",
  ),
  MascotMessageTemplate(
    id: 'tip_interference',
    category: MascotMessageCategory.tips,
    builder: (_) => "Keep your router away from microwaves and cordless phones",
  ),
  MascotMessageTemplate(
    id: 'tip_5ghz',
    category: MascotMessageCategory.tips,
    builder: (_) => "5GHz WiFi is faster but has shorter range than 2.4GHz",
  ),
  MascotMessageTemplate(
    id: 'tip_here',
    category: MascotMessageCategory.tips,
    builder: (_) => "I'm here if you need help!",
    suggestedAnimation: MascotAnimationKey.greet,
  ),
  MascotMessageTemplate(
    id: 'tip_tap',
    category: MascotMessageCategory.tips,
    builder: (_) => "Tap me if you need assistance!",
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
