import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/core/usp/models/invalidation_domain.dart';
import '../mascot_config.dart';
import 'mascot_trigger.dart';

/// Factory for creating predefined mascot triggers.
///
/// Extensible: add new triggers by creating factory methods.
abstract final class TriggerDefinitions {
  /// WAN connection lost — critical priority.
  static MascotTrigger wanDown() => const MascotTrigger(
        id: 'wan_down',
        message:
            'Internet connection lost. Check your WAN cable or contact your ISP.',
        priority: TriggerPriority.critical,
        cooldown: TriggerCooldowns.wanDown,
        animation: MascotAnimationKey.sad,
        interruptCurrent: true,
        autoHideDuration: TriggerAutoHide.critical,
      );

  /// WAN connection restored.
  static MascotTrigger wanRestored() => const MascotTrigger(
        id: 'wan_restored',
        message: 'Internet connection restored!',
        priority: TriggerPriority.high,
        cooldown: TriggerCooldowns.wanRestored,
        animation: MascotAnimationKey.celebrate,
        interruptCurrent: false,
        autoHideDuration: TriggerAutoHide.medium,
      );

  /// New device joined the network.
  static MascotTrigger newDeviceJoined(String deviceName) => MascotTrigger(
        id: 'new_device_joined',
        message: 'New device "$deviceName" joined the network.',
        priority: TriggerPriority.medium,
        cooldown: TriggerCooldowns.newDevice,
        animation: MascotAnimationKey.greet,
        interruptCurrent: false,
        autoHideDuration: TriggerAutoHide.medium,
      );

  /// CPU usage exceeded threshold.
  static MascotTrigger cpuHigh(int percentage) => MascotTrigger(
        id: 'cpu_high',
        message:
            'CPU usage is at $percentage%. System performance may be affected.',
        priority: TriggerPriority.high,
        cooldown: TriggerCooldowns.cpuHigh,
        animation: MascotAnimationKey.think,
        interruptCurrent: false,
        autoHideDuration: TriggerAutoHide.high,
      );

  /// Memory usage exceeded threshold.
  static MascotTrigger memoryHigh(int percentage) => MascotTrigger(
        id: 'memory_high',
        message:
            'Memory usage is at $percentage%. Consider restarting the router.',
        priority: TriggerPriority.high,
        cooldown: TriggerCooldowns.memoryHigh,
        animation: MascotAnimationKey.think,
        interruptCurrent: false,
        autoHideDuration: TriggerAutoHide.high,
      );

  /// Firmware update available.
  static MascotTrigger firmwareAvailable(String version) => MascotTrigger(
        id: 'firmware_available',
        message: 'Firmware update $version is available.',
        priority: TriggerPriority.low,
        cooldown: TriggerCooldowns.firmwareAvailable,
        animation: MascotAnimationKey.idle,
        interruptCurrent: false,
        autoHideDuration: TriggerAutoHide.low,
      );

  /// WiFi radio disabled.
  static MascotTrigger wifiRadioDisabled(String band) => MascotTrigger(
        id: 'wifi_radio_disabled_$band',
        message: '$band WiFi radio has been disabled.',
        priority: TriggerPriority.medium,
        cooldown: TriggerCooldowns.wifiRadioDisabled,
        animation: MascotAnimationKey.sad,
        interruptCurrent: false,
        autoHideDuration: TriggerAutoHide.medium,
      );

  /// Firewall disabled.
  static MascotTrigger firewallDisabled() => const MascotTrigger(
        id: 'firewall_disabled',
        message: 'Firewall has been disabled. Your network may be vulnerable.',
        priority: TriggerPriority.high,
        cooldown: TriggerCooldowns.firewallDisabled,
        animation: MascotAnimationKey.sad,
        interruptCurrent: true,
        autoHideDuration: TriggerAutoHide.critical,
      );

  /// DMZ enabled warning.
  static MascotTrigger dmzEnabled(String deviceName) => MascotTrigger(
        id: 'dmz_enabled',
        message:
            'DMZ is enabled for "$deviceName". This device is exposed to the internet.',
        priority: TriggerPriority.medium,
        cooldown: TriggerCooldowns.dmzEnabled,
        animation: MascotAnimationKey.think,
        interruptCurrent: false,
        autoHideDuration: TriggerAutoHide.high,
      );
}

/// Mapping from InvalidationDomain to trigger evaluation.
///
/// Determines which domains should trigger immediate health re-evaluation.
abstract final class TriggerDomainMapping {
  /// Domains that require immediate health re-evaluation when invalidated.
  static const Set<InvalidationDomain> healthCriticalDomains = {
    InvalidationDomain.wanStatus,
    InvalidationDomain.connectedDevices,
    InvalidationDomain.wifiRadios,
    InvalidationDomain.firewallRules,
    InvalidationDomain.dmz,
  };

  /// Domains that may trigger proactive notifications.
  static const Set<InvalidationDomain> notificationDomains = {
    InvalidationDomain.wanStatus,
    InvalidationDomain.connectedDevices,
    InvalidationDomain.wifiRadios,
    InvalidationDomain.firewallRules,
    InvalidationDomain.dmz,
  };

  /// Check if a domain should trigger health re-evaluation.
  static bool isHealthCritical(InvalidationDomain domain) =>
      healthCriticalDomains.contains(domain);

  /// Check if a domain may trigger a notification.
  static bool canTriggerNotification(InvalidationDomain domain) =>
      notificationDomains.contains(domain);
}
