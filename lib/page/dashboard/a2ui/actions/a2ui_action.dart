import 'package:equatable/equatable.dart';

/// Represents an action that can be triggered by A2UI widgets.
class A2UIAction extends Equatable {
  /// The action identifier (e.g., 'router.restart', 'device.block')
  final String action;

  /// Parameters to pass to the action handler
  final Map<String, dynamic> params;

  /// The source widget that triggered this action
  final String? sourceWidgetId;

  /// Timestamp when the action was created
  final DateTime timestamp;

  A2UIAction({
    required this.action,
    this.params = const {},
    this.sourceWidgetId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates an action from JSON widget definition
  factory A2UIAction.fromJson(Map<String, dynamic> json,
      {String? sourceWidgetId}) {
    return A2UIAction(
      action: json[r'$action'] as String,
      params: Map<String, dynamic>.from(json['params'] ?? {}),
      sourceWidgetId: sourceWidgetId,
    );
  }

  /// Creates an action from resolved template properties
  factory A2UIAction.fromResolvedProperties(Map<String, dynamic> resolvedProps,
      {String? sourceWidgetId}) {
    return A2UIAction(
      action: resolvedProps[r'$action'] as String,
      params: Map<String, dynamic>.from(resolvedProps['params'] ?? {}),
      sourceWidgetId: sourceWidgetId,
    );
  }

  /// Converts to the format expected by GenUiActionCallback
  Map<String, dynamic> toGenUiData() {
    return {
      'action': action,
      'params': params,
      'sourceWidgetId': sourceWidgetId,
      'timestamp': timestamp.toIso8601String(),
      ...params, // Flatten params for backward compatibility
    };
  }

  @override
  List<Object?> get props => [action, params, sourceWidgetId, timestamp];

  @override
  String toString() {
    return 'A2UIAction(action: $action, params: $params, sourceWidgetId: $sourceWidgetId)';
  }
}

/// Represents the result of an action execution
class A2UIActionResult extends Equatable {
  /// Whether the action was executed successfully
  final bool success;

  /// Error message if the action failed
  final String? error;

  /// Data returned by the action handler
  final Map<String, dynamic> data;

  /// The original action that was executed
  final A2UIAction action;

  const A2UIActionResult({
    required this.success,
    required this.action,
    this.error,
    this.data = const {},
  });

  /// Factory for successful results
  factory A2UIActionResult.success(A2UIAction action,
      [Map<String, dynamic>? data]) {
    return A2UIActionResult(
      success: true,
      action: action,
      data: data ?? {},
    );
  }

  /// Factory for failed results
  factory A2UIActionResult.failure(A2UIAction action, String error) {
    return A2UIActionResult(
      success: false,
      action: action,
      error: error,
    );
  }

  @override
  List<Object?> get props => [success, error, data, action];
}

/// Supported action types
enum A2UIActionType {
  /// Router-related actions
  router('router'),

  /// Device management actions
  device('device'),

  /// WiFi configuration actions
  wifi('wifi'),

  /// Navigation actions
  navigation('navigation'),

  /// UI state actions
  ui('ui'),

  /// Custom actions
  custom('custom');

  const A2UIActionType(this.prefix);
  final String prefix;

  /// Gets the action type from an action string
  static A2UIActionType? fromAction(String action) {
    for (final type in A2UIActionType.values) {
      if (action.startsWith('${type.prefix}.')) {
        return type;
      }
    }
    return null;
  }
}
