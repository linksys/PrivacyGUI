import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';

import '../models/package_widget_template.dart';

/// Loads and caches package widget templates from the router.
///
/// Sequence:
/// 1. GET /api/apps.json → extract entries with `widget` field
/// 2. For each widget entry, GET its templateUrl
/// 3. Parse JSON into [PackageWidgetTemplate]
/// 4. 30-second poll detects package install/remove via key set difference
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

    final templates = await _loadTemplates();

    // Start polling for package changes (install/remove)
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollForChanges();
    });

    return templates;
  }

  /// Result of [_loadTemplates] — distinguishes "no widgets" from "fetch failed".
  ({Map<String, PackageWidgetTemplate> templates, bool success}) _lastLoad =
      (templates: const {}, success: false);

  Future<Map<String, PackageWidgetTemplate>> _loadTemplates() async {
    final baseUrl = Uri.base.origin;
    final templates = <String, PackageWidgetTemplate>{};

    try {
      final appsResponse = await http.get(Uri.parse('$baseUrl/api/apps.json'));
      if (appsResponse.statusCode != 200) {
        logger.w('[USP][PkgWidgets] apps.json HTTP ${appsResponse.statusCode}');
        _lastLoad = (templates: const {}, success: false);
        return {};
      }

      final appsJson = jsonDecode(appsResponse.body) as Map<String, dynamic>;

      // Collect widget entries from both system and user apps
      final allApps = <Map<String, dynamic>>[
        ..._safeList(appsJson['apps']),
        ..._safeList(appsJson['userApps']),
      ];

      final widgetEntries =
          allApps.where((app) => app['widget'] != null).toList();

      if (widgetEntries.isEmpty) {
        logger.d('[USP][PkgWidgets] No widget entries in apps.json');
        _lastLoad = (templates: const {}, success: true);
        return {};
      }

      for (final app in widgetEntries) {
        final widget = app['widget'] as Map<String, dynamic>;
        final templateUrl = widget['templateUrl'] as String?;
        if (templateUrl == null) continue;

        try {
          final fullUrl = templateUrl.startsWith('http')
              ? templateUrl
              : '$baseUrl$templateUrl';
          final templateResponse = await http.get(Uri.parse(fullUrl));
          if (templateResponse.statusCode != 200) {
            logger.w('[USP][PkgWidgets] Template HTTP '
                '${templateResponse.statusCode} for $templateUrl');
            continue;
          }

          final templateJson =
              jsonDecode(templateResponse.body) as Map<String, dynamic>;
          final template = PackageWidgetTemplate.fromJson(templateJson);
          templates[template.widgetId] = template;

          logger.d('[USP][PkgWidgets] Loaded: ${template.widgetId} '
              '(${template.displayName})');
        } catch (e) {
          logger.w('[USP][PkgWidgets] Failed to load template '
              '$templateUrl: $e');
        }
      }
    } catch (e) {
      logger.w('[USP][PkgWidgets] Failed to load apps.json: $e');
      _lastLoad = (templates: const {}, success: false);
      return {};
    }

    logger.d('[USP][PkgWidgets] Loaded ${templates.length} templates');
    _lastLoad = (templates: templates, success: true);
    return templates;
  }

  /// Re-fetch templates (called on manual refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadTemplates());
  }

  /// Poll for package changes — detect install/remove via key set diff.
  ///
  /// Only processes removals when the HTTP fetch was successful. A transient
  /// network failure (non-200, timeout, etc.) must NOT be interpreted as
  /// "all packages were uninstalled" — that would wipe dashboard cards.
  Future<void> _pollForChanges() async {
    try {
      final currentIds = state.valueOrNull?.keys.toSet() ?? {};
      final freshTemplates = await _loadTemplates();

      // Skip diff when fetch failed — we cannot tell removed from unavailable.
      if (!_lastLoad.success) {
        logger.d('[USP][PkgWidgets] Poll skipped (fetch failed)');
        return;
      }

      final freshIds = freshTemplates.keys.toSet();

      if (freshIds == currentIds) return; // No change

      final added = freshIds.difference(currentIds);
      final removed = currentIds.difference(freshIds);

      if (added.isNotEmpty) {
        logger.d('[USP][PkgWidgets] New widgets: $added');
      }

      // Clean up removed widgets from dashboard
      if (removed.isNotEmpty) {
        logger.d('[USP][PkgWidgets] Removed widgets: $removed');
        for (final id in removed) {
          ref
              .read(uspSliverDashboardControllerProvider.notifier)
              .removeWidget(id);
          ref.read(packageWidgetDataProvider(id).notifier).clear();
        }
      }

      state = AsyncData(freshTemplates);
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
