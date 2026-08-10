import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:generative_ui/generative_ui.dart';

import 'package:privacy_gui/ai/ai_logging.dart';
import 'package:privacy_gui/ai/abstraction/_abstraction.dart';
import 'package:privacy_gui/ai/prompts/router_system_prompt.dart';

/// Most LLM round-trips one exchange may take before it is cut off.
///
/// A fuse against a model that keeps requesting data instead of answering, not
/// a budget the user is meant to feel.
const int _maxLoops = 5;

/// Results accumulated for one assistant turn, owned by the exchange that
/// opened it.
///
/// Pairing the results with the generation they belong to is what makes
/// staleness safe to act on: work resuming after an `await` holds a reference
/// to *its own* batch, so it can never read, clear, or append to results that
/// belong to a later exchange.
class ToolResultBatch {
  ToolResultBatch(this.generation);

  /// Conversation generation this batch was opened in.
  final int generation;

  /// Tool results collected so far, in execution order.
  ///
  /// Order does not have to match the assistant's `tool_use` order — a
  /// confirmed write is appended after its siblings — because the API matches
  /// results to requests by `tool_use_id`. What matters is that they all arrive
  /// in the single user message following the assistant turn.
  final List<ToolResultPart> results = [];
}

/// Pending confirmation state for write/admin operations.
class PendingConfirmation extends Equatable {
  final RouterCommand command;
  final Map<String, dynamic> params;
  final ToolUseBlock toolUse;

  /// The batch this confirmation was raised from. Its result rejoins that
  /// batch's siblings, and its generation decides whether the batch may still
  /// be emitted — so a confirmation answered after the conversation moved on
  /// cannot inject an orphaned `tool_result`.
  final ToolResultBatch batch;

  const PendingConfirmation({
    required this.command,
    required this.params,
    required this.toolUse,
    required this.batch,
  });

