/// USP Environment Configuration
///
/// This module handles loading and accessing environment configuration
/// for USP (User Services Platform) router connections.
///
/// For web deployments, uses relative URLs (empty baseUrl) to avoid CORS issues.
/// For native platforms, uses configured host/port settings.
library;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment configuration for USP router connections.
///
/// Provides access to router connection settings.
/// On web, uses relative URLs for same-origin requests.
class UspEnvironment {
  UspEnvironment._();

  // Default configuration values
  static const String _defaultRouterHost = '192.168.1.1';
  static const int _defaultRouterPort = 443;
  static const bool _defaultUseTls = true;
  static const String _defaultAuthEndpoint = '/api/auth/login';
  static const String _defaultApiEndpoint = '/api/usp';
  static const String _defaultSseEndpoint = '/api/events';

  /// Initialize the environment configuration.
  ///
  /// Currently a no-op but kept for API compatibility.
  static Future<void> initialize() async {
    // No-op - configuration uses defaults
  }

  /// Router hostname or IP address.
  ///
  /// Defaults to '192.168.1.1'.
  static String get routerHost => _defaultRouterHost;

  /// Router API port.
  ///
  /// Defaults to 443.
  static int get routerPort => _defaultRouterPort;

  /// Whether to use TLS/HTTPS for connections.
  ///
  /// Defaults to true.
  static bool get useTls => _defaultUseTls;

  /// Authentication endpoint path.
  ///
  /// Defaults to '/api/auth/login'.
  static String get authEndpoint => _defaultAuthEndpoint;

  /// USP API endpoint path.
  ///
  /// Defaults to '/api/usp'.
  static String get apiEndpoint => _defaultApiEndpoint;

  /// Server-Sent Events endpoint for real-time notifications.
  ///
  /// Defaults to '/api/events'.
  static String get sseEndpoint => _defaultSseEndpoint;

  /// Base URL for the router API.
  ///
  /// On web, returns empty string to use relative URLs (same origin).
  /// This is required because the web app is served from the router itself,
  /// so API calls should use relative URLs to avoid CORS issues.
  ///
  /// On native platforms, constructed from host, port, and TLS settings.
  static String get baseUrl {
    // On web, use relative URLs (empty base) so requests go to same origin.
    // This avoids CORS issues when the web app is served from the router.
    if (kIsWeb) {
      return '';
    }
    final protocol = useTls ? 'https' : 'http';
    return '$protocol://$routerHost:$routerPort';
  }

  /// Full URL for the authentication endpoint.
  static String get authUrl => '$baseUrl$authEndpoint';

  /// Full URL for the USP API endpoint.
  static String get apiUrl => '$baseUrl$apiEndpoint';

  /// Full URL for the SSE endpoint.
  static String get sseUrl => '$baseUrl$sseEndpoint';
}
