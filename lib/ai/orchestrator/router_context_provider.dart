import 'dart:convert';

import 'package:privacy_gui/ai/abstraction/_abstraction.dart';

/// Provides router context information for AI system prompts.
///
/// This class fetches current router state and formats it as context
/// that can be injected into the AI system prompt.
class RouterContextProvider {
  final IRouterCommandProvider _commandProvider;

  RouterContextProvider(this._commandProvider);

  /// Builds a context string with current router state for the AI.
  Future<String> buildContextPrompt() async {
    final buffer = StringBuffer();
    buffer.writeln('## Current Router State');
    buffer.writeln();

    try {
      // Get device info
      final statusResource =
          await _commandProvider.readResource('router://status');
      buffer.writeln('### System Status');
      buffer.writeln('```json');
      buffer.writeln(
          const JsonEncoder.withIndent('  ').convert(statusResource.content));
      buffer.writeln('```');
      buffer.writeln();

      // Get connected devices count
      final devicesResource =
          await _commandProvider.readResource('router://devices');
      final devices = devicesResource.content['devices'] as List? ?? [];
      // Filter for online devices only (those with active connections)
      final onlineDevices = devices.where((d) {
        final connections = d['connections'] as List? ?? [];
        return connections.isNotEmpty;
      }).toList();

      buffer.writeln('### Connected Devices');
      buffer.writeln('- Total connected devices: ${onlineDevices.length}');
      // Also provide total known devices for context if needed, but primary focus is connected
      buffer.writeln('- Total known devices: ${devices.length}');
      buffer.writeln();
    } catch (e) {
      buffer
          .writeln('> Note: Some router information is currently unavailable.');
    }

    // List available commands
    buffer.writeln('### Available Commands');
    final commands = await _commandProvider.listCommands();
    for (final cmd in commands) {
      final level = cmd.accessLevel.name.toUpperCase();
      final confirm = cmd.requiresConfirmation ? ' ⚠️' : '';
      buffer.writeln('- `${cmd.name}` [$level]$confirm: ${cmd.description}');
    }

    return buffer.toString();
  }

  /// Builds a list of available tools for the AI in GenTool format.
  Future<List<Map<String, dynamic>>> buildToolDefinitions() async {
    final commands = await _commandProvider.listCommands();
    return commands
        .map((cmd) => {
              'name': cmd.name,
              'description': cmd.description,
              'input_schema': cmd.inputSchema,
            })
        .toList();
  }
}
