import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:generative_ui/generative_ui.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/constants.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/generators/direct_search_generator.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/services/linksys_search_service.dart';

/// AWS Bedrock-based FAQ generator with LLM analysis
class BedrockFAQGenerator implements IContentGenerator {
  final AWSConfig config;
  final LinksysSearchService _searchService;
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

  BedrockFAQGenerator({
    required this.config,
    LinksysSearchService? searchService,
  }) : _searchService = searchService ?? LinksysSearchService() {
    _awsGenerator = AwsContentGenerator(config: config);
  }

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
        GenTool(
          name: 'NetworkError',
          description: 'Display when network connection failed',
          inputSchema: {
            'type': 'object',
            'properties': {
              'message': {
                'type': 'string',
                'description': 'Error message to display',
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
      final searchResult = await _searchService.fetchResults(prompt);

      // Handle errors
      if (searchResult.errorType == SearchErrorType.cors) {
        return _createErrorResponse(
          'cors-error',
          'NetworkError',
          'Unable to access Linksys Support. This feature works best on the published app.',
        );
      }

      if (searchResult.errorType == SearchErrorType.network) {
        return _createErrorResponse(
          'network-error',
          'NetworkError',
          'Unable to search. Please check your network connection.',
        );
      }

      // Step 2: Build the user message with search context
      final results = searchResult.results;
      final userContent = '''
User question: $prompt

Search results from Linksys Support:
${results.isEmpty ? 'No articles found.' : results.take(kMaxSearchResults).map((r) => '- [ID: ${r['id']}] ${r['title']} (Type: ${r['type'] ?? 'article'})').join('\n')}

Please analyze these results and recommend the most relevant articles using the FAQResult tool. Explain briefly why these articles might help before listing them.
''';

      // Step 3: Use generateWithHistory with tools for proper tool_use format
      final response = await _awsGenerator.generateWithHistory(
        [ChatMessage.user(userContent)],
        tools: _tools,
        systemPrompt: _systemPrompt,
        forceToolUse: false,
      );

      return response;
    } on SocketException {
      return _createErrorResponse(
        'network-error',
        'NetworkError',
        'Unable to connect. Please check your network.',
      );
    } catch (e) {
      debugPrint('BedrockFAQGenerator error: $e');
      // Fallback to direct search
      return DirectSearchGenerator().generate(prompt);
    }
  }

  LLMResponse _createErrorResponse(String id, String name, String message) {
    return LLMResponse(
      id: 'faq-${DateTime.now().millisecondsSinceEpoch}',
      model: 'error',
      content: [
        ToolUseBlock(
          id: id,
          name: name,
          input: {'message': message},
        ),
      ],
    );
  }
}
