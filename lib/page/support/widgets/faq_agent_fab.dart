import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/constants/url_links.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Floating FAQ Agent component
///
/// Floating button in the bottom right corner, click to expand the search dialog.
/// Search for FAQ articles using the Linksys Support API and analyze the results via AWS Bedrock LLM.
class FAQAgentFab extends StatefulWidget {
  const FAQAgentFab({super.key});

  @override
  State<FAQAgentFab> createState() => _FAQAgentFabState();
}

class _FAQAgentFabState extends State<FAQAgentFab>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  final _containerKey = GlobalKey<GenUiContainerState>();
  final _inputController = TextEditingController();

  late final AnimationController _animController;
  late final OrchestrateUIFlowUseCase _orchestrator;
  late final IComponentRegistry _registry;
  bool _useMock = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _setupGenUI();
  }

  void _setupGenUI() {
    _registry = _createRegistry();

    // Try to create AWS Bedrock generator, fall back to direct search
    IContentGenerator generator;
    try {
      final config = AWSConfig.fromEnvironment();
      debugPrint('FAQ Agent: Using AWS Bedrock - $config');
      generator = BedrockFAQGenerator(config: config);
      _useMock = false;
    } on ConfigurationException catch (e) {
      debugPrint('FAQ Agent: AWS config failed: ${e.message}');
      debugPrint('FAQ Agent: Falling back to direct Linksys search');
      generator = DirectSearchGenerator();
      _useMock = true;
    } catch (e) {
      debugPrint('FAQ Agent: Unexpected error: $e');
      generator = DirectSearchGenerator();
      _useMock = true;
    }

    _orchestrator = OrchestrateUIFlowUseCase(contentGenerator: generator);
  }

  ComponentRegistry _createRegistry() {
    final registry = ComponentRegistry();

    // FAQ search result item
    registry.register('FAQResult', (context, props, {onAction, children}) {
      return AppListTile(
        leading: Icon(
          props['type'] == 'article'
              ? Icons.article_outlined
              : Icons.forum_outlined,
          size: 20,
        ),
        title: AppText.bodyMedium(props['title'] ?? ''),
        trailing: const Icon(Icons.open_in_new, size: 16),
        onTap: () {
          final id = props['id'];
          // type is not used in the new URL structure
          final url = 'https://support.linksys.com/kb/article/$id';
          gotoOfficialWebUrl(url);
        },
      );
    });

    // No results prompt
    registry.register('NoResults', (context, props, {onAction, children}) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            AppGap.md(),
            AppText.bodyMedium(
              props['message'] ?? 'No results found',
              textAlign: TextAlign.center,
            ),
            AppGap.md(),
            AppButton.text(
              label: 'Visit Linksys Support',
              onTap: () => gotoOfficialWebUrl('https://support.linksys.com'),
            ),
          ],
        ),
      );
    });

    return registry;
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  void _ask() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _containerKey.currentState?.sendMessage(text);
    _inputController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: _isExpanded ? 394 : 56,
      height: _isExpanded ? 580 : 56,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // Expanded dialog
          if (_isExpanded)
            Positioned(
              bottom: 64,
              right: 0,
              child: _buildChatPanel(colorScheme),
            ),

          // Floating button
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              heroTag: 'faq-agent-fab',
              onPressed: _toggle,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  _isExpanded ? Icons.close : Icons.support_agent,
                  key: ValueKey(_isExpanded),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPanel(ColorScheme colorScheme) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 380,
        height: 500,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Title bar
            _buildHeader(colorScheme),

            // Content area
            Expanded(
              child: GenUiContainer(
                key: _containerKey,
                orchestrator: _orchestrator,
                registry: _registry,
              ),
            ),

            // Input area
            _buildInputBar(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Icon(Icons.support_agent, color: colorScheme.onPrimaryContainer),
          AppGap.sm(),
          AppText.titleMedium(
            'FAQ Assistant',
            color: colorScheme.onPrimaryContainer,
          ),
          const Spacer(),
          // Mode indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _useMock
                  ? Colors.orange.withValues(alpha: 0.3)
                  : Colors.green.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _useMock ? 'Search' : 'AI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _useMock ? Colors.orange : Colors.green,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close,
                size: 20, color: colorScheme.onPrimaryContainer),
            onPressed: _toggle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _inputController,
              hintText: 'Search for help topics...',
              onSubmitted: (_) => _ask(),
            ),
          ),
          AppGap.sm(),
          AppIconButton(
            icon: const Icon(Icons.search),
            onTap: _ask,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _inputController.dispose();
    super.dispose();
  }
}

// =============================================================================
// Content Generators
// =============================================================================

/// AWS Bedrock-based FAQ generator with LLM analysis
class BedrockFAQGenerator implements IContentGenerator {
  final AWSConfig config;
  late final AwsContentGenerator _awsGenerator;

