import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Logging helpers for the AI assistant.
///
/// The assistant handles two kinds of information, and they need different
/// treatment in a shipped build:
///
/// * **Structural diagnostics** — loop progress, tool names, token counts,
///   success/failure, counts. Useful in the field, carries nothing about the
///   user or their network. Logged always, via [aiLog].
/// * **Content** — router state, conversation text, device names, IP and MAC
///   addresses, SSIDs. This is user data; it must not reach a release log.
///   Logged only in debug builds, via [aiLogSensitive].
///
/// Keeping the distinction at the call site (rather than a single `log()` that
/// callers have to remember to guard) makes it visible in review which lines
/// carry user data.

/// Set to false by tests to exercise the release path of [aiLogSensitive].
///
/// A seam, not a feature. The suite runs in debug, so a test that reads
/// [kDebugMode] directly can only assert the behaviour of the mode it happens
/// to run in — such a test can never fail, and would stay green if the guard
/// were weakened or removed. Forcing this off lets a test assert what actually
/// matters: that content is withheld and `orElse` is used instead.
///
/// It gates only the *debug* branch, so [kDebugMode] remains the outer
/// condition and release builds still drop that branch at compile time — the
/// sensitive callback cannot be reached, let alone invoked.
bool _sensitiveLoggingAllowed = true;

/// Where log lines go. Overridable so tests can assert the emitted text.
void Function(String line) _sink = (line) => logger.d(line);

/// Make [aiLogSensitive] take its release path, and capture emitted lines.
///
/// Returns the list the sink appends to. Pair with [resetAiLoggingForTest].
@visibleForTesting
List<String> stubAiLoggingAsRelease() {
  final lines = <String>[];
  _sensitiveLoggingAllowed = false;
  _sink = lines.add;
  return lines;
}

/// Capture emitted lines while leaving the debug/release behaviour alone.
@visibleForTesting
List<String> captureAiLogs() {
  final lines = <String>[];
  _sink = lines.add;
  return lines;
}

/// Restore production logging. Call from `tearDown`.
@visibleForTesting
void resetAiLoggingForTest() {
  _sensitiveLoggingAllowed = true;
  _sink = (line) => logger.d(line);
}

/// Log a structural diagnostic. Safe in release builds.
void aiLog(String message) {
  _sink('[AI]: $message');
}

/// Log user data — router state, conversation text, device identifiers.
///
/// [message] is compiled out of release builds. It is a callback so the string
/// is not even built when it will not be logged, which keeps interpolation of
/// sensitive values out of a release run entirely.
///
/// Pass [orElse] when the line also carries something worth keeping in the
/// field — a count, a status flag — so release builds log that instead of
/// nothing. This avoids the alternative of emitting two lines for one event,
/// which would double up in debug logs.
void aiLogSensitive(String Function() message, {String Function()? orElse}) {
  // kDebugMode is const, so this whole branch is removed from a release build.
  if (kDebugMode && _sensitiveLoggingAllowed) {
    _sink('[AI]: ${message()}');
  } else if (orElse != null) {
    _sink('[AI]: ${orElse()}');
  }
}
