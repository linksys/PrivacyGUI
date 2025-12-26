/// USP Logger Utility
///
/// Provides consistent logging for USP TR-181 to JNAP mapping.
library;

/// Logger utility for USP operations.
///
/// Provides structured logging for TR-181 ↔ JNAP mapping process.
/// Uses print() to ensure visibility in Flutter web release builds.
class UspLogger {
  static const _prefix = '[USP]';

  /// Log the start of a mapping operation.
  static void logMappingStart(String methodName) {
    // ignore: avoid_print
    print('$_prefix 🔄 [TR-181 → JNAP] Mapping $methodName...');
  }

  /// Log raw TR-181 data received from the simulator.
  ///
  /// Combines all entries into a single log call for cleaner output.
  static void logTr181Data(Map<String, dynamic> values) {
    final buffer = StringBuffer();
    buffer.writeln('$_prefix 📦 Raw TR-181 Data (${values.length} items):');
    for (final entry in values.entries) {
      buffer.writeln('   ${entry.key} = ${entry.value}');
    }
    // ignore: avoid_print
    print(buffer.toString());
  }

  /// Log a count of items found.
  static void logCount(String itemType, int count) {
    // ignore: avoid_print
    print('$_prefix 📱 Found $count $itemType');
  }

  /// Log the result of a mapping operation.
  ///
  /// [items] is a list of (name, id) pairs for each mapped item.
  static void logMappingResult(
      String resultType, List<(String name, String id)> items) {
    final buffer = StringBuffer();
    buffer.writeln(
        '$_prefix ✅ Mapped ${items.length} $resultType to JNAP format');
    for (final (name, id) in items) {
      buffer.writeln('   📍 $name ($id)');
    }
    // ignore: avoid_print
    print(buffer.toString());
  }

  /// Log a simple message.
  static void log(String message) {
    // ignore: avoid_print
    print('$_prefix $message');
  }

  /// Log a warning.
  static void warn(String message) {
    // ignore: avoid_print
    print('$_prefix ⚠️ $message');
  }
}
