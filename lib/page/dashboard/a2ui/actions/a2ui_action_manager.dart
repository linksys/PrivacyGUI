import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'a2ui_action.dart';
import 'a2ui_action_handler.dart';

/// Manages A2UI actions - registration, routing, and execution
class A2UIActionManager {
  final Map<String, A2UIActionHandler> _handlers = {};
  final StreamController<A2UIActionResult> _resultStream = StreamController.broadcast();

  /// Stream of action execution results
  Stream<A2UIActionResult> get results => _resultStream.stream;

  A2UIActionManager() {
    // Register default handlers
    _registerDefaultHandlers();
  }

  void _registerDefaultHandlers() {
    registerHandler(RouterActionHandler());
    registerHandler(DeviceActionHandler());
    registerHandler(NavigationActionHandler());
    registerHandler(UIActionHandler());
  }

  /// Registers an action handler for a specific action type
  void registerHandler(A2UIActionHandler handler) {
    _handlers[handler.actionType] = handler;
    debugPrint('A2UI: Registered handler for "${handler.actionType}" actions');
  }

  /// Executes an action and returns the result
  Future<A2UIActionResult> executeAction(A2UIAction action, WidgetRef ref) async {
    try {
      debugPrint('A2UI: Executing action: ${action.action}');

      // Find appropriate handler
      final handler = _findHandler(action);
      if (handler == null) {
        final result = A2UIActionResult.failure(
          action,
          'No handler found for action type: ${action.action}'
        );
        _resultStream.add(result);
        return result;
      }

      // Validate action
      if (!handler.validateAction(action)) {
        final result = A2UIActionResult.failure(
          action,
          'Action validation failed'
        );
        _resultStream.add(result);
        return result;
      }

      // Execute action
      final result = await handler.handle(action, ref);
      _resultStream.add(result);

      if (result.success) {
        debugPrint('A2UI: Action executed successfully: ${action.action}');
      } else {
        debugPrint('A2UI: Action failed: ${action.action} - ${result.error}');
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('A2UI: Action execution error: $e');
      debugPrint('Stack trace: $stackTrace');

      final result = A2UIActionResult.failure(action, 'Execution error: $e');
      _resultStream.add(result);
      return result;
    }
  }

  /// Creates a GenUi-compatible action callback
  void Function(Map<String, dynamic>) createActionCallback(WidgetRef ref, {String? widgetId}) {
    return (Map<String, dynamic> data) async {
      try {
        // Extract action from the data
        final actionName = data['action'] as String?;
        if (actionName == null) {
          debugPrint('A2UI: No action specified in callback data: $data');
          return;
        }

        // Create A2UIAction from the callback data
        final action = A2UIAction(
          action: actionName,
          params: Map<String, dynamic>.from(data)..remove('action'),
          sourceWidgetId: widgetId,
        );

        // Execute the action
        await executeAction(action, ref);
      } catch (e) {
        debugPrint('A2UI: Error in action callback: $e');
      }
    };
  }

  /// Finds the appropriate handler for an action
  A2UIActionHandler? _findHandler(A2UIAction action) {
    for (final handler in _handlers.values) {
      if (handler.canHandle(action)) {
        return handler;
      }
    }
    return null;
  }

  /// Gets all registered action types
  Set<String> get registeredActionTypes => _handlers.keys.toSet();

  /// Checks if a specific action type is supported
  bool isActionTypeSupported(String actionType) {
    return _handlers.containsKey(actionType);
  }

  /// Disposes the action manager
  void dispose() {
    _resultStream.close();
  }
}

/// Security context for A2UI actions
class A2UISecurityContext {
  final Set<String> allowedActions;
  final Set<String> allowedDataPaths;
  final String? userRole;

  const A2UISecurityContext({
    this.allowedActions = const {},
    this.allowedDataPaths = const {},
    this.userRole,
  });

  /// Checks if an action is allowed
  bool canExecuteAction(String action) {
    // If no restrictions, allow all
    if (allowedActions.isEmpty) return true;

    // Check exact match or wildcard
    return allowedActions.contains(action) ||
           allowedActions.any((allowed) => _matchesPattern(action, allowed));
  }

  /// Checks if a data path can be accessed
  bool canAccessDataPath(String path) {
    // If no restrictions, allow all
    if (allowedDataPaths.isEmpty) return true;

    // Check exact match or wildcard
    return allowedDataPaths.contains(path) ||
           allowedDataPaths.any((allowed) => _matchesPattern(path, allowed));
  }

  bool _matchesPattern(String value, String pattern) {
    // Simple wildcard matching (e.g., "router.*" matches "router.restart")
    if (pattern.endsWith('*')) {
      final prefix = pattern.substring(0, pattern.length - 1);
      return value.startsWith(prefix);
    }
    return value == pattern;
  }

  /// Default context for development (allows everything)
  static const development = A2UISecurityContext();

  /// Restricted context for production
  static const production = A2UISecurityContext(
    allowedActions: {
      'router.restart',
      'router.connect',
      'router.disconnect',
      'device.block',
      'device.unblock',
      'device.showDetails',
      'navigation.*',
      'ui.*',
    },
    allowedDataPaths: {
      'router.*',
      'wifi.*',
      'device.*',
    },
  );
}

/// Provider for the A2UI action manager
final a2uiActionManagerProvider = Provider<A2UIActionManager>((ref) {
  final manager = A2UIActionManager();

  // Clean up when disposed
  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

/// Provider for the security context
final a2uiSecurityContextProvider = Provider<A2UISecurityContext>((ref) {
  // In production, this would be determined by user authentication
  // For now, use development context
  return kDebugMode
      ? A2UISecurityContext.development
      : A2UISecurityContext.production;
});