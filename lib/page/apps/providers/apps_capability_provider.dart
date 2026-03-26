import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/core/utils/logger.dart';

/// Whether the router supports the modular apps feature.
///
/// Performs a one-shot GET to `/api/apps.json` on first watch.
/// Returns `true` if the endpoint responds 200, `false` otherwise (404, timeout, etc.).
///
/// NOT autoDispose — result is cached for the session lifetime.
/// A page reload re-evaluates.
final appsCapabilityProvider = FutureProvider<bool>((ref) async {
  try {
    final baseUrl = Uri.base.origin;
    final response = await http
        .get(Uri.parse('$baseUrl/api/apps.json'))
        .timeout(const Duration(seconds: 5));
    final supported = response.statusCode == 200;
    logger.d('[Apps] capability check: HTTP ${response.statusCode} → $supported');
    return supported;
  } catch (e) {
    logger.d('[Apps] capability check failed: $e');
    return false;
  }
});
