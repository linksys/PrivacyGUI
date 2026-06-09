import 'package:flutter/foundation.dart';
import 'package:generative_ui/generative_ui.dart';

import 'package:privacy_gui/ai/abstraction/_abstraction.dart';
import 'package:privacy_gui/ai/prompts/router_system_prompt.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Pending confirmation state for write/admin operations.
class PendingConfirmation {
  final RouterCommand command;
  final Map<String, dynamic> params;
  final ToolUseBlock toolUse;

  const PendingConfirmation({
    required this.command,
    required this.params,
    required this.toolUse,
  });
}

/// Controller for managing Router AI Assistant conversations.
///
/// Key differences from generic ChatController:
/// - Injects router context into system prompt
/// - Handles router command execution with confirmation flow
/// - Maintains conversation state across confirmation dialogs
///
/// Flow:
/// 1. User sends message
/// 2. LLM responds (may include tool_use for router commands)
/// 3. If command requires confirmation → set pendingConfirmation, notify UI
/// 4. User confirms → execute command → add tool_result → get LLM response
/// 5. User cancels → add cancellation tool_result → get LLM response
class RouterChatController extends ChangeNotifier {
  RouterChatController({
    required IConversationGenerator generator,
    required IRouterCommandProvider commandProvider,
    required String routerContext,
  })  : _generator = generator,
        _commandProvider = commandProvider,
        _routerContext = routerContext {
    _log('RouterChatController initialized');
    _log('Router context:\n$routerContext');
    _initializeSystemPrompt();
  }

  static void _log(String message) {
    logger.d('[AI]: $message');
  }

  final IConversationGenerator _generator;
  final IRouterCommandProvider _commandProvider;
  final String _routerContext;

  ConversationState _state = ConversationState.initial();
  PendingConfirmation? _pendingConfirmation;
  String? _lastUserMessage;
  List<SystemPromptPart>? _systemPromptParts;
  List<GenTool>? _routerTools;

  // Token usage tracking
  int _totalInputTokens = 0;
  int _totalOutputTokens = 0;
  int _totalCacheReadTokens = 0;
  int _totalCacheWriteTokens = 0;

  /// Current conversation state.
  ConversationState get state => _state;

  /// Current view state.
  ChatViewState get viewState => _state.viewState;

  /// All messages in the conversation.
  List<ChatMessage> get messages => _state.messages;

  /// Whether the controller is currently loading.
  bool get isLoading => _state.isLoading;

  /// Whether there's an error.
  bool get hasError => _state.hasError;

  /// Error message if any.
  String? get errorMessage => _state.errorMessage;

  /// Whether the error is retryable.
  bool get isRetryable => _state.isRetryable;

  /// Whether there's a pending confirmation.
  bool get hasPendingConfirmation => _pendingConfirmation != null;

  /// Current pending confirmation (for UI to display).
  PendingConfirmation? get pendingConfirmation => _pendingConfirmation;

  /// Total input tokens used in this session.
  int get totalInputTokens => _totalInputTokens;

  /// Total output tokens used in this session.
  int get totalOutputTokens => _totalOutputTokens;

  /// Total tokens (input + output) used in this session.
  int get totalTokens => _totalInputTokens + _totalOutputTokens;

  /// Initialize system prompt parts with router context (for caching).
  void _initializeSystemPrompt() {
    _systemPromptParts =
        RouterSystemPrompt.buildParts(routerContext: _routerContext);
    _log(
        'System prompt initialized: ${_systemPromptParts!.length} parts, static cached: ${_systemPromptParts!.first.cache}');
  }

  /// Build router tools from command provider.
  Future<List<GenTool>> _getRouterTools() async {
    if (_routerTools != null) return _routerTools!;

    final commands = await _commandProvider.listCommands();
    _routerTools = commands
        .map((cmd) => GenTool(
              name: cmd.name,
              description: cmd.description,
              inputSchema: cmd.inputSchema,
            ))
        .toList();
    return _routerTools!;
  }

  /// Send a user message and process response.
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _log('sendMessage: "$message"');
    _lastUserMessage = message;

    // Insert pending tool results if needed
    _insertPendingToolResults();

    // Add user message
    final userMessage = ChatMessage.user(message);
    _state = _state.withMessage(userMessage);
    notifyListeners();

    // Transition to loading
    _state = _state.loading();
    notifyListeners();

