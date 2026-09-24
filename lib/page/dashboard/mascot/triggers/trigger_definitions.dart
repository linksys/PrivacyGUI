import 'package:ui_kit_library/ui_kit.dart';
import '../mascot_config.dart';
import 'mascot_trigger.dart';

/// Factory for creating predefined mascot triggers.
///
/// Every definition here has an evaluator in `MascotTriggerNotifier`, and that
/// is the rule for adding one. Four used to sit here without one — `cpuHigh`,
/// `memoryHigh`, `firmwareAvailable`, `dmzEnabled` — each with a cooldown
/// constant, an auto-hide duration and a unit test, which is exactly what made
/// them look live. `manualTrigger` is the only other route to `_fireTrigger`
/// and has no call site either, so there was no path to any of them (#1531).
///
/// All four subjects already reach the user through the health dimensions:
/// CPU/memory via `SystemHealthDimension`, firmware via
/// `FirmwareHealthDimension`, DMZ via `SecurityHealthDimension`. Writing the
/// evaluators would have said the same thing twice — and `firmwareAvailable`
/// specifically belongs to the firmware notification work, not here.
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
}
