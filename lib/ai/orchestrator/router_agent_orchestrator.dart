import 'package:flutter/foundation.dart';
import 'package:generative_ui/generative_ui.dart';

import 'package:privacy_gui/ai/abstraction/_abstraction.dart';
import 'package:privacy_gui/ai/prompts/router_system_prompt.dart';

import 'router_context_provider.dart';

/// Orchestrator that bridges AI conversation with router commands.
///
/// This class:
/// 1. Injects router context into LLM system prompts
/// 2. Handles tool execution requests from LLM
/// 3. Manages action confirmation flow for write/admin operations
class RouterAgentOrchestrator implements IConversationGenerator {
  final IConversationGenerator _llmGenerator;
  final IRouterCommandProvider _commandProvider;
  final RouterContextProvider _contextProvider;

  /// Callback for when a command requires user confirmation.
  final void Function(RouterCommand command, Map<String, dynamic> params)?
      onConfirmationRequired;

  /// Cached system prompt with router context.
  String? _cachedSystemPrompt;

  RouterAgentOrchestrator({
    required IConversationGenerator llmGenerator,
    required IRouterCommandProvider commandProvider,
    RouterContextProvider? contextProvider,
    this.onConfirmationRequired,
  })  : _llmGenerator = llmGenerator,
        _commandProvider = commandProvider,
        _contextProvider =
            contextProvider ?? RouterContextProvider(commandProvider);

  @override
  Future<LLMResponse> generateWithHistory(
    List<ChatMessage> messages, {
    List<GenTool>? tools,
    String? systemPrompt,
    bool forceToolUse = false,
  }) async {
    // Build enhanced system prompt with router context
    final enhancedPrompt = await _buildSystemPrompt(systemPrompt);

    // Build tool definitions from command provider
    final routerTools = await _buildRouterTools();
    final allTools = [...?tools, ...routerTools];

    // Local copy of messages for the loop
    var currentMessages = List<ChatMessage>.from(messages);
    var loopCount = 0;
    const maxLoops = 5;

    while (loopCount < maxLoops) {
      loopCount++;

      // Call LLM
      final response = await _llmGenerator.generateWithHistory(
        currentMessages,
        tools: allTools.isNotEmpty ? allTools : null,
        systemPrompt: enhancedPrompt,
        // Only force tool use on the FIRST turn if requested
        forceToolUse: loopCount == 1 && forceToolUse,
      );

      // Check for tool use
      final toolUseBlocks = response.content.whereType<ToolUseBlock>().toList();

      if (toolUseBlocks.isEmpty) {
        // No tools used, return final response
        return response;
      }

      // Add assistant response to history
      currentMessages.add(ChatMessage.assistant(response));

      // Execute tools
      var confirmationRequired = false;

      for (final toolUse in toolUseBlocks) {
        final executionResult = await _executeCommand(toolUse);

        if (executionResult.$1) {
          // Confirmation required
          confirmationRequired = true;
        }

        // Add result message
        currentMessages.add(ChatMessage.toolResult(
          toolUseId: toolUse.id,
          result: executionResult.$2,
          isError: executionResult.$3,
        ));
      }

      if (confirmationRequired) {
        // If confirmation was required, stop loop and return the response.
        // The UI will handle the confirmation dialog via callback.
        return response;
      }

      // Continue loop with new history
    }

    return LLMResponse(id: 'error', model: 'error', content: [
      TextBlock(
          text: '⚠️ Error: Too many conversation turns, execution stopped.')
    ]);
  }

  /// Builds the system prompt with router context injected.
  Future<String> _buildSystemPrompt(String? basePrompt) async {
    if (_cachedSystemPrompt == null) {
      final routerContext = await _contextProvider.buildContextPrompt();
      _cachedSystemPrompt =
          RouterSystemPrompt.build(routerContext: routerContext);

      // DEBUG: Log first 500 chars of system prompt
      debugPrint('=== SYSTEM PROMPT FIRST 500 CHARS ===');
      debugPrint(_cachedSystemPrompt!.substring(
          0,
          _cachedSystemPrompt!.length > 500
              ? 500
              : _cachedSystemPrompt!.length));
      debugPrint('=== END SYSTEM PROMPT PREVIEW ===');
    }

    if (basePrompt != null && basePrompt.isNotEmpty) {
      return '$_cachedSystemPrompt\n\n$basePrompt';
    }

    return _cachedSystemPrompt!;
  }

  /// Builds GenTool definitions from the command provider.
  Future<List<GenTool>> _buildRouterTools() async {
    final commands = await _commandProvider.listCommands();
    return commands
        .map((cmd) => GenTool(
              name: cmd.name,
              description: cmd.description,
              inputSchema: cmd.inputSchema,
            ))
        .toList();
  }

  /// Executes a command and returns (requiresConfirmation, output/error, isError)
  Future<(bool, Map<String, dynamic>, bool)> _executeCommand(
      ToolUseBlock toolCall) async {
    // Check if this is a router command
    final commands = await _commandProvider.listCommands();
    final command = commands.cast<RouterCommand?>().firstWhere(
          (c) => c?.name == toolCall.name,
          orElse: () => null,
        );

    if (command == null) {
      return (false, {'error': 'Unknown command: ${toolCall.name}'}, true);
    }

    // Check if confirmation is required
    if (command.requiresConfirmation) {
      debugPrint(
          'RouterAgentOrchestrator: Confirmation required for ${command.name}');
      onConfirmationRequired?.call(command, toolCall.input);
      return (true, {'status': 'pending_confirmation'}, false);
    }

    // Execute read-only command immediately
    try {
      final result = await _commandProvider.execute(
        command.name,
        toolCall.input,
      );

      debugPrint(
          'RouterAgentOrchestrator: Executed ${command.name}, success=${result.success}');

      return (false, result.data, !result.success);
    } catch (e) {
      debugPrint(
          'RouterAgentOrchestrator: Error executing ${command.name}: $e');
      return (false, {'error': e.toString()}, true);
    }
  }

  /// Clears the cached system prompt to force refresh.
  void clearCache() {
    _cachedSystemPrompt = null;
  }

  /// Executes a confirmed command.
  ///
  /// Call this after user confirms a write/admin operation.
  Future<RouterCommandResult> executeConfirmedCommand(
    String commandName,
    Map<String, dynamic> params,
  ) async {
    return _commandProvider.execute(commandName, params);
  }
}