    await _processConversation();
  }

  /// Core conversation processing loop.
  ///
  /// Handles:
  /// - Calling LLM
  /// - Executing router commands
  /// - Detecting confirmation requirements
  /// - Looping for multi-turn tool use
  Future<void> _processConversation() async {
    final tools = await _getRouterTools();
    var loopCount = 0;
    const maxLoops = 5;

    _log(
        '_processConversation: starting loop (${tools.length} tools available)');

    while (loopCount < maxLoops) {
      loopCount++;
      _log('_processConversation: loop $loopCount/$maxLoops');

      try {
        _log('_processConversation: calling LLM...');
        final response = await _generator.generateWithHistory(
          _state.messages,
          tools: tools.isNotEmpty ? tools : null,
          systemPromptParts: _systemPromptParts,
        );
        _log(
            '_processConversation: LLM responded, stopReason=${response.stopReason}');

        // Log token usage with cache info
        if (response.usage != null) {
          final usage = response.usage!;
          _totalInputTokens += usage.inputTokens;
          _totalOutputTokens += usage.outputTokens;
          _totalCacheReadTokens += usage.cacheReadInputTokens;
          _totalCacheWriteTokens += usage.cacheWriteInputTokens;

          // Log cache status
          if (usage.cacheHit) {
            _log(
                '_processConversation: CACHE HIT - read ${usage.cacheReadInputTokens} tokens from cache');
          } else if (usage.cacheWrite) {
            _log(
                '_processConversation: CACHE MISS - wrote ${usage.cacheWriteInputTokens} tokens to cache');
          }

          _log(
              '_processConversation: tokens - input: ${usage.inputTokens}, output: ${usage.outputTokens}');
          _log(
              '_processConversation: session total - input: $_totalInputTokens, output: $_totalOutputTokens, cacheRead: $_totalCacheReadTokens, cacheWrite: $_totalCacheWriteTokens');
        }

        // Check for tool use
        final toolUseBlocks =
            response.content.whereType<ToolUseBlock>().toList();
        final textBlocks = response.content.whereType<TextBlock>().toList();

        _log(
            '_processConversation: ${textBlocks.length} text blocks, ${toolUseBlocks.length} tool_use blocks');

        if (toolUseBlocks.isEmpty) {
          // No tools used, add response and return
          _log('_processConversation: no tools, adding final response');
          final assistantMessage = ChatMessage.assistant(response);
          _state = _state.withMessage(assistantMessage);
          notifyListeners();
          return;
        }

        // Add assistant response with tool_use
        final assistantMessage = ChatMessage.assistant(response);
        _state = _state.withMessage(assistantMessage);
        notifyListeners();

        // Restore loading state while executing tools
        _state = _state.loading();
        notifyListeners();

        // Process each tool use
        var requiresConfirmation = false;

        for (final toolUse in toolUseBlocks) {
          _log('_processConversation: executing tool "${toolUse.name}"');
          final result = await _executeToolUse(toolUse);

          if (result.requiresConfirmation) {
            _log('_processConversation: tool requires confirmation');
            requiresConfirmation = true;
            // Don't add tool_result yet — wait for user confirmation
          } else {
            _log(
                '_processConversation: tool result: ${result.isError ? "ERROR" : "SUCCESS"}');
            // Add tool result immediately
            _state = _state.withMessage(ChatMessage.toolResult(
              toolUseId: toolUse.id,
              result: result.data,
              isError: result.isError,
            ));
            notifyListeners();
          }
        }

        if (requiresConfirmation) {
          // Stop loop, UI will handle confirmation
          _log('_processConversation: waiting for user confirmation');
          return;
        }

        // Restore loading state before continuing loop
        _log('_processConversation: continuing to next loop iteration');
        _state = _state.loading();
        notifyListeners();
      } on GenUiException catch (e) {
        _log('_processConversation: GenUiException: ${e.message}');
        _state = _state.withError(e.message, retryable: e.isRetryable);
        notifyListeners();
        return;
      } catch (e) {
        _log('_processConversation: unexpected error: $e');
        _state = _state.withError('An unexpected error occurred: $e');
        notifyListeners();
        return;
      }
    }

    // Max loops reached
    _log('_processConversation: max loops reached');
    _state = _state.withError('Conversation exceeded maximum turns');
    notifyListeners();
  }

  /// Execute a single tool use block.
  Future<_ToolExecutionResult> _executeToolUse(ToolUseBlock toolUse) async {
    // Find the command
    final commands = await _commandProvider.listCommands();
    final command = commands.cast<RouterCommand?>().firstWhere(
          (c) => c?.name == toolUse.name,
          orElse: () => null,
        );

    if (command == null) {
      return _ToolExecutionResult(
        data: {'error': 'Unknown command: ${toolUse.name}'},
        isError: true,
      );
    }

    // Check if confirmation required
    if (command.requiresConfirmation) {
      _pendingConfirmation = PendingConfirmation(
        command: command,
        params: toolUse.input,
        toolUse: toolUse,
      );
      notifyListeners();
      return _ToolExecutionResult(requiresConfirmation: true);
    }

    // Execute immediately
    try {
      final result = await _commandProvider.execute(
        command.name,
        toolUse.input,
      );
      return _ToolExecutionResult(
        data: result.data,
        isError: !result.success,
      );
    } catch (e) {
      return _ToolExecutionResult(
        data: {'error': e.toString()},
        isError: true,
      );
    }
  }

  /// Confirm and execute the pending action.
  ///
  /// Called when user confirms a write/admin operation.
  /// Executes the command, adds tool_result, and continues conversation.
  Future<void> confirmPendingAction() async {
    final pending = _pendingConfirmation;
    if (pending == null) return;

    _pendingConfirmation = null;
    _state = _state.loading();
    notifyListeners();

    try {
      final result = await _commandProvider.execute(
        pending.command.name,
        pending.params,
      );

      // Add tool result
      _state = _state.withMessage(ChatMessage.toolResult(
        toolUseId: pending.toolUse.id,
        result: result.success
            ? {...result.data, 'status': 'executed'}
            : {'error': result.error ?? 'Operation failed'},
        isError: !result.success,
      ));
      notifyListeners();

      // Continue conversation to get LLM's follow-up response
      await _processConversation();
    } catch (e) {
      _state = _state.withMessage(ChatMessage.toolResult(
        toolUseId: pending.toolUse.id,
        result: {'error': e.toString()},
        isError: true,
      ));
      notifyListeners();

      // Still continue to get LLM response about the error
      await _processConversation();
    }
  }

  /// Cancel the pending action.
  ///
  /// Called when user declines a write/admin operation.
  /// Adds cancellation tool_result and continues conversation.
  Future<void> cancelPendingAction() async {
    final pending = _pendingConfirmation;
    if (pending == null) return;

    _pendingConfirmation = null;
    _state = _state.loading();
    notifyListeners();

    // Add cancellation result
    _state = _state.withMessage(ChatMessage.toolResult(
      toolUseId: pending.toolUse.id,
      result: {
        'status': 'cancelled',
        'message': 'User declined to execute ${pending.command.name}',
      },
    ));
    notifyListeners();

    // Continue conversation to get LLM's response to cancellation
    await _processConversation();
  }

  /// Handle tool action from A2UI component.
  Future<void> handleToolAction(ToolActionOutput action) async {
    final toolResultMessage = action.toChatMessage();
    _state = _state.withMessage(toolResultMessage);
    _state = _state.toolActionCompleted();
    notifyListeners();

    _state = _state.loading();
    notifyListeners();

    await _processConversation();
  }

  /// Insert tool_result messages for any pending tool_use blocks.
  void _insertPendingToolResults() {
    if (_state.messages.isEmpty) return;

    // Find the last assistant message
    ChatMessage? lastAssistantMessage;
    for (var i = _state.messages.length - 1; i >= 0; i--) {
      final msg = _state.messages[i];
      if (msg.isAssistant) {
        lastAssistantMessage = msg;
        break;
      }
      if (msg.isToolResult) return;
    }

    if (lastAssistantMessage == null) return;

    final response = lastAssistantMessage.response;
    if (response == null) return;

    final toolUseBlocks = response.content.whereType<ToolUseBlock>().toList();
    if (toolUseBlocks.isEmpty) return;

    // Insert tool_result for each tool_use block (UI rendered acknowledgment)
    for (final toolUse in toolUseBlocks) {
      _state = _state.withMessage(ChatMessage.toolResult(
        toolUseId: toolUse.id,
        result: {'status': 'rendered', 'component': toolUse.name},
      ));
    }
    notifyListeners();
  }

  /// Retry the last failed operation.
  Future<void> retry() async {
    if (!_state.hasError || _lastUserMessage == null) return;

    // Remove the failed user message
    final messagesWithoutLast = [..._state.messages];
    if (messagesWithoutLast.isNotEmpty &&
        messagesWithoutLast.last.role == ChatRole.user) {
      messagesWithoutLast.removeLast();
    }

    _state = ConversationState(
      viewState: ChatViewState.content,
      messages: messagesWithoutLast,
    );
    notifyListeners();

    await sendMessage(_lastUserMessage!);
  }

  /// Clear conversation and reset state.
  void clearConversation() {
    _log(
        'clearConversation: session summary - input: $_totalInputTokens, output: $_totalOutputTokens, cacheRead: $_totalCacheReadTokens, cacheWrite: $_totalCacheWriteTokens');
    _state = ConversationState.initial();
    _pendingConfirmation = null;
    _lastUserMessage = null;
    _routerTools = null;
    _totalInputTokens = 0;
    _totalOutputTokens = 0;
    _totalCacheReadTokens = 0;
    _totalCacheWriteTokens = 0;

    // Refresh router context
    _initializeSystemPrompt();
    notifyListeners();
  }

  /// Refresh router context (call when dashboard data changes).
  void refreshContext() {
    _initializeSystemPrompt();
  }
}

/// Internal result type for tool execution.
class _ToolExecutionResult {
  final Map<String, dynamic> data;
  final bool isError;
  final bool requiresConfirmation;

  const _ToolExecutionResult({
    this.data = const {},
    this.isError = false,
    this.requiresConfirmation = false,
  });
}
