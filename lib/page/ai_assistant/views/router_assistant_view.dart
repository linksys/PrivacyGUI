import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/ai/_ai.dart';
import 'package:privacy_gui/ai/ai_logging.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/ai_assistant/providers/router_command_provider.dart';
import 'package:privacy_gui/page/ai_assistant/services/aws_credentials_store.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_hero_widget.dart';

/// Available Bedrock model options.
class BedrockModel {
  final String id;
  final String displayName;

  const BedrockModel(this.id, this.displayName);

  static const models = [
    BedrockModel(
        'us.anthropic.claude-haiku-4-5-20251001-v1:0', 'Haiku 4.5 (Fast)'),
    BedrockModel('us.anthropic.claude-sonnet-4-6', 'Sonnet 4.6'),
    BedrockModel('us.anthropic.claude-sonnet-4-5-20250929-v1:0', 'Sonnet 4.5'),
    BedrockModel('us.anthropic.claude-opus-4-8', 'Opus 4.8 (Most Capable)'),
    BedrockModel('us.anthropic.claude-opus-4-7', 'Opus 4.7'),
  ];
}

/// Main view for the Router AI Assistant.
///
/// Shows configuration form if AWS credentials are not available,
/// otherwise shows the chat interface.
class RouterAssistantView extends ConsumerStatefulWidget {
  const RouterAssistantView({super.key});

  @override
  ConsumerState<RouterAssistantView> createState() =>
      _RouterAssistantViewState();
}

class _RouterAssistantViewState extends ConsumerState<RouterAssistantView> {
  late final IComponentRegistry _registry;
  RouterChatController? _controller;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  // Configuration state
  bool _needsConfig = false;

  /// Why the last connection attempt failed, or null when there is nothing to
  /// report.
  ///
  /// Two distinct kinds, kept apart because they localize differently:
  ///
  /// * [_ConfigError.missingFields] — form validation. Per Art. XIII §1.4 this
  ///   is a separate line from `ServiceError` and has its own l10n key.
  /// * [_ConfigError.failure] — a real failure, carrying a `ServiceError` that
  ///   `localizeServiceError` turns into the displayed message.
  ///
  /// Absent from this set on purpose: "environment config is unavailable".
  /// `AWSConfig.fromEnvironment()` throwing `ConfigurationException` is the
  /// normal path — it is how the app discovers it should show the manual form —
  /// so it is logged and never shown as an error.
  _ConfigError? _configError;
  final _accessKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  BedrockModel _selectedModel = BedrockModel.models.first;
  bool _isConfiguring = false;

  /// True while saved credentials are being read on startup.
  ///
  /// Every input on the config screen is sealed for this window, which is what
  /// makes the restore safe: landing after the user started typing would
  /// otherwise overwrite their input and connect with credentials other than
  /// the ones they entered. It is therefore always cleared — see
  /// [_restoreSavedCredentials] — because a stuck flag locks the user out of
  /// the only screen they can act on.
  bool _isRestoring = false;

