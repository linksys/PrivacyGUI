import 'package:equatable/equatable.dart';

import 'access_level.dart';

/// Describes a router command that can be executed via AI.
///
/// This maps to MCP's Tool concept.
class RouterCommand extends Equatable {
  /// Unique command name (e.g., 'getDevices', 'setRadioSettings')
  final String name;

  /// Human-readable description for AI understanding
  final String description;

  /// JSON Schema describing the input parameters
  final Map<String, dynamic> inputSchema;

  /// Whether this command requires user confirmation before execution
  final bool requiresConfirmation;

  /// Access level required to execute this command
  final AccessLevel accessLevel;

  const RouterCommand({
    required this.name,
    required this.description,
    this.inputSchema = const {},
    this.requiresConfirmation = false,
    this.accessLevel = AccessLevel.read,
  });

  @override
  List<Object?> get props => [
        name,
        description,
        inputSchema,
        requiresConfirmation,
        accessLevel,
      ];
}

/// Result of executing a router command.
class RouterCommandResult extends Equatable {
  /// Whether the command executed successfully
  final bool success;

  /// Result data from the command
  final Map<String, dynamic> data;

  /// Error message if the command failed
  final String? error;

  const RouterCommandResult({
    required this.success,
    this.data = const {},
    this.error,
  });

  factory RouterCommandResult.success(Map<String, dynamic> data) {
    return RouterCommandResult(success: true, data: data);
  }

  factory RouterCommandResult.failure(String error) {
    return RouterCommandResult(success: false, error: error);
  }

  @override
  List<Object?> get props => [success, data, error];
}
