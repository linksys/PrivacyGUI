/// Centralized configuration for the Mascot system.
///
/// All magic numbers and timing constants are collected here for easy
/// adjustment. Future: these could be loaded from user preferences or
/// remote config.
library;

// ══════════════════════════════════════════════════════════════════════════════
// Health Evaluation Config
// ══════════════════════════════════════════════════════════════════════════════

/// Interval between periodic health evaluations.
const kHealthEvaluationInterval = Duration(minutes: 5);

/// Debounce delay for SSE-triggered health re-evaluation.
const kHealthDebounceDelay = Duration(milliseconds: 500);

// ══════════════════════════════════════════════════════════════════════════════
// Health Dimension Thresholds
// ══════════════════════════════════════════════════════════════════════════════

/// System dimension: CPU/Memory usage thresholds.
abstract final class SystemThresholds {
  static const int excellent = 50; // < 50% = score 100
  static const int good = 70; // 50-70% = score 80
  static const int fair = 85; // 70-85% = score 60
  static const int poor = 95; // 85-95% = score 40
  // >= 95% = score 20
}

/// Devices dimension: Online ratio thresholds.
abstract final class DevicesThresholds {
  static const double excellent = 1.0; // 100% online = score 100
  static const double good = 0.8; // > 80% = score 80
  static const double fair = 0.5; // > 50% = score 60
  // <= 50% = score 40
}

// ══════════════════════════════════════════════════════════════════════════════
// Trigger Cooldowns
// ══════════════════════════════════════════════════════════════════════════════

/// Default cooldowns for each trigger type.
///
/// Adjust these to control notification frequency.
abstract final class TriggerCooldowns {
  static const Duration wanDown = Duration(minutes: 5);
  static const Duration wanRestored = Duration(minutes: 1);
  static const Duration newDevice = Duration(seconds: 30);
  static const Duration cpuHigh = Duration(minutes: 10);
  static const Duration memoryHigh = Duration(minutes: 10);
  static const Duration firmwareAvailable = Duration(hours: 24);
  static const Duration wifiRadioDisabled = Duration(minutes: 5);
  static const Duration firewallDisabled = Duration(minutes: 30);
  static const Duration dmzEnabled = Duration(hours: 1);
}

// ══════════════════════════════════════════════════════════════════════════════
// Trigger Auto-Hide Durations
// ══════════════════════════════════════════════════════════════════════════════

/// How long trigger notifications stay visible before auto-hiding.
abstract final class TriggerAutoHide {
  static const Duration critical = Duration(seconds: 8);
  static const Duration high = Duration(seconds: 6);
  static const Duration medium = Duration(seconds: 5);
  static const Duration low = Duration(seconds: 5);
}

// ══════════════════════════════════════════════════════════════════════════════
// Random Speech Config
// ══════════════════════════════════════════════════════════════════════════════

/// Minimum interval between random mascot speeches.
const kRandomSpeechMinInterval = Duration(seconds: 10);

/// Maximum interval between random mascot speeches.
const kRandomSpeechMaxInterval = Duration(seconds: 30);

/// How long random speech bubbles stay visible.
const kRandomSpeechAutoHide = Duration(seconds: 5);

// ══════════════════════════════════════════════════════════════════════════════
// Word Cloud Config
// ══════════════════════════════════════════════════════════════════════════════

/// Font size range for word cloud dimensions.
abstract final class WordCloudFontSize {
  static const double min = 12.0;
  static const double max = 24.0;
}

/// Base spacing between word cloud items.
const kWordCloudSpacing = 8.0;
