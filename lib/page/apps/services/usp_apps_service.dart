import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/apps/models/app_event.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';

final uspAppsServiceProvider = Provider<UspAppsService>(
  (ref) => UspAppsService(),
);

/// Service layer for fetching router-installed apps via lighttpd static JSON.
///
/// These endpoints are NOT USP/TR-181 — they are plain files served by
/// lighttpd, written by app_util.lua on opkg install/remove.
class UspAppsService {
  final http.Client _client;
  final String _baseUrl;

  UspAppsService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? Uri.base.origin;

  /// Fetch all apps from /api/apps.json.
  Future<List<AppInfoUIModel>> fetchApps() async {
    final response = await _client.get(Uri.parse('$_baseUrl/api/apps.json'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load apps: HTTP ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseApps(json);
  }

  /// Fetch latest event from /api/app-events.json.
  /// Returns null if no events exist or the file is empty.
  Future<AppEvent?> fetchLatestEvent() async {
    try {
      final response =
          await _client.get(Uri.parse('$_baseUrl/api/app-events.json'));
      if (response.statusCode != 200 || response.body.trim().isEmpty) {
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json.isEmpty) return null;
      return AppEvent.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  List<AppInfoUIModel> _parseApps(Map<String, dynamic> json) {
    final systemApps = _safeList(json['apps'])
        .map((app) => _toModel(app, AppCategory.system))
        .toList();

    final userApps = _safeList(json['userApps'])
        .map((app) => _toModel(app, AppCategory.user))
        .toList();

    return [...systemApps, ...userApps];
  }

  /// Safely extract a List<Map> from a JSON value that could be:
  /// - List (normal)
  /// - Map/empty {} (server returns object instead of array when empty)
  /// - null
  static List<Map<String, dynamic>> _safeList(dynamic value) {
    if (value is List) return value.cast<Map<String, dynamic>>();
    return [];
  }

  AppInfoUIModel _toModel(Map<String, dynamic> json, AppCategory category) {
    final rawLink = json['link'] as String? ?? '';
    final normalized = _normalizeLink(rawLink);
    logger.d('[USP][Apps] _toModel: name=${json['name']}, '
        'rawLink="$rawLink", normalized="$normalized", baseUrl=$_baseUrl');
    return AppInfoUIModel(
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String? ?? '',
      link: normalized,
      version: json['version'] as String? ?? '',
      iconData: _mapIcon(json['icon'] as String? ?? ''),
      color: _mapColor(json['color'] as String? ?? ''),
      category: category,
    );
  }

  // --- Mappers ---

  static const _iconMap = <String, IconData>{
    'settings': Icons.settings,
    'wifi': Icons.wifi,
    'app-registration': Icons.app_registration,
    'dashboard': Icons.dashboard,
    'terminal': Icons.terminal,
    'code': Icons.code,
    'cloud': Icons.cloud,
    'storage': Icons.storage,
    'security': Icons.security,
    'vpn-key': Icons.vpn_key,
    'speed': Icons.speed,
    'analytics': Icons.analytics,
    'monitoring': Icons.monitor_heart,
    'folder': Icons.folder,
    'psychology': Icons.psychology,
    'apps': Icons.apps,
  };

  static const _colorMap = <String, Color>{
    'blueAccent': Colors.blueAccent,
    'cyanAccent': Colors.cyanAccent,
    'greenAccent': Colors.greenAccent,
    'orangeAccent': Colors.orangeAccent,
    'purpleAccent': Colors.purpleAccent,
    'redAccent': Colors.redAccent,
    'tealAccent': Colors.tealAccent,
    'amberAccent': Colors.amberAccent,
    'indigoAccent': Colors.indigoAccent,
  };

  static IconData _mapIcon(String name) => _iconMap[name] ?? Icons.apps;

  static Color _mapColor(String name) => _colorMap[name] ?? Colors.blueAccent;

  /// Resolve app link against the current origin.
  ///
  /// Links in apps.json may contain a hardcoded router IP (e.g.
  /// `"192.168.1.1/files/"` or `"http://192.168.1.1/admin"`), but the
  /// user may be accessing the router from a different address or via
  /// HTTPS.  Extract the path and re-base it on [Uri.base.origin].
  String _normalizeLink(String link) {
    if (link.isEmpty) return link;

    try {
      // Ensure we can parse as a URI — add scheme if missing.
      final withScheme =
          link.startsWith('http://') || link.startsWith('https://')
              ? link
              : 'http://$link';
      final uri = Uri.parse(withScheme);
      final path = uri.path.isEmpty ? '/' : uri.path;
      final result = '$_baseUrl$path';
      logger.d('[USP][Apps] _normalizeLink: '
          'raw="$link" → withScheme="$withScheme" → '
          'uri.host="${uri.host}", uri.path="${uri.path}" → result="$result"');
      return result;
    } catch (e) {
      logger.w('[USP][Apps] _normalizeLink parse error: $e, link="$link"');
      return '$_baseUrl/$link';
    }
  }
}