  @override
  List<Object?> get props => [command, params, toolUse, batch];
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
/// follows it. Results are therefore accumulated in a [ToolResultBatch] and
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
    // The router context is the user's network: model, IP addresses, SSIDs,
    // device names. Debug builds only.
    aiLogSensitive(() => 'Router context:\n$routerContext');
    _initializeSystemPrompt();
  }

  static void _log(String message) => aiLog(message);

  // Tool result `status` values. These are part of the protocol the model
  // reads, so they are defined once rather than spelled out at each site.
  static const _statusExecuted = 'executed';
  static const _statusCancelled = 'cancelled';
  static const _statusNotExecuted = 'not_executed';
  static const _statusRendered = 'rendered';

  final IConversationGenerator _generator;
  final IRouterCommandProvider _commandProvider;
  final String _routerContext;

  ConversationState _state = ConversationState.initial();
  PendingConfirmation? _pendingConfirmation;
  String? _lastUserMessage;
  List<SystemPromptPart>? _systemPromptParts;
  List<GenTool>? _routerTools;
  Map<String, RouterCommand>? _commandsByName;
  Future<Map<String, RouterCommand>>? _commandsLoad;

  /// The batch currently accumulating results, or null between exchanges.
  ///
  /// Owning the results together with the generation they belong to is what
  /// makes staleness safe to act on: work returning from an `await` can only
  /// ever touch *its own* batch, so it can never clear or append to results
  /// belonging to a later exchange.
  ToolResultBatch? _batch;

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

  /// Which round-trip of the current exchange is in flight, or 0 when idle.
  ///
  /// Exists so the view can say something true while the user waits. A single
  /// question can take several LLM calls — each round asks for data the previous
  /// round revealed it needed — and the intermediate responses are invisible
  /// (they carry only `tool_use`, which is not for the user to read). Without
  /// this the wait is indistinguishable from a hang.
  int get currentRound => _currentRound;
  int _currentRound = 0;

  /// The most rounds one exchange may take before it is cut off.
  ///
  /// Exposed so the view can show progress relative to a known bound rather
  /// than an open-ended counter.
  static const int maxRounds = _maxLoops;

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

  /// Load the command registry once per conversation.
  ///
  /// Both the tool definitions sent to the model and the per-name lookup are
  /// derived here so the provider is queried once, and the two views cannot
  /// drift apart. The future itself is cached so concurrent first calls share
  /// one query.
  Future<Map<String, RouterCommand>> _loadCommands() {
    final cached = _commandsLoad;
    if (cached != null) return cached;

    final load = _commandProvider.listCommands().then((commands) {
      _routerTools = commands
          .map((cmd) => GenTool(
                name: cmd.name,
                description: cmd.description,
                inputSchema: cmd.inputSchema,
              ))
          .toList();
      return _commandsByName = {for (final c in commands) c.name: c};
    });

    // Drop a rejected load so a transient provider failure does not stick for
    // the rest of the conversation.
    _commandsLoad = load.catchError((Object e) {
      _commandsLoad = null;
      throw e;
    });
    return _commandsLoad!;
  }

  /// Tool definitions for the model, loading the registry if needed.
  Future<List<GenTool>> _getRouterTools() async {
    await _loadCommands();
    // Set by the load above; the map and the list are always populated together.
    return _routerTools ?? const [];
  }

  /// Send a user message and process response.
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    aiLogSensitive(
      () => 'sendMessage: "$message"',
      orElse: () => 'sendMessage: ${message.length} chars',
    );
    _lastUserMessage = message;

    // Insert pending tool results if needed
    _closeOutOpenBatch();

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
    // Wrapped rather than guarded inline: the body has eleven exit paths, and
    // clearing the round at each one is the kind of bookkeeping that gets
    // forgotten when a twelfth is added. A `finally` here covers every return
    // and every throw, without reindenting the body.
    try {
      await _runConversation();
    } finally {
      if (_currentRound != 0) {
        _currentRound = 0;
        notifyListeners();
      }
    }
  }

  Future<void> _runConversation() async {
    // This exchange owns its own batch, stamped with the generation it belongs
    // to. Every await below is a point where the user can reset the
    // conversation; because results live on the batch rather than in shared
    // state, work resuming afterwards can only ever discard its own.
    final batch = ToolResultBatch(_conversationGeneration);
    _batch = batch;

    final List<GenTool> tools;
    try {
      tools = await _getRouterTools();
    } catch (e) {
      _log('_processConversation: loading commands failed: $e');
      if (_isStale(batch)) return;
      _state = _state.withError('An unexpected error occurred: $e');
      notifyListeners();
      return;
    }
    if (_isStale(batch)) return;

    var loopCount = 0;
    const maxLoops = _maxLoops;

    _log(
        '_processConversation: starting loop (${tools.length} tools available)');

    while (loopCount < maxLoops) {
      loopCount++;
      // Published before the call so the view can describe the wait it is
      // about to sit through, not the one that just ended.
      _currentRound = loopCount;
      notifyListeners();
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
        if (_isStale(batch)) return;
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
        batch.results.clear();

        for (final toolUse in toolUseBlocks) {
          // Every tool is wrapped so that a failure anywhere — including a
          // provider lookup — still yields a result. Leaving one unanswered
          // would make the next request invalid.
          try {
            // Only the first confirmation-required command is executed in this
            // batch. Answering the rest with an explicit "not executed" result
            // keeps the batch complete and tells the model to ask again.
            if (deferred != null) {
              final command = await _findCommand(toolUse.name);
              if (_isStale(batch)) return;
              if (command?.requiresConfirmation ?? false) {
                _log(
                    '_processConversation: deferring extra confirmation-required '
                    'tool "${toolUse.name}" to a later turn');
                batch.results.add(ToolResultPart(
                  toolUseId: toolUse.id,
                  result: {
                    'status': _statusNotExecuted,
                    'reason':
                        'Only one operation requiring confirmation can be '
                            'handled at a time. Request this one again in a '
                            'follow-up turn.',
                  },
                ));
                continue;
              }
            }

            _log('_processConversation: executing tool "${toolUse.name}"');
            final result = await _executeToolUse(toolUse, batch);
            if (_isStale(batch)) return;

            if (result.requiresConfirmation) {
              _log('_processConversation: tool requires confirmation');
              // Hold the batch open — the result is added once the user decides.
              deferred = result.pendingConfirmation;
            } else {
              _log(
                  '_processConversation: tool result: ${result.isError ? "ERROR" : "SUCCESS"}');
              batch.results.add(ToolResultPart(
                toolUseId: toolUse.id,
                result: result.data,
                isError: result.isError,
              ));
            }
          } catch (e) {
            _log('_processConversation: tool "${toolUse.name}" threw: $e');
            batch.results.add(ToolResultPart(
              toolUseId: toolUse.id,
              result: {'error': e.toString()},
              isError: true,
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

        if (!_completeBatch(batch)) return;

        // Restore loading state before continuing loop
        _log('_processConversation: continuing to next loop iteration');
        _state = _state.loading();
        notifyListeners();
      } on GenUiException catch (e) {
        _log('_processConversation: GenUiException: ${e.message}');
        _abandonBatch(batch, deferred);
        _state = _state.withError(e.message, retryable: e.isRetryable);
        notifyListeners();
        return;
      } catch (e) {
        _log('_processConversation: unexpected error: $e');
        _abandonBatch(batch, deferred);
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
  Future<RouterCommand?> _findCommand(String name) async =>
      (await _loadCommands())[name];

  /// Whether [batch] belongs to a conversation that has since been reset.
  ///
  /// A pure predicate — it deliberately touches no state, so a losing exchange
  /// cannot disturb the one that replaced it. Work resuming after an `await`
  /// checks this before writing anything: a `tool_result` landing in a
  /// conversation it does not belong to has no matching `tool_use` and
  /// invalidates every later request.
  bool _isStale(ToolResultBatch batch) {
    if (batch.generation == _conversationGeneration) return false;
    _log('_isStale: conversation moved on (batch gen ${batch.generation}, '
        'current $_conversationGeneration) — abandoning this exchange');
    return true;
  }

  /// Wind down a batch that failed part-way through.
  ///
  /// Any tools that already ran are answered so the assistant turn is not left
  /// with unanswered `tool_use` blocks, and a confirmation discovered before
  /// the failure is still surfaced so the user's write request is not lost.
  void _abandonBatch(ToolResultBatch batch, PendingConfirmation? deferred) {
    if (deferred != null) {
      // Re-arming only makes sense while the batch still owns the conversation.
      if (_isStale(batch)) return;
      _log(
          '_abandonBatch: keeping confirmation for "${deferred.command.name}"');
      _pendingConfirmation = deferred;
      return;
    }
    _completeBatch(batch);
  }

  /// Emit [batch]'s results as a single tool result message.
  ///
  /// Returns false when the batch no longer owns the conversation, in which
  /// case nothing is written. Does nothing for an empty batch either, since a
  /// tool result message with no content is not valid.
  bool _completeBatch(ToolResultBatch batch) {
    if (_isStale(batch)) {
      _log(
          '_completeBatch: discarding ${batch.results.length} stale result(s)');
      batch.results.clear();
      return false;
    }
    if (batch.results.isNotEmpty) {
      _log('_completeBatch: emitting ${batch.results.length} result(s) '
          'in one message');
      // Copy: the message must not alias a list this batch still owns.
      _state = _state.withMessage(
        ChatMessage.toolResults(List.of(batch.results)),
      );
      // Emptied so a later wind-down of the same batch cannot re-emit them.
      batch.results.clear();
      notifyListeners();
    }
    if (_batch == batch) _batch = null;
    return true;
  }

  /// Execute a single tool use block.
  ///
  /// When the command requires confirmation this only *reports* that fact — it
  /// deliberately does not set [_pendingConfirmation] or notify listeners, so
  /// the dialog cannot appear while sibling tools are still executing.
  Future<_ToolExecutionResult> _executeToolUse(
    ToolUseBlock toolUse,
    ToolResultBatch batch,
  ) async {
    final command = await _findCommand(toolUse.name);

    if (command == null) {
      return _ToolExecutionResult(
        data: {'error': 'Unknown command: ${toolUse.name}'},
        isError: true,
      );
    }

    // Check if confirmation required
    if (command.requiresConfirmation) {
      return _ToolExecutionResult.awaitingConfirmation(
        PendingConfirmation(
          command: command,
          params: toolUse.input,
          toolUse: toolUse,
          batch: batch,
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

    // The confirmation carries the batch it belongs to, so the result joins
    // that batch's siblings — not whatever is open when the user answers.
    final batch = pending.batch;
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
      batch.results.add(ToolResultPart(
        toolUseId: pending.toolUse.id,
        result: result.success
            // Nested so a 'status' field the device itself returns is not
            // silently overwritten by ours.
            ? {'status': _statusExecuted, 'result': result.data}
            : {'error': result.error ?? 'Operation failed'},
        isError: !result.success,
      ));
      if (!_completeBatch(batch)) return;

      // Continue conversation to get LLM's follow-up response
      await _processConversation();
    } catch (e) {
      batch.results.add(ToolResultPart(
        toolUseId: pending.toolUse.id,
        result: {'error': e.toString()},
        isError: true,
      ));
      if (!_completeBatch(batch)) return;

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

    // The cancellation joins the batch the confirmation came from.
    final batch = pending.batch;
    _pendingConfirmation = null;
    _state = _state.loading();
    notifyListeners();

    // Complete the batch with the cancellation, then flush it as one message.
    batch.results.add(ToolResultPart(
      toolUseId: pending.toolUse.id,
      result: {
        'status': _statusCancelled,
        'message': 'User declined to execute ${pending.command.name}',
      },
    ));
    if (!_completeBatch(batch)) return;

    // Continue conversation to get LLM's response to cancellation
    await _processConversation();
  }

  /// Handle tool action from A2UI component.
  Future<void> handleToolAction(ToolActionOutput action) async {
    // Close out whatever the previous turn left open first — including a
    // confirmation the user never answered, whose tool_use would otherwise stay
    // unanswered while this action's result is appended. The id this action
    // answers is excluded so it is not answered twice.
    _closeOutOpenBatch(except: {action.toolUseId});

    final toolResultMessage = action.toChatMessage();
    _state = _state.withMessage(toolResultMessage);
    _state = _state.toolActionCompleted();
    notifyListeners();

    _state = _state.loading();
    notifyListeners();

    await _processConversation();
  }

  /// Close out the previous turn before starting a new one.
  ///
  /// Called when the user moves on without completing a batch — typing a new
  /// message instead of answering a confirmation dialog, or triggering a UI
  /// action. Leaving a `tool_use` unanswered makes the API reject the next
  /// request, so any gap in the trailing assistant turn is filled.
  ///
  /// Results already computed for that turn are **preserved** — they hold real
  /// device data — and only the genuinely missing ids are synthesised. The
  /// generation is always bumped, so anything still in flight for the closed
  /// batch (a confirmation awaiting the device, or an LLM call mid-request)
  /// cannot come back and answer an id this method just answered.
  void _closeOutOpenBatch({Set<String> except = const {}}) {
    final hadConfirmation = _pendingConfirmation != null;
    _pendingConfirmation = null;

    // Results computed for the turn being closed are real; keep them and only
    // fill the gaps below.
    final closed = _batch;
    _batch = null;

    // Bump only when work for the closed batch may still be in flight — an
    // unanswered confirmation awaiting the device, or a batch left open by an
    // exchange that has not finished. A batch that already completed sets
    // _batch to null, so a normal turn does not invalidate the next one.
    if (hadConfirmation || closed != null) {
      _conversationGeneration++;
    }

    final carried = closed == null
        ? <ToolResultPart>[]
        : List<ToolResultPart>.of(closed.results);

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

    // Carried results answer their ids too — do not synthesise over them.
    answeredIds.addAll(carried.map((p) => p.toolUseId));
    // Ids the caller is about to answer itself.
    answeredIds.addAll(except);

    final synthesised = [
      for (final block in response.content.whereType<ToolUseBlock>())
        if (!answeredIds.contains(block.id))
          ToolResultPart(
            toolUseId: block.id,
            result: _abandonedToolResult(block.name),
          ),
    ];

    final parts = [...carried, ...synthesised];
    if (parts.isEmpty) return;

    _log('_closeOutOpenBatch: emitting ${carried.length} carried + '
        '${synthesised.length} synthesised result(s)');
    _state = _state.withMessage(ChatMessage.toolResults(parts));
    notifyListeners();
  }

  /// Result body for a `tool_use` the user walked away from.
  ///
  /// A router command must never be reported as done — it never ran. Only names
  /// the registry positively confirms are *not* commands are treated as A2UI
  /// components, which genuinely were rendered. When the registry is unavailable
  /// the answer falls to `not_executed`: claiming an unexecuted write succeeded
  /// is the harmful direction to be wrong in.
  Map<String, dynamic> _abandonedToolResult(String toolName) {
    final registry = _commandsByName;
    final isKnownComponent =
        registry != null && !registry.containsKey(toolName);
    if (isKnownComponent) {
      return {'status': _statusRendered, 'component': toolName};
    }
    return {
      'status': _statusNotExecuted,
      'reason': 'The user moved on without responding to the confirmation.',
    };
  }

  /// Retry the last failed operation.
  Future<void> retry() async {
    if (!_state.hasError || _lastUserMessage == null) return;

    // A batch that failed while holding a confirmation still owns its results
    // and the user's write request. Retrying would clear both and leave the
    // assistant turn unanswered, so the confirmation takes precedence — the
    // user must answer the dialog first.
    if (_pendingConfirmation != null) {
      _log('retry: ignored — a confirmation is still awaiting the user');
      notifyListeners();
      return;
    }

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
    _batch = null;
    _lastUserMessage = null;
    _routerTools = null;
    _commandsByName = null;
    _commandsLoad = null;
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

  /// Test seam for [_abandonedToolResult], which is otherwise only reachable
  /// through a specific abandonment sequence.
  @visibleForTesting
  Map<String, dynamic> debugAbandonedToolResultFor(String toolName) =>
      _abandonedToolResult(toolName);
}

/// Internal result type for tool execution.
class _ToolExecutionResult {
  final Map<String, dynamic> data;
  final bool isError;

  /// The confirmation the caller must surface once the rest of the batch has
  /// finished, or null when the tool ran to completion.
  final PendingConfirmation? pendingConfirmation;

  const _ToolExecutionResult({
    this.data = const {},
    this.isError = false,
  }) : pendingConfirmation = null;

  /// The tool was not run because it needs the user to confirm first.
  const _ToolExecutionResult.awaitingConfirmation(
    PendingConfirmation this.pendingConfirmation,
  )   : data = const {},
        isError = false;

  /// Whether the caller must surface [pendingConfirmation] instead of recording
  /// a result. Cannot disagree with [pendingConfirmation] being set.
  bool get requiresConfirmation => pendingConfirmation != null;
}