  static const _systemPrompt = '''
You are a helpful FAQ assistant for Linksys networking products. Your role is to analyze user questions and provide helpful answers with relevant support articles.

**Response Format Requirements:**

1. **First, provide your conclusion/analysis** - Give a clear, helpful text response that directly addresses the user's question. Explain the likely cause of the issue and possible solutions.

2. **Then, list source articles** - Use the FAQResult tool to display clickable links to relevant support articles that back up your answer.

3. **If no articles were found in the search results**, you MUST still suggest 3 possible article topics that would likely help. Create reasonable FAQResult entries based on common Linksys support topics related to the question. Use estimated IDs (like 1000, 1001, 1002) and descriptive titles.

**Available UI Components:**

1. FAQResult - Display a clickable article link
   Properties: { "id": number, "title": string, "type": "article" | "forum" }

2. NoResults - ONLY use when you cannot suggest ANY articles at all (avoid using this)
   Properties: { "message": string }

**Important:**
- Always start with your conclusion text BEFORE using any tools
- Limit to 5 most relevant articles maximum
- Always respond in the user's language
- Prefer creating helpful FAQResult suggestions over using NoResults
''';

  BedrockFAQGenerator({required this.config}) {
    _awsGenerator = AwsContentGenerator(config: config);
  }

  /// Tool definitions for Claude to use FAQResult format
  List<GenTool> get _tools => [
        GenTool(
          name: 'FAQResult',
          description: 'Display a clickable FAQ article link to the user',
          inputSchema: {
            'type': 'object',
            'properties': {
              'id': {
                'type': 'integer',
                'description': 'Article ID from Linksys Support',
              },
              'title': {
                'type': 'string',
                'description': 'Article title',
              },
              'type': {
                'type': 'string',
                'enum': ['article', 'forum'],
                'description': 'Content type',
              },
            },
            'required': ['id', 'title', 'type'],
          },
        ),
        GenTool(
          name: 'NoResults',
          description: 'Display when no relevant articles were found',
          inputSchema: {
            'type': 'object',
            'properties': {
              'message': {
                'type': 'string',
                'description': 'Message to display to the user',
              },
            },
            'required': ['message'],
          },
        ),
      ];

  @override
  Future<LLMResponse> generate(String prompt) async {
    try {
      // Step 1: Search Linksys API for related articles
      final searchResults = await _fetchSearchResults(prompt);

      // Step 2: Build the user message with search context
      final userContent = '''
User question: $prompt

Search results from Linksys Support:
${searchResults.isEmpty ? 'No articles found.' : searchResults.take(10).map((r) => '- [ID: ${r['id']}] ${r['title']} (Type: ${r['type'] ?? 'article'})').join('\n')}

Please analyze these results and recommend the most relevant articles using the FAQResult tool. Explain briefly why these articles might help before listing them.
''';

      // Step 3: Use generateWithHistory with tools for proper tool_use format
      // Note: forceToolUse is false to allow Claude to include text analysis first
      final response = await _awsGenerator.generateWithHistory(
        [ChatMessage.user(userContent)],
        tools: _tools,
        systemPrompt: _systemPrompt,
        forceToolUse: false, // Allow text analysis + tool_use together
      );

      return response;
    } catch (e) {
      debugPrint('BedrockFAQGenerator error: $e');
      // Fallback to direct search
      return DirectSearchGenerator()._formatDirectResponse(
        prompt,
        await _fetchSearchResults(prompt),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSearchResults(String keyword) async {
    if (keyword.isEmpty) return [];

    final encodedKeyword = Uri.encodeComponent(keyword);
    final apiUrl =
        'https://support.linksys.com/get_related_kb_forums/?text=$encodedKeyword';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return (data as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Linksys API error: $e');
    }
    return [];
  }
}

/// Direct search generator without LLM (fallback)
class DirectSearchGenerator implements IContentGenerator {
  @override
  Future<LLMResponse> generate(String prompt) async {
    final results = await _fetchSearchResults(prompt);
    return _formatDirectResponse(prompt, results);
  }

  Future<List<Map<String, dynamic>>> _fetchSearchResults(String keyword) async {
    if (keyword.isEmpty) return [];

    final encodedKeyword = Uri.encodeComponent(keyword);
    final apiUrl =
        'https://support.linksys.com/get_related_kb_forums/?text=$encodedKeyword';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return (data as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Linksys API error: $e');
    }
    return [];
  }

  LLMResponse _formatDirectResponse(
    String query,
    List<Map<String, dynamic>> results,
  ) {
    if (results.isEmpty) {
      return LLMResponse(
        id: 'faq-${DateTime.now().millisecondsSinceEpoch}',
        model: 'linksys-search',
        content: [
          ToolUseBlock(
            id: 'no-result',
            name: 'NoResults',
            input: {'message': 'No results found for "$query"'},
          ),
        ],
      );
    }

    return LLMResponse(
      id: 'faq-${DateTime.now().millisecondsSinceEpoch}',
      model: 'linksys-search',
      content: [
        TextBlock(text: 'Found ${results.length} related articles:'),
        ...results.take(10).map((result) => ToolUseBlock(
              id: 'result-${result['id']}',
              name: 'FAQResult',
              input: {
                'id': result['id'],
                'title': result['title'],
                'type': result['type'] ?? 'article',
              },
            )),
      ],
    );
  }
}
