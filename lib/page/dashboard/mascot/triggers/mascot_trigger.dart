import 'package:equatable/equatable.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Priority levels for mascot triggers.
///
/// Lower value = higher priority.
abstract class TriggerPriority {
  static const critical = 1; // WAN down
  static const high = 2; // WAN restored, CPU critical
  static const medium = 3; // New device joined
  static const low = 4; // Informational
}

/// A trigger condition that can activate a mascot notification.
class MascotTrigger extends Equatable {
  /// Unique identifier for this trigger.
  final String id;

  /// Message to display when triggered.
  final String message;

  /// Priority level (lower = more important).
  final int priority;

  /// Minimum time between consecutive triggers of this type.
  final Duration cooldown;

  /// Suggested animation to play.
  final MascotAnimationKey? animation;

  /// Whether this trigger should interrupt the current dialog.
  final bool interruptCurrent;

  /// Auto-hide duration for the notification.
  final Duration autoHideDuration;

  const MascotTrigger({
    required this.id,
    required this.message,
    this.priority = TriggerPriority.medium,
    this.cooldown = const Duration(minutes: 5),
    this.animation,
    this.interruptCurrent = false,
    this.autoHideDuration = const Duration(seconds: 5),
  });

  @override
  List<Object?> get props =>
      [id, message, priority, cooldown, animation, interruptCurrent];
}

/// State tracking for trigger cooldowns.
class TriggerCooldownState {
  final Map<String, DateTime> _lastTriggered = {};

  /// Check if a trigger is currently in cooldown.
  bool isInCooldown(MascotTrigger trigger) {
    final lastTime = _lastTriggered[trigger.id];
    if (lastTime == null) return false;
    return DateTime.now().difference(lastTime) < trigger.cooldown;
  }

  /// Record that a trigger was fired.
  void recordTrigger(MascotTrigger trigger) {
    _lastTriggered[trigger.id] = DateTime.now();
  }

  /// Clear cooldown for a specific trigger.
  void clearCooldown(String triggerId) {
    _lastTriggered.remove(triggerId);
  }

  /// Clear all cooldowns.
  void clearAll() {
    _lastTriggered.clear();
  }
}
