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
///
/// ## Batching tool results
///
/// The Claude Messages API requires every `tool_use` block in an assistant
/// message to be answered within the *single* user message that immediately
/// follows it. Results are therefore accumulated in [_pendingResults] and
/// flushed as one [ChatMessage.toolResults] message once every tool in the
/// batch has a result.
///
/// When a command requires confirmation the batch stays open across the
/// confirmation dialog: results for the sibling tools are held back until the
/// user confirms or cancels, then flushed together with the write result. This
/// is invisible to the user because tool results are never rendered in the chat.
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
  Map<String, RouterCommand>? _commandsByName;

  /// Tool results for the batch currently being processed. Flushed by
  /// [_flushPendingResults].
  ///
  /// Ordering follows execution, not the assistant's `tool_use` order — a
  /// confirmed write is appended after its siblings. That is fine: the API
  /// matches results to requests by `tool_use_id`, and only requires them all
  /// to arrive in the single user message following the assistant turn.
  final List<ToolResultPart> _pendingResults = [];

  /// Incremented whenever the conversation is reset, so work that was already
  /// in flight (e.g. a confirmation awaiting the device) can tell that its
  /// conversation is gone and drop its result instead of injecting an orphan.
  int _conversationGeneration = 0;

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

      // Declared outside the try so the catch blocks can still surface a
      // confirmation that was discovered before the failure.
      PendingConfirmation? deferred;

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

        // Process each tool use. Results are accumulated rather than emitted
        // one by one, so the whole batch can be flushed as a single message.
        _pendingResults.clear();

        for (final toolUse in toolUseBlocks) {
          // Only the first confirmation-required command is executed in this
          // batch. Answering the rest with an explicit "not executed" result
          // keeps the batch complete and tells the model to ask again.
          if (deferred != null) {
            final command = await _findCommand(toolUse.name);
            if (command?.requiresConfirmation ?? false) {
              _log(
                  '_processConversation: deferring extra confirmation-required '
                  'tool "${toolUse.name}" to a later turn');
              _pendingResults.add(ToolResultPart(
                toolUseId: toolUse.id,
                result: {
                  'status': 'not_executed',
                  'reason': 'Only one operation requiring confirmation can be '
                      'handled at a time. Request this one again in a '
                      'follow-up turn.',
                },
              ));
              continue;
            }
          }

          _log('_processConversation: executing tool "${toolUse.name}"');
          final result = await _executeToolUse(toolUse);

          if (result.requiresConfirmation) {
            _log('_processConversation: tool requires confirmation');
            // Hold the batch open — the result is added once the user decides.
            deferred = result.pendingConfirmation;
          } else {
            _log(
                '_processConversation: tool result: ${result.isError ? "ERROR" : "SUCCESS"}');
            _pendingResults.add(ToolResultPart(
              toolUseId: toolUse.id,
              result: result.data,
              isError: result.isError,
            ));
          }
        }

        if (deferred != null) {
          // Surface the dialog only now that every sibling tool has finished,
          // so confirming cannot re-enter _processConversation mid-loop.
          _log('_processConversation: waiting for user confirmation');
          _pendingConfirmation = deferred;
          notifyListeners();
          return;
        }

        _flushPendingResults();

        // Restore loading state before continuing loop
        _log('_processConversation: continuing to next loop iteration');
        _state = _state.loading();
        notifyListeners();
      } on GenUiException catch (e) {
        _log('_processConversation: GenUiException: ${e.message}');
        _abandonBatch(deferred);
        _state = _state.withError(e.message, retryable: e.isRetryable);
        notifyListeners();
        return;
      } catch (e) {
        _log('_processConversation: unexpected error: $e');
        _abandonBatch(deferred);
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

  /// Look up a command by name, or null when it is not registered.
  ///
  /// Cached alongside [_routerTools] so a batch does not re-query the provider
  /// once per tool.
  Future<RouterCommand?> _findCommand(String name) async {
    if (_commandsByName == null) {
      final commands = await _commandProvider.listCommands();
      _commandsByName = {for (final c in commands) c.name: c};
    }
    return _commandsByName![name];
  }

  /// Wind down a batch that failed part-way through.
  ///
  /// Any tools that already ran are answered so the assistant turn is not left
  /// with unanswered `tool_use` blocks, and a confirmation discovered before
  /// the failure is still surfaced so the user's write request is not lost.
  void _abandonBatch(PendingConfirmation? deferred) {
    if (deferred != null) {
      _log(
          '_abandonBatch: keeping confirmation for "${deferred.command.name}"');
      _pendingConfirmation = deferred;
      return;
    }
    _flushPendingResults();
  }

  /// Emit [_pendingResults] as a single tool result message and clear the batch.
  ///
  /// Does nothing when the batch is empty, since a tool result message with no
  /// content is not valid.
  void _flushPendingResults() {
    if (_pendingResults.isEmpty) return;
    _log('_flushPendingResults: emitting ${_pendingResults.length} result(s) '
        'in one message');
    _state = _state.withMessage(
      ChatMessage.toolResults(List.of(_pendingResults)),
    );
    _pendingResults.clear();
    notifyListeners();
  }

  /// Execute a single tool use block.
  ///
  /// When the command requires confirmation this only *reports* that fact — it
  /// deliberately does not set [_pendingConfirmation] or notify listeners, so
  /// the dialog cannot appear while sibling tools are still executing.
  Future<_ToolExecutionResult> _executeToolUse(ToolUseBlock toolUse) async {
    final command = await _findCommand(toolUse.name);

    if (command == null) {
      return _ToolExecutionResult(
        data: {'error': 'Unknown command: ${toolUse.name}'},
        isError: true,
      );
    }

    // Check if confirmation required
    if (command.requiresConfirmation) {
      return _ToolExecutionResult(
        requiresConfirmation: true,
        pendingConfirmation: PendingConfirmation(
          command: command,
          params: toolUse.input,
          toolUse: toolUse,
        ),
      );
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

    final generation = _conversationGeneration;
    _pendingConfirmation = null;
    _state = _state.loading();
    notifyListeners();

    try {
      final result = await _commandProvider.execute(
        pending.command.name,
        pending.params,
      );

      // Complete the batch this confirmation belongs to, then flush it as one
      // message so every tool_use in the assistant turn is answered together.
      _pendingResults.add(ToolResultPart(
        toolUseId: pending.toolUse.id,
        result: result.success
            ? {...result.data, 'status': 'executed'}
            : {'error': result.error ?? 'Operation failed'},
        isError: !result.success,
      ));
      if (!_completeBatch(generation)) return;

      // Continue conversation to get LLM's follow-up response
      await _processConversation();
    } catch (e) {
      _pendingResults.add(ToolResultPart(
        toolUseId: pending.toolUse.id,
        result: {'error': e.toString()},
        isError: true,
      ));
      if (!_completeBatch(generation)) return;

      // Still continue to get LLM response about the error
      await _processConversation();
    }
  }

  /// Flush the batch unless the conversation moved on while we were awaiting.
  ///
  /// Returns false when [generation] is stale — the results belong to a
  /// conversation that has since been cleared, so emitting them would leave a
  /// `tool_result` with no matching `tool_use` and break every later request.
  bool _completeBatch(int generation) {
    if (generation != _conversationGeneration) {
      _log('_completeBatch: conversation was reset, discarding '
          '${_pendingResults.length} stale result(s)');
      _pendingResults.clear();
      return false;
    }
    _flushPendingResults();
    return true;
  }

  /// Cancel the pending action.
  ///
  /// Called when user declines a write/admin operation.
  /// Adds cancellation tool_result and continues conversation.
  Future<void> cancelPendingAction() async {
    final pending = _pendingConfirmation;
    if (pending == null) return;

    final generation = _conversationGeneration;
    _pendingConfirmation = null;
    _state = _state.loading();
    notifyListeners();

    // Complete the batch with the cancellation, then flush it as one message.
    _pendingResults.add(ToolResultPart(
      toolUseId: pending.toolUse.id,
      result: {
        'status': 'cancelled',
        'message': 'User declined to execute ${pending.command.name}',
      },
    ));
    if (!_completeBatch(generation)) return;

    // Continue conversation to get LLM's response to cancellation
    await _processConversation();
  }

  /// Handle tool action from A2UI component.
  Future<void> handleToolAction(ToolActionOutput action) async {
    // A UI action answers a single rendered component, so it is its own batch.
    // Close out whatever the previous turn left open first — including a
    // confirmation the user never answered, whose tool_use would otherwise stay
    // unanswered while this action's result is appended.
    _insertPendingToolResults();

    final toolResultMessage = action.toChatMessage();
    _state = _state.withMessage(toolResultMessage);
    _state = _state.toolActionCompleted();
    notifyListeners();

    _state = _state.loading();
    notifyListeners();

    await _processConversation();
  }

  /// Answer any `tool_use` blocks of the trailing assistant message that do not
  /// have a result yet.
  ///
  /// This happens when the previous turn ended without completing its batch —
  /// for example the user typed a new message instead of answering a pending
  /// confirmation dialog. Leaving a `tool_use` unanswered makes the API reject
  /// the next request, so the gaps are filled with an acknowledgment.
  void _insertPendingToolResults() {
    // A confirmation is still open: drop it and abandon its batch, otherwise
    // the stale results would be flushed alongside the next turn's.
    _pendingConfirmation = null;
    _pendingResults.clear();

    if (_state.messages.isEmpty) return;

    // Walk back to the trailing assistant message, collecting the tool_use ids
    // already answered along the way.
    ChatMessage? lastAssistantMessage;
    final answeredIds = <String>{};
    for (var i = _state.messages.length - 1; i >= 0; i--) {
      final msg = _state.messages[i];
      if (msg.isAssistant) {
        lastAssistantMessage = msg;
        break;
      }
      if (msg.isToolResult) {
        final parts = msg.content;
        if (parts is List<ContentPart>) {
          answeredIds.addAll(
            parts.whereType<ToolResultPart>().map((p) => p.toolUseId),
          );
        }
      }
    }

    final response = lastAssistantMessage?.response;
    if (response == null) return;

    final unanswered = response.content
        .whereType<ToolUseBlock>()
        .where((block) => !answeredIds.contains(block.id))
        .toList();
    if (unanswered.isEmpty) return;

    _log('_insertPendingToolResults: answering ${unanswered.length} '
        'unanswered tool_use block(s)');
    _state = _state.withMessage(ChatMessage.toolResults([
      for (final toolUse in unanswered)
        ToolResultPart(
          toolUseId: toolUse.id,
          result: _abandonedToolResult(toolUse.name),
        ),
    ]));
    notifyListeners();
  }

  /// Result body for a `tool_use` the user walked away from.
  ///
  /// Router commands must not be reported as done — they never ran. Anything
  /// that is not a known command is an A2UI component, which really was
  /// rendered, so the original acknowledgment still applies.
  Map<String, dynamic> _abandonedToolResult(String toolName) {
    if (_commandsByName?.containsKey(toolName) ?? false) {
      return {
        'status': 'not_executed',
        'reason': 'The user moved on without responding to the confirmation.',
      };
    }
    return {'status': 'rendered', 'component': toolName};
  }

  /// Retry the last failed operation.
  Future<void> retry() async {
    if (!_state.hasError || _lastUserMessage == null) return;

    // Drop the trailing user message so [sendMessage] can re-add it. Tool
    // result messages also carry the user role, but they answer a preceding
    // assistant turn and hold real device data — removing one would both
    // orphan that turn's tool_use and destroy the result.
    final messages = [..._state.messages];
    final trailing = messages.isEmpty ? null : messages.last;
    final removedUserTurn = trailing != null &&
        trailing.role == ChatRole.user &&
        !trailing.isToolResult;
    if (removedUserTurn) {
      messages.removeLast();
    }

    _state = ConversationState(
      viewState: ChatViewState.content,
      messages: messages,
    );
    notifyListeners();

    if (removedUserTurn) {
      await sendMessage(_lastUserMessage!);
    } else {
      // The user turn is still in history (the failure happened after tools
      // ran), so resume the exchange instead of duplicating the question.
      _state = _state.loading();
      notifyListeners();
      await _processConversation();
    }
  }

  /// Clear conversation and reset state.
  void clearConversation() {
    _log(
        'clearConversation: session summary - input: $_totalInputTokens, output: $_totalOutputTokens, cacheRead: $_totalCacheReadTokens, cacheWrite: $_totalCacheWriteTokens');
    _state = ConversationState.initial();
    // Invalidate any in-flight confirmation so it cannot inject its result into
    // the new conversation once the device responds.
    _conversationGeneration++;
    _pendingConfirmation = null;
    _pendingResults.clear();
    _lastUserMessage = null;
    _routerTools = null;
    _commandsByName = null;
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

  /// Set when [requiresConfirmation] is true — the confirmation the caller
  /// should surface once the rest of the batch has finished executing.
  final PendingConfirmation? pendingConfirmation;

  const _ToolExecutionResult({
    this.data = const {},
    this.isError = false,
    this.requiresConfirmation = false,
    this.pendingConfirmation,
  });
}
