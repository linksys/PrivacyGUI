import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/apps/providers/apps_capability_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';

import '../models/package_widget_template.dart';

/// Loads and caches package widget templates from the router.
///
/// Sequence:
/// 1. Check [appsCapabilityProvider] — skip entirely if router has no apps.json
/// 2. GET /api/apps.json → extract entries with `widget` field
/// 3. For each widget entry, GET its templateUrl
/// 4. Parse JSON into [PackageWidgetTemplate]
/// 5. 30-second poll detects package install/remove via key set difference
///    (lightweight: only re-fetches apps.json, not all template URLs)
///
/// NOT autoDispose — persists across tab switches.
final packageWidgetLoaderProvider = AsyncNotifierProvider<PackageWidgetLoader,
    Map<String, PackageWidgetTemplate>>(
  PackageWidgetLoader.new,
);

class PackageWidgetLoader
    extends AsyncNotifier<Map<String, PackageWidgetTemplate>> {
  Timer? _pollTimer;

  @override
  Future<Map<String, PackageWidgetTemplate>> build() async {
    ref.onDispose(() => _pollTimer?.cancel());

    // Gate: skip entirely if router does not support modular apps.
    // appsCapabilityProvider is a one-shot FutureProvider cached for
    // the session — this await is essentially free on subsequent reads.
    final supported = await ref.watch(appsCapabilityProvider.future);
    if (!supported) {
      logger.d('[USP][PkgWidgets] Router does not support apps — skipping');
      return const {};
    }

    final templates = await _loadAllTemplates();

    // Start polling for package changes (install/remove)
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pollForChanges();
    });

    return templates;
  }

  /// Whether the last apps.json fetch succeeded.
  bool _lastFetchSuccess = false;

  /// Fetch apps.json and load ALL template URLs. Used on initial load
  /// and manual refresh — not on poll (which is lightweight).
  Future<Map<String, PackageWidgetTemplate>> _loadAllTemplates() async {
    final baseUrl = Uri.base.origin;
    final templates = <String, PackageWidgetTemplate>{};

    try {
      final entries = await _fetchWidgetEntries();
      if (entries == null) return {}; // fetch failed

      for (final MapEntry(key: _, value: templateUrl) in entries.entries) {
        final template = await _fetchTemplate(baseUrl, templateUrl);
        if (template != null) {
          templates[template.widgetId] = template;
        }
      }
    } catch (e) {
      logger.w('[USP][PkgWidgets] Failed to load templates: $e');
      _lastFetchSuccess = false;
      return {};
    }

    logger.d('[USP][PkgWidgets] Loaded ${templates.length} templates');
    return templates;
  }

  /// Fetch apps.json and extract widget entries as widgetId → templateUrl.
  /// Returns null on failure.
  Future<Map<String, String>?> _fetchWidgetEntries() async {
    final baseUrl = Uri.base.origin;

    try {
      final response = await http.get(Uri.parse('$baseUrl/api/apps.json'));
      if (response.statusCode != 200) {
        logger.w('[USP][PkgWidgets] apps.json HTTP ${response.statusCode}');
        _lastFetchSuccess = false;
        return null;
      }

      final appsJson = jsonDecode(response.body) as Map<String, dynamic>;
      final allApps = <Map<String, dynamic>>[
        ..._safeList(appsJson['apps']),
        ..._safeList(appsJson['userApps']),
      ];

      final entries = <String, String>{};
      for (final app in allApps) {
        final widget = app['widget'] as Map<String, dynamic>?;
        if (widget == null) continue;
        final templateUrl = widget['templateUrl'] as String?;
        final widgetId = widget['id'] as String?;
        if (templateUrl == null || widgetId == null) continue;
        entries[widgetId] = templateUrl;
      }

      _lastFetchSuccess = true;
      return entries;
    } catch (e) {
      logger.w('[USP][PkgWidgets] Failed to fetch apps.json: $e');
      _lastFetchSuccess = false;
      return null;
    }
  }

  /// Fetch and parse a single template URL.
  Future<PackageWidgetTemplate?> _fetchTemplate(
      String baseUrl, String templateUrl) async {
    try {
      final fullUrl =
          templateUrl.startsWith('http') ? templateUrl : '$baseUrl$templateUrl';
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode != 200) {
        logger.w('[USP][PkgWidgets] Template HTTP '
            '${response.statusCode} for $templateUrl');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final template = PackageWidgetTemplate.fromJson(json);
      logger.d('[USP][PkgWidgets] Loaded: ${template.widgetId} '
          '(${template.displayName})');
      return template;
    } catch (e) {
      logger.w('[USP][PkgWidgets] Failed to load template $templateUrl: $e');
      return null;
    }
  }

  /// Re-fetch all templates (called on manual refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadAllTemplates());
  }

  /// Lightweight poll: only re-fetches apps.json to detect install/remove.
  /// Only fetches individual template URLs for NEWLY added widgets.
  ///
  /// Only processes removals when the HTTP fetch was successful. A transient
  /// network failure (non-200, timeout, etc.) must NOT be interpreted as
  /// "all packages were uninstalled" — that would wipe dashboard cards.
  Future<void> _pollForChanges() async {
    try {
      final currentIds = state.valueOrNull?.keys.toSet() ?? {};
      final freshEntries = await _fetchWidgetEntries();

      // Skip diff when fetch failed — cannot tell removed from unavailable.
      if (freshEntries == null || !_lastFetchSuccess) {
        logger.d('[USP][PkgWidgets] Poll skipped (fetch failed)');
        return;
      }

      final freshIds = freshEntries.keys.toSet();
      if (freshIds == currentIds) return; // No change

      final added = freshIds.difference(currentIds);
      final removed = currentIds.difference(freshIds);

      final current =
          Map<String, PackageWidgetTemplate>.of(state.valueOrNull ?? {});

      // Fetch templates only for newly added widgets
      if (added.isNotEmpty) {
        logger.d('[USP][PkgWidgets] New widgets detected: $added');
        final baseUrl = Uri.base.origin;
        for (final id in added) {
          final templateUrl = freshEntries[id];
          if (templateUrl == null) continue;
          final template = await _fetchTemplate(baseUrl, templateUrl);
          if (template != null) {
            current[template.widgetId] = template;
          }
        }
      }

      // Clean up removed widgets from dashboard
      if (removed.isNotEmpty) {
        logger.d('[USP][PkgWidgets] Removed widgets: $removed');
        for (final id in removed) {
          current.remove(id);
          ref
              .read(uspSliverDashboardControllerProvider.notifier)
              .removeWidget(id);
          ref.read(packageWidgetDataProvider(id).notifier).clear();
        }
      }

      state = AsyncData(current);
    } catch (e) {
      logger.w('[USP][PkgWidgets] Poll error: $e');
    }
  }

  /// Safely extract a List<Map> from a JSON value that could be
  /// List, Map (empty), or null.
  static List<Map<String, dynamic>> _safeList(dynamic value) {
    if (value is List) return value.cast<Map<String, dynamic>>();
    return [];
  }
}
