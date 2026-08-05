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

/// Log a structural diagnostic. Safe in release builds.
void aiLog(String message) {
  logger.d('[AI]: $message');
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
  if (kDebugMode) {
    logger.d('[AI]: ${message()}');
  } else if (orElse != null) {
    logger.d('[AI]: ${orElse()}');
  }
}
