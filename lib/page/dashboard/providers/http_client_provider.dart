import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Injectable HTTP client for package widget CGI requests.
///
/// Overridable in tests via `httpClientProvider.overrideWithValue(mockClient)`.
final httpClientProvider = Provider<http.Client>((ref) => http.Client());
