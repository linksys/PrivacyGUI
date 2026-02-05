import 'package:generative_ui/generative_ui.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/constants.dart';
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/services/linksys_search_service.dart';

/// Direct search generator without LLM (fallback)
class DirectSearchGenerator implements IContentGenerator {
  final LinksysSearchService _searchService;

  DirectSearchGenerator({LinksysSearchService? searchService})
      : _searchService = searchService ?? LinksysSearchService();

  @override
  Future<LLMResponse> generate(String prompt) async {
    final searchResult = await _searchService.fetchResults(prompt);

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

    return _formatDirectResponse(prompt, searchResult.results);
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
        ...results.take(kMaxSearchResults).map((result) => ToolUseBlock(
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
