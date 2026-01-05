/// JNAP Mock Registry for Demo App
///
/// Returns mock responses from demo_cache_data.json.
/// Fallback strategy:
/// 1. Cache data from JSON (real device data)
/// 2. SET/DELETE actions return empty {} (no-op)
/// 3. Unmapped actions log warning and return empty {}
library;

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/demo/data/demo_cache_data.dart';

/// Central registry for JNAP mock responses
class JnapMockRegistry {
  /// Get mock response for the given action
  static Map<String, dynamic> getResponse(JNAPAction action) {
    var url = action.actionValue;

    // 1. Check cache data (primary source)
    final cacheOutput = DemoCacheDataLoader.instance.getOutput(url);
    if (cacheOutput != null) {
      return cacheOutput;
    }

    // 2. SET/DELETE/Command actions return empty (no-op)
    if (_isWriteAction(action)) {
      debugPrint('📝 Demo: No-op for ${action.actionValue}');
      return {};
    }

    // 3. Fallback with warning
    debugPrint('⚠️ Demo: No mock data for ${action.actionValue}');
    return {};
  }

  static bool _isWriteAction(JNAPAction action) {
    final actionUrl = action.actionValue;
    // Extract action name from URL (after last '/')
    final actionName = actionUrl.split('/').last;

    // Check if action STARTS with write verbs
    return actionName.startsWith('Set') ||
        actionName.startsWith('Delete') ||
        actionName.startsWith('Reboot') ||
        actionName.startsWith('Reset') ||
        actionName.startsWith('Start') ||
        actionName.startsWith('Stop') ||
        actionName.startsWith('Run') ||
        actionName.startsWith('Clear') ||
        actionName.startsWith('Update') ||
        actionName.startsWith('Add') ||
        actionName.startsWith('Remove');
  }
}
