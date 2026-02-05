import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/page/support/shared_widgets/faq_agent/constants.dart';

/// Search result error types
enum SearchErrorType {
  none,
  network,
  cors,
}

/// Result wrapper for search operations
class SearchResult {
  final List<Map<String, dynamic>> results;
  final SearchErrorType errorType;

  const SearchResult({
    required this.results,
    required this.errorType,
  });

  const SearchResult.success(this.results) : errorType = SearchErrorType.none;
  const SearchResult.error(this.errorType) : results = const [];

  bool get hasError => errorType != SearchErrorType.none;
  bool get isEmpty => results.isEmpty;
}

/// Service for searching Linksys support articles
class LinksysSearchService {
  final http.Client? _client;

  LinksysSearchService({http.Client? client}) : _client = client;

  http.Client get _httpClient => _client ?? http.Client();

  /// Fetch search results from Linksys Support API
  Future<SearchResult> fetchResults(String keyword) async {
    if (keyword.isEmpty) {
      return const SearchResult.success([]);
    }

    final encodedKeyword = Uri.encodeComponent(keyword);
    final apiUrl =
        '$kLinksysSearchApiBase$kLinksysSearchEndpoint?text=$encodedKeyword';

    try {
      final response = await _httpClient.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return SearchResult.success(
          (data as List).cast<Map<String, dynamic>>(),
        );
      }
      debugPrint('API returned status: ${response.statusCode}');
      return const SearchResult.success([]);
    } on SocketException catch (e) {
      debugPrint('Network error (SocketException): $e');
      return const SearchResult.error(SearchErrorType.network);
    } on http.ClientException catch (e) {
      // In Flutter Web, CORS errors appear as ClientException
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('cors') ||
          errorMsg.contains('xmlhttprequest') ||
          errorMsg.contains('failed to fetch')) {
        debugPrint('CORS error: $e');
        return const SearchResult.error(SearchErrorType.cors);
      }
      debugPrint('HTTP client error: $e');
      return const SearchResult.error(SearchErrorType.network);
    } catch (e) {
      debugPrint('Linksys API error: $e');
      return const SearchResult.error(SearchErrorType.network);
    }
  }
}
