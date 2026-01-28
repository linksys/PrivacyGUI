import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/ai/_ai.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

/// Provider for the command provider.
final routerCommandProviderProvider = Provider<IRouterCommandProvider>((ref) {
  final router = ref.watch(routerRepositoryProvider);
  return JnapCommandProvider(router);
});

/// Main view for the Router AI Assistant.
///
/// This provides a chat interface for users to interact with their router
/// using natural language.
class RouterAssistantView extends ConsumerStatefulWidget {
  const RouterAssistantView({super.key});

  @override
  ConsumerState<RouterAssistantView> createState() =>
      _RouterAssistantViewState();
}

class _RouterAssistantViewState extends ConsumerState<RouterAssistantView> {
  late final IComponentRegistry _registry;
  late final IConversationGenerator _generator;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isMock = false;

  @override
  void initState() {
    super.initState();
    _registry = RouterComponentRegistry.create();
    _initGenerator();
  }

  void _initGenerator() {
    final commandProvider = ref.read(routerCommandProviderProvider);

    // Try to create AWS generator, fallback to mock
    IConversationGenerator baseGenerator;
    try {
      final awsConfig = AWSConfig.fromEnvironment();
      baseGenerator = AwsContentGenerator(config: awsConfig);
      _isMock = false;
    } catch (e) {
      debugPrint('RouterAssistantView: Using mock generator: $e');
      baseGenerator = _MockConversationGenerator();
      _isMock = true;
    }

    _generator = RouterAgentOrchestrator(
      llmGenerator: baseGenerator,
      commandProvider: commandProvider,
      onConfirmationRequired: _handleConfirmationRequired,
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleConfirmationRequired(
      RouterCommand command, Map<String, dynamic> params) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation Required'),
        content:
            Text('Are you sure you want to execute "${command.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executeConfirmedCommand(command.name, params);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeConfirmedCommand(
      String commandName, Map<String, dynamic> params) async {
    final orchestrator = _generator as RouterAgentOrchestrator;
    try {
      final result =
          await orchestrator.executeConfirmedCommand(commandName, params);
      if (result.success) {
        _addMessage('✅ Operation completed', isUser: false);
      } else {
        _addMessage('❌ Operation failed: ${result.error}', isUser: false);
      }
    } catch (e) {
      _addMessage('❌ Execution error: $e', isUser: false);
    }
  }

  void _addMessage(String text, {required bool isUser, bool isA2UI = false}) {
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        isUser: isUser,
        isA2UI: isA2UI,
      ));
    });
    _scrollToBottom();
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
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();
    _addMessage(text, isUser: true);

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _generator.generateWithHistory(
        _messages
            .map((m) => m.isUser
                ? ChatMessage.user(m.text)
                : ChatMessage.assistant(
                    LLMResponse(
                      id: 'history',
                      model: 'history',
                      content: [TextBlock(text: m.text)],
                    ),
                  )) // Use assistant role for history
            .toList(),
      );

      // Process response content
      for (final block in response.content) {
        if (block is TextBlock) {
          // Check for A2UI content
          if (A2UIResponseRenderer.containsA2UI(block.text)) {
            _addMessage(block.text, isUser: false, isA2UI: true);
          } else {
            _addMessage(block.text, isUser: false);
          }
        }
      }
    } catch (e) {
      _addMessage('❌ Error occurred: $e', isUser: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('AI Router Assistant'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _isMock ? Colors.orange : Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isMock ? 'Mock' : 'Live',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              if (_generator is RouterAgentOrchestrator) {
                (_generator as RouterAgentOrchestrator).clearCache();
              }
            },
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildChatArea(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_messages.isEmpty) {
      return _buildWelcomeScreen();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: AppLoader(),
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
            Icon(
              Icons.router,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            AppText.headline('AI Router Assistant'),
            const SizedBox(height: 8),
            AppText.body(
              'I can help you check network status, manage connected devices, or adjust WiFi settings.\nTry asking "Show all connected devices" or "What is my WiFi password?"',
              textAlign: TextAlign.center,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Add spacer on the left for USER messages (to push them right)
          // For BOT messages, we want them on the left, so no left spacer (or maybe a small one if needed, but usually spacer is for the empty side)
          if (message.isUser) const Spacer(flex: 1),
          Flexible(
            flex: 3,
            child: message.isA2UI
                ? A2UIResponseRenderer(
                    content: message.text,
                    registry: _registry,
                    onAction: (data) {
                      debugPrint('A2UI Action: $data');
                      final action = data['action'] as String?;
                      if (action != null) {
                        _addMessage('Executing action: $action', isUser: true);
                      }
                    },
                  )
                : AppSurface(
                    variant: message.isUser
                        ? SurfaceVariant.highlight
                        : SurfaceVariant.elevated,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: AppText.body(message.text),
                    ),
                  ),
          ),
          // Add spacer on the right for BOT messages (to keep them left)
          if (!message.isUser) const Spacer(flex: 1),
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
              onTap: _isLoading ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple chat message model.
class _ChatMessage {
  final String text;
  final bool isUser;
  final bool isA2UI;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.isA2UI = false,
  });
}

/// Mock conversation generator for demo without AWS credentials.
class _MockConversationGenerator implements IConversationGenerator {
  @override
  Future<LLMResponse> generateWithHistory(
    List<ChatMessage> messages, {
    List<GenTool>? tools,
    String? systemPrompt,
    bool forceToolUse = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final lastMessage = messages.lastWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => ChatMessage.user(''),
    );

    final userText = (lastMessage.content as String).toLowerCase();

    // Simple keyword matching for demo
    if (userText.contains('設備') || userText.contains('device')) {
      return _createDeviceListResponse();
    } else if (userText.contains('wifi') || userText.contains('密碼')) {
      return _createWifiResponse();
    } else if (userText.contains('網路') || userText.contains('狀態')) {
      return _createStatusResponse();
    }

    return LLMResponse(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      model: 'mock',
      content: [
        TextBlock(
            text:
                'Hello! I am your AI Router Assistant. You can ask me about connected devices, WiFi settings, or network status.'),
      ],
    );
  }

  LLMResponse _createDeviceListResponse() {
    const a2ui = '''
{"surfaceUpdate":{"surfaceId":"main","components":[
  {"id":"root","type":"Column","childIds":["header","list"]},
  {"id":"header","type":"AppText","properties":{"text":"Connected Devices","variant":"headline"}},
  {"id":"list","type":"DeviceListView","properties":{"devices":{"boundPath":"/data/devices"}}}
]}}
{"dataModelUpdate":{"surfaceId":"main","contents":[
  {"path":"/data/devices","value":[
    {"name":"iPhone 15 Pro","ip":"192.168.1.101","connectionType":"5GHz"},
    {"name":"MacBook Pro","ip":"192.168.1.102","connectionType":"5GHz"},
    {"name":"Smart TV","ip":"192.168.1.103","connectionType":"2.4GHz"}
  ]}
]}}
{"beginRendering":{"surfaceId":"main","root":"root"}}
''';

    return LLMResponse(
      id: 'mock-devices',
      model: 'mock',
      content: [TextBlock(text: a2ui)],
    );
  }

  LLMResponse _createWifiResponse() {
    const a2ui = '''
{"surfaceUpdate":{"surfaceId":"main","components":[
  {"id":"root","type":"WifiSettingsCard","properties":{
    "ssid":"MyNetwork",
    "password":"12345678",
    "securityMode":"WPA2-Personal",
    "band":"2.4GHz + 5GHz"
  }}
]}}
{"beginRendering":{"surfaceId":"main","root":"root"}}
''';

    return LLMResponse(
      id: 'mock-wifi',
      model: 'mock',
      content: [TextBlock(text: a2ui)],
    );
  }

  LLMResponse _createStatusResponse() {
    const a2ui = '''
{"surfaceUpdate":{"surfaceId":"main","components":[
  {"id":"root","type":"NetworkStatusCard","properties":{
    "wanStatus":"Connected",
    "connectedDevices":8,
    "uploadSpeed":"50 Mbps",
    "downloadSpeed":"100 Mbps"
  }}
]}}
{"beginRendering":{"surfaceId":"main","root":"root"}}
''';

    return LLMResponse(
      id: 'mock-status',
      model: 'mock',
      content: [TextBlock(text: a2ui)],
    );
  }
}
