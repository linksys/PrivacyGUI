/// Demo Package Widget Loader for static widget templates.
///
/// Loads predefined package widget JSON files from assets instead of
/// fetching them dynamically from /api/apps.json like the production version.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';

/// Demo version of PackageWidgetLoader that uses static asset files.
class DemoPackageWidgetLoader extends PackageWidgetLoader {
  @override
  Future<Map<String, PackageWidgetTemplate>> build() async {
    // Skip the apps capability check and polling setup from the base class
    // Just load demo templates directly from assets
    final templates = await _loadDemoTemplates();

    logger.d('[Demo][PkgWidgets] Loaded ${templates.length} demo templates');
    return templates;
  }

  /// Load all demo package widget templates from predefined asset files.
  Future<Map<String, PackageWidgetTemplate>> _loadDemoTemplates() async {
    final templates = <String, PackageWidgetTemplate>{};

    // List of demo widget asset paths
    final assetPaths = [
      'assets/a2ui/widgets/action_demo_widget.json',
      'assets/a2ui/widgets/chart_integration_demo.json',
      'assets/a2ui/widgets/demo_network_monitor.json',
      'assets/a2ui/widgets/demo_security_center.json',
      'assets/a2ui/widgets/demo_smart_qos.json',
      'assets/a2ui/widgets/demo_smart_home_hub.json',
    ];

    for (final assetPath in assetPaths) {
      try {
        final template = await _loadTemplateFromAsset(assetPath);
        if (template != null) {
          templates[template.widgetId] = template;
          logger.d('[Demo][PkgWidgets] Loaded: ${template.widgetId} '
              '(${template.displayName})');
        }
      } catch (e) {
        logger.w('[Demo][PkgWidgets] Failed to load $assetPath: $e');
      }
    }

    return templates;
  }

  /// Load a single template from asset path.
  Future<PackageWidgetTemplate?> _loadTemplateFromAsset(
      String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PackageWidgetTemplate.fromJson(json);
    } catch (e) {
      logger.w('[Demo][PkgWidgets] Failed to parse template $assetPath: $e');
      return null;
    }
  }

  /// Manual refresh for demo (just rebuilds from assets).
  @override
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _loadDemoTemplates());
  }
}