  /// How long to wait for stored credentials before showing an empty form.
  ///
  /// Shorter than the store's own timeout so the user is never left looking at
  /// a disabled screen for long; the restore is a convenience, and typing the
  /// credentials again is a worse outcome than waiting but not a broken one.
  static const _restoreTimeout = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _registry = RouterComponentRegistry.create();
    _tryInitController();
    if (_needsConfig) {
      // Environment config was unavailable; fall back to whatever the user
      // saved on a previous run before asking them to type it again.
      _isRestoring = true;
      _restoreSavedCredentials();
    }
  }

  void _tryInitController() {
    final commandProvider = ref.read(routerCommandProviderProvider);

    try {
      final awsConfig = AWSConfig.fromEnvironment();
      _controller = RouterChatController(
        generator: AwsContentGenerator(config: awsConfig),
        commandProvider: commandProvider,
        routerContext: buildRouterContext(ref.read),
      );
      _controller!.addListener(_onControllerChanged);
      _needsConfig = false;
      _configError = null;
    } on ConfigurationException catch (e) {
      // Not an error: no environment credentials is the ordinary case, and the
      // manual form is the correct next screen. Showing "AWS_ACCESS_KEY_ID not
      // set" would report the app's own configuration as the user's problem.
      aiLog('RouterAssistantView: No environment config (${e.missingKey})');
      _needsConfig = true;
      _configError = null;
    } catch (e) {
      // Full text in the log: per the error-handling guide, detail/code are
      // diagnostic material for the engineer. Only the UI is restricted.
      aiLog('RouterAssistantView: could not build controller from '
          'environment config: $e');
      _needsConfig = true;
      _configError = _ConfigError.failure(UnexpectedError(originalError: e));
    }
  }

  /// Connect with credentials saved on a previous run, if there are any.
  ///
  /// Failing to restore is not surfaced as an error: the config screen is
  /// already the correct next step, and the message there should describe why
  /// configuration is needed, not that a restore attempt failed.
  ///
  /// Bounded by [_restoreTimeout] and cleared in a `finally`, so a read that
  /// never settles cannot leave the config screen disabled with no way out —
  /// the Change-configuration button that also clears the flag lives on the
  /// chat screen, which is unreachable while configuration is needed.
  Future<void> _restoreSavedCredentials() async {
    final store = ref.read(awsCredentialsStoreProvider);

    StoredAwsCredentials? stored;
    try {
      stored = await store.read().timeout(_restoreTimeout);
    } catch (e) {
      _logStorageFailure('read saved credentials')(e);
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }

    if (!mounted) return;

    final saved = stored;
    // Stand down if a session already exists: replacing a live controller would
    // orphan its listener and discard the conversation the user can see.
    if (saved == null || _controller != null) return;

    final model = BedrockModel.models.firstWhere(
      (m) => m.id == saved.modelId,
      // The saved model may no longer be offered; connect with the default
      // rather than discarding otherwise-valid credentials.
      orElse: () => BedrockModel.models.first,
    );

    setState(() {
      _accessKeyController.text = saved.accessKeyId;
      _secretKeyController.text = saved.secretAccessKey;
      _selectedModel = model;
    });
    _initControllerWithManualConfig(persist: false);
  }

  /// Build the controller from the fields on the config screen.
  ///
  /// [persist] is false when the fields were themselves populated from storage,
  /// so a restore does not rewrite what it just read.
  void _initControllerWithManualConfig({bool persist = true}) {
    final accessKeyId = _accessKeyController.text.trim();
    final secretAccessKey = _secretKeyController.text.trim();
    if (accessKeyId.isEmpty || secretAccessKey.isEmpty) {
      setState(() {
        _configError = const _ConfigError.missingFields();
      });
      return;
    }

    setState(() {
      _isConfiguring = true;
      _configError = null;
    });

    try {
      final commandProvider = ref.read(routerCommandProviderProvider);
      final awsConfig = AWSConfig(
        accessKeyId: accessKeyId,
        secretAccessKey: secretAccessKey,
        region: 'us-west-2',
        modelId: _selectedModel.id,
      );

      _controller = RouterChatController(
        generator: AwsContentGenerator(config: awsConfig),
        commandProvider: commandProvider,
        routerContext: buildRouterContext(ref.read),
      );
      _controller!.addListener(_onControllerChanged);

      setState(() {
        _needsConfig = false;
        _isConfiguring = false;
      });

      if (persist) {
        // Fire-and-forget: a storage failure must not block a working session.
        // Logged, not shown — the session is fine and the user has nothing to
        // act on; the only consequence is re-entering credentials next launch.
        ref
            .read(awsCredentialsStoreProvider)
            .store(
              accessKeyId: accessKeyId,
              secretAccessKey: secretAccessKey,
              modelId: _selectedModel.id,
            )
            .catchError(_logStorageFailure('save credentials'));
      }
    } catch (e) {
      aiLog('RouterAssistantView: could not connect with manual config: $e');
      setState(() {
        _configError = _ConfigError.failure(UnexpectedError(originalError: e));
        _isConfiguring = false;
      });
    }
  }

  /// Handler for the fire-and-forget storage calls.
  ///
  /// The store throws only [ServiceError]s, so there is nothing to map here.
  /// These are logged and never shown: see [_configError] for why.
  ///
  /// `originalError` is logged explicitly because `ServiceError.toString()`
  /// renders only the type name — without it a storage failure would log the
  /// uninformative "Storage" and nothing about what actually went wrong.
  void Function(Object) _logStorageFailure(String action) {
    return (Object e) {
      final cause = e is StorageError ? e.originalError : null;
      aiLog('RouterAssistantView: could not $action: $e'
          '${cause != null ? ' ($cause)' : ''}');
    };
  }

  void _onControllerChanged() {
    setState(() {});
    _scrollToBottom();

    if (_controller?.hasPendingConfirmation == true) {
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    final pending = _controller?.pendingConfirmation;
    if (pending == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: AppText.titleMedium(loc(context).confirmationRequired),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium(loc(context).confirmExecuteOperation),
            const SizedBox(height: 12),
            AppSurface(
              variant: SurfaceVariant.elevated,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelMedium(pending.command.name),
                    const SizedBox(height: 4),
                    AppText.bodySmall(pending.command.description),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () {
              Navigator.pop(ctx);
              _controller?.cancelPendingAction();
            },
          ),
          AppButton.primary(
            label: loc(context).confirm,
            onTap: () {
              Navigator.pop(ctx);
              _controller?.confirmPendingAction();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _accessKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  String _localizeConfigError(BuildContext context, _ConfigError error) {
    // Exhaustive over a sealed type: adding a case forces a localization
    // decision here rather than allowing a raw string to slip through, which is
    // what the previous `return error;` fallback did.
    return switch (error) {
      _MissingFields() => loc(context).fillAllRequiredFields,
      _Failure(:final error) => localizeServiceError(context, error),
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _controller?.isLoading == true) return;

    _inputController.clear();
    await _controller?.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    if (_needsConfig) {
      return _buildConfigScreen();
    }
    return _buildChatScreen();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Configuration Screen
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildConfigScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(loc(context).aiRouterAssistant),
          ],
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Hero(
                  tag: mascotHeroTag,
                  child: const MascotHeroWidget(
                    size: 80,
                    animation: MascotAnimationKey.think,
                  ),
                ),
                const SizedBox(height: 24),
                AppText.headline(
                  loc(context).awsBedrockConfiguration,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                AppText.body(
                  loc(context).enterAwsCredentials,
                  textAlign: TextAlign.center,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 24),
                if (_configError != null) ...[
                  AppSurface(
                    variant: SurfaceVariant.elevated,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: theme.colorScheme.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppText.bodySmall(
                              _localizeConfigError(context, _configError!),
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelMedium(loc(context).awsAccessKeyId),
                    const SizedBox(height: 4),
                    AppTextField(
                      controller: _accessKeyController,
                      hintText: 'AKIA...',
                      readOnly: _isRestoring,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelMedium(loc(context).awsSecretAccessKey),
                    const SizedBox(height: 4),
                    AppPasswordInput(
                      controller: _secretKeyController,
                      hintText: loc(context).enterSecretKey,
                      readOnly: _isRestoring,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModelDropdown(),
                const SizedBox(height: 8),
                AppText.caption(
                  loc(context).regionFixed,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: _isRestoring
                      ? loc(context).loading
                      : (_isConfiguring
                          ? loc(context).connecting
                          : loc(context).connect),
                  // Disabled while restoring: connecting now would race the
                  // restore and leave two controllers fighting over the view.
                  onTap: (_isConfiguring || _isRestoring)
                      ? null
                      : _initControllerWithManualConfig,
                  variant: SurfaceVariant.highlight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModelDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.labelMedium(loc(context).model),
        const SizedBox(height: 4),
        AppDropdown<BedrockModel>(
          value: _selectedModel,
          items: BedrockModel.models,
          itemAsString: (m) => m.displayName,
          onChanged: _isRestoring
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _selectedModel = value);
                  // Keep a stored record in step, so a model changed after a
                  // restore is not silently forgotten on the next launch.
                  ref
                      .read(awsCredentialsStoreProvider)
                      .storeModelId(value.id)
                      .catchError(_logStorageFailure('save model'));
                },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Chat Screen
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildChatScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(loc(context).aiRouterAssistant),
            const SizedBox(width: 8),
            _buildStatusBadge(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showConfigDialog,
            tooltip: loc(context).settings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller?.clearConversation,
            tooltip: loc(context).clearConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildChatArea()),
          if (_controller?.hasError == true) _buildErrorBanner(),
          _buildInputArea(),
        ],
      ),
    );
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: AppText.titleMedium(loc(context).changeConfiguration),
        content: AppText.bodyMedium(loc(context).changeAwsCredentials),
        actions: [
          AppButton.text(
            label: loc(context).cancel,
            onTap: () => Navigator.pop(ctx),
          ),
          AppButton.primary(
            label: loc(context).change,
            onTap: () {
              Navigator.pop(ctx);
              // This is the user's way to remove saved credentials — leaving
              // them in storage would silently restore on the next launch,
              // defeating the change they just asked for.
              ref
                  .read(awsCredentialsStoreProvider)
                  .clear()
                  .catchError(_logStorageFailure('clear credentials'));
              setState(() {
                _controller?.removeListener(_onControllerChanged);
                _controller = null;
                _needsConfig = true;
                _configError = null;
                _accessKeyController.clear();
                _secretKeyController.clear();
                // Reset the model too: leaving the previous account's choice
                // selected would silently connect the next credentials on it.
                _selectedModel = BedrockModel.models.first;
                // No restore is in flight on this path — reaching this button
                // means a session exists — but clear the flag so the fresh
                // config screen is never handed over in a disabled state.
                _isRestoring = false;
                _isConfiguring = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        loc(context).live,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    final messages = _controller?.messages ?? [];

    if (messages.isEmpty ||
        (messages.length == 1 && messages.first.role == ChatRole.system)) {
      return _buildWelcomeScreen();
    }

    final displayMessages =
        messages.where((m) => m.role != ChatRole.system).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          displayMessages.length + (_controller?.isLoading == true ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayMessages.length) {
          return _buildLoadingIndicator();
        }
        return _buildMessageBubble(displayMessages[index]);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 3,
            child: ProcessingGlow.subtle(
              isActive: true,
              glowColor: theme.colorScheme.primary,
              child: AppSurface(
                variant: SurfaceVariant.elevated,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      _AnimatedThinkingText(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: mascotHeroTag,
              child: const MascotHeroWidget(
                size: 80,
                animation: MascotAnimationKey.greet,
              ),
            ),
            const SizedBox(height: 16),
            AppText.headline(loc(context).aiRouterAssistant),
            const SizedBox(height: 8),
            AppText.body(
              loc(context).aiAssistantWelcome,
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == ChatRole.user;

    if (message.isToolResult) {
      return const SizedBox.shrink();
    }

    String? textContent;
    bool isA2UI = false;

    if (message.isUser) {
      textContent = message.content as String?;
    } else if (message.isAssistant && message.response != null) {
      final textBlocks = message.response!.content.whereType<TextBlock>();
      if (textBlocks.isNotEmpty) {
        textContent = textBlocks.map((b) => b.text).join('\n');
        isA2UI = A2UIResponseRenderer.containsA2UI(textContent);
      }
    } else {
      aiLog('MessageBubble: unknown message type, role=${message.role}');
    }

    if (textContent == null || textContent.isEmpty) {
      return const SizedBox.shrink();
    }

    // Shape and length are diagnostic; the text itself is the conversation.
    aiLogSensitive(
      () => 'MessageBubble: rendering, isUser=$isUser, isA2UI=$isA2UI, '
          'content=$textContent',
      orElse: () => 'MessageBubble: rendering, isUser=$isUser, '
          'isA2UI=$isA2UI, length=${textContent!.length}',
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isUser) const Spacer(flex: 1),
          Flexible(
            flex: 3,
            child: isA2UI
                ? Builder(
                    builder: (context) {
                      return A2UIResponseRenderer(
                        content: textContent!,
                        registry: _registry,
                        onAction: _handleA2UIAction,
                      );
                    },
                  )
                : AppSurface(
                    variant: isUser
                        ? SurfaceVariant.highlight
                        : SurfaceVariant.elevated,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AppText.body(textContent),
                    ),
                  ),
          ),
          if (!isUser) const Spacer(flex: 1),
        ],
      ),
    );
  }

  void _handleA2UIAction(Map<String, dynamic> data) {
    // The payload can carry device details from the rendered component.
    aiLogSensitive(
      () => 'A2UI Action: $data',
      orElse: () => 'A2UI Action: ${data['action'] ?? 'unknown'}',
    );

    final toolUseId = data['toolUseId'] as String?;
    if (toolUseId == null) return;

    final actionType = data['action'] as String? ?? 'unknown';
    final actionData = Map<String, dynamic>.from(data)
      ..remove('action')
      ..remove('toolUseId');

    final action = ToolActionOutput(
      toolUseId: toolUseId,
      componentName: data['component'] as String? ?? 'unknown',
      actionType: actionType,
      data: actionData,
    );

    _controller?.handleToolAction(action);
  }

  Widget _buildErrorBanner() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      color: theme.colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText.bodyMedium(
              _controller?.errorMessage ?? loc(context).anErrorOccurred,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          if (_controller?.isRetryable == true)
            AppButton.text(
              label: loc(context).retry,
              onTap: _controller?.retry,
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _inputController,
                hintText: loc(context).typeAMessage,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            AppIconButton(
              icon: const Icon(Icons.send),
              onTap: _controller?.isLoading == true ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated thinking text with cycling phrases and dots.
class _AnimatedThinkingText extends StatefulWidget {
  final Color color;

  const _AnimatedThinkingText({required this.color});

  static const _phrases = [
    'Thinking',
    'Analyzing',
    'Processing',
    'Checking',
    'Looking into this',
    'Working on it',
  ];

  @override
  State<_AnimatedThinkingText> createState() => _AnimatedThinkingTextState();
}

class _AnimatedThinkingTextState extends State<_AnimatedThinkingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _dotCount = 0;
  int _phraseIndex = 0;
  int _cycleCount = 0;

  @override
  void initState() {
    super.initState();
    _phraseIndex =
        DateTime.now().millisecond % _AnimatedThinkingText._phrases.length;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _dotCount = (_dotCount + 1) % 4;
            if (_dotCount == 0) {
              _cycleCount++;
              if (_cycleCount >= 2) {
                _cycleCount = 0;
                _phraseIndex =
                    (_phraseIndex + 1) % _AnimatedThinkingText._phrases.length;
              }
            }
          });
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = _AnimatedThinkingText._phrases[_phraseIndex];
    final dots = '.' * _dotCount;
    return AppText.body(
      '$phrase$dots',
      color: widget.color,
    );
  }
}

/// Why the configuration screen is showing an error.
///
/// Two kinds, not one string: form validation and a real failure localize
/// through different paths (Art. XIII §1.4 keeps field validation separate from
/// `ServiceError`). Being sealed makes the `switch` in `_localizeConfigError`
/// exhaustive, so a new kind cannot be added without deciding how it reads.
sealed class _ConfigError {
  const _ConfigError();

  /// The user pressed Connect with a field left empty.
  const factory _ConfigError.missingFields() = _MissingFields;

  /// The attempt failed for a reason the error type describes.
  const factory _ConfigError.failure(ServiceError error) = _Failure;
}

final class _MissingFields extends _ConfigError {
  const _MissingFields();
}

final class _Failure extends _ConfigError {
  const _Failure(this.error);

  final ServiceError error;
}
