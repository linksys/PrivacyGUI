import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/ai/_ai.dart';
import 'package:privacy_gui/page/ai_assistant/providers/router_command_provider.dart';
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
  String? _configError;
  final _accessKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  BedrockModel _selectedModel = BedrockModel.models.first;
  bool _isConfiguring = false;

  @override
  void initState() {
    super.initState();
    _registry = RouterComponentRegistry.create();
    _tryInitController();
  }

  void _tryInitController() {
    final commandProvider = ref.read(routerCommandProviderProvider);

    try {
      final awsConfig = AWSConfig.fromEnvironment();
      _controller = RouterChatController(
        generator: AwsContentGenerator(config: awsConfig),
        commandProvider: commandProvider,
        routerContext: buildRouterContext(ref),
      );
      _controller!.addListener(_onControllerChanged);
      _needsConfig = false;
      _configError = null;
    } on ConfigurationException catch (e) {
      debugPrint('RouterAssistantView: Config error: $e');
      _needsConfig = true;
      _configError = e.message;
    } catch (e) {
      debugPrint('RouterAssistantView: Unexpected error: $e');
      _needsConfig = true;
      _configError = e.toString();
    }
  }

  void _initControllerWithManualConfig() {
    if (_accessKeyController.text.isEmpty ||
        _secretKeyController.text.isEmpty) {
      setState(() {
        _configError = 'Please fill in all required fields';
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
        accessKeyId: _accessKeyController.text.trim(),
        secretAccessKey: _secretKeyController.text.trim(),
        region: 'us-west-2',
        modelId: _selectedModel.id,
      );

      _controller = RouterChatController(
        generator: AwsContentGenerator(config: awsConfig),
        commandProvider: commandProvider,
        routerContext: buildRouterContext(ref),
      );
      _controller!.addListener(_onControllerChanged);

      setState(() {
        _needsConfig = false;
        _isConfiguring = false;
      });
    } catch (e) {
      setState(() {
        _configError = 'Failed to initialize: $e';
        _isConfiguring = false;
      });
    }
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
      builder: (context) => AlertDialog(
        title: const Text('Confirmation Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to execute this operation?'),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller?.cancelPendingAction();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _controller?.confirmPendingAction();
            },
            child: const Text('Confirm'),
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
            const Text('AI Router Assistant'),
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
                  'AWS Bedrock Configuration',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                AppText.body(
                  'Enter your AWS credentials to connect to Claude.',
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
                              _configError!,
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
                    AppText.labelMedium('AWS Access Key ID'),
                    const SizedBox(height: 4),
                    AppTextField(
                      controller: _accessKeyController,
                      hintText: 'AKIA...',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelMedium('AWS Secret Access Key'),
                    const SizedBox(height: 4),
                    AppPasswordInput(
                      controller: _secretKeyController,
                      hintText: 'Enter secret key',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildModelDropdown(),
                const SizedBox(height: 8),
                AppText.caption(
                  'Region: us-west-2 (fixed)',
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: _isConfiguring ? 'Connecting...' : 'Connect',
                  onTap:
                      _isConfiguring ? null : _initControllerWithManualConfig,
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
        AppText.labelMedium('Model'),
        const SizedBox(height: 4),
        AppDropdown<BedrockModel>(
          value: _selectedModel,
          items: BedrockModel.models,
          itemAsString: (m) => m.displayName,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedModel = value);
            }
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
            const Text('AI Router Assistant'),
            const SizedBox(width: 8),
            _buildStatusBadge(),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showConfigDialog,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _controller?.clearConversation,
            tooltip: 'Clear conversation',
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
      builder: (context) => AlertDialog(
        title: const Text('Change Configuration'),
        content: const Text(
          'Do you want to change AWS credentials?\nThis will clear the current conversation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _controller?.removeListener(_onControllerChanged);
                _controller = null;
                _needsConfig = true;
                _configError = null;
              });
            },
            child: const Text('Change'),
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
      child: const Text(
        'Live',
        style: TextStyle(
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
            AppText.headline('AI Router Assistant'),
            const SizedBox(height: 8),
            AppText.body(
              'I can help you check network status, manage connected devices, or adjust WiFi settings.\nTry asking "Show all connected devices" or "What is my network status?"',
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
      debugPrint('[AI] MessageBubble: skipping tool_result');
      return const SizedBox.shrink();
    }

    String? textContent;
    bool isA2UI = false;

    if (message.isUser) {
      textContent = message.content as String?;
      debugPrint('[AI] MessageBubble: user message, content=$textContent');
    } else if (message.isAssistant && message.response != null) {
      final textBlocks = message.response!.content.whereType<TextBlock>();
      debugPrint(
          '[AI] MessageBubble: assistant message, textBlocks=${textBlocks.length}');
      if (textBlocks.isNotEmpty) {
        textContent = textBlocks.map((b) => b.text).join('\n');
        isA2UI = A2UIResponseRenderer.containsA2UI(textContent);
        debugPrint(
            '[AI] MessageBubble: textContent length=${textContent.length}, isA2UI=$isA2UI');
        debugPrint(
            '[AI] MessageBubble: textContent preview=${textContent.substring(0, textContent.length.clamp(0, 200))}');
      }
    } else {
      debugPrint(
          '[AI] MessageBubble: unknown message type, role=${message.role}, isAssistant=${message.isAssistant}, response=${message.response}');
    }

    if (textContent == null || textContent.isEmpty) {
      debugPrint('[AI] MessageBubble: no textContent, returning empty');
      return const SizedBox.shrink();
    }

    debugPrint('[AI] MessageBubble: rendering, isUser=$isUser, isA2UI=$isA2UI');

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
                      debugPrint('[AI] Rendering A2UIResponseRenderer');
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
    debugPrint('A2UI Action: $data');

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
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _controller?.errorMessage ?? 'An error occurred',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (_controller?.isRetryable == true)
            TextButton(
              onPressed: _controller?.retry,
              child: const Text('Retry'),
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
                hintText: 'Type a message...',
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
