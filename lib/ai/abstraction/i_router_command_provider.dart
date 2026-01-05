import 'router_command.dart';
import 'router_resource.dart';

/// Core abstraction for router command providers.
///
/// This interface follows MCP (Model Context Protocol) patterns:
/// - `listCommands()` ≈ MCP `tools/list`
/// - `execute()` ≈ MCP `tools/call`
/// - `listResources()` ≈ MCP `resources/list`
/// - `readResource()` ≈ MCP `resources/read`
///
/// Implementations:
/// - [JnapCommandProvider] - JNAP-based implementation
/// - [UspCommandProvider] - USP-based implementation (future)
abstract class IRouterCommandProvider {
  /// Returns the list of available commands.
  ///
  /// This is used to generate the tool definitions for the AI.
  Future<List<RouterCommand>> listCommands();

  /// Executes a command with the given parameters.
  ///
  /// Throws [UnauthorizedCommandException] if the command is not in the whitelist.
  /// Throws [CommandExecutionException] if the command fails to execute.
  Future<RouterCommandResult> execute(
    String commandName,
    Map<String, dynamic> params,
  );

  /// Returns the list of available resources.
  ///
  /// Resources are read-only data that the AI can query.
  List<RouterResourceDescriptor> listResources();

  /// Reads a resource by its URI.
  ///
  /// Throws [ResourceNotFoundException] if the resource does not exist.
  Future<RouterResource> readResource(String resourceUri);
}

/// Exception thrown when attempting to execute an unauthorized command.
class UnauthorizedCommandException implements Exception {
  final String commandName;

  const UnauthorizedCommandException(this.commandName);

  @override
  String toString() =>
      'UnauthorizedCommandException: Command "$commandName" is not allowed';
}

/// Exception thrown when command execution fails.
class CommandExecutionException implements Exception {
  final String commandName;
  final String message;

  const CommandExecutionException(this.commandName, this.message);

  @override
  String toString() =>
      'CommandExecutionException: Command "$commandName" failed: $message';
}

/// Exception thrown when a resource is not found.
class ResourceNotFoundException implements Exception {
  final String resourceUri;

  const ResourceNotFoundException(this.resourceUri);

  @override
  String toString() =>
      'ResourceNotFoundException: Resource "$resourceUri" not found';
}
