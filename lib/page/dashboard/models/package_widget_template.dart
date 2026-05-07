import 'package:equatable/equatable.dart';
import 'package:ui_kit_library/ui_kit.dart';

import 'display_mode.dart';
import 'widget_spec.dart';

/// Parsed widget template from a router-deployed package.
///
/// Loaded from `/api/widgets/{id}.json`. Contains the widget spec,
/// subscription config, and the UiTreeBuilder-compatible template JSON.
class PackageWidgetTemplate extends Equatable {
  final String widgetId;
  final String displayName;
  final String? description;
  final WidgetGridConstraints constraints;
  final WidgetSubscriptionConfig? subscription;
  final HttpDataSourceConfig? dataSource;
  final String? navigateTo;
  final String? icon;
  final String? iconColor;

  /// Header badge text — `String` for static, `Map` for `$bind`/`$compute`.
  final Object? headerBadge;

  /// Header subtitle — `String` for static, `Map` for `$bind`/`$compute`.
  final Object? headerExtra;
  final Map<String, dynamic> template;

  const PackageWidgetTemplate({
    required this.widgetId,
    required this.displayName,
    this.description,
    required this.constraints,
    this.subscription,
    this.dataSource,
    this.navigateTo,
    this.icon,
    this.iconColor,
    this.headerBadge,
    this.headerExtra,
    required this.template,
  });

  /// Parse from JSON fetched from the template URL.
  factory PackageWidgetTemplate.fromJson(Map<String, dynamic> json) {
    final c = json['constraints'] as Map<String, dynamic>? ?? {};
    return PackageWidgetTemplate(
      widgetId: json['widgetId'] as String,
      displayName: json['displayName'] as String? ?? 'Package Widget',
      description: json['description'] as String?,
      constraints: WidgetGridConstraints(
        minColumns: c['minColumns'] as int? ?? 3,
        maxColumns: c['maxColumns'] as int? ?? 6,
        preferredColumns: c['preferredColumns'] as int? ?? 4,
        heightStrategy: HeightStrategy.strict(
          (c['preferredRows'] as num? ?? 2).toDouble(),
        ),
        minHeightRows: c['minRows'] as int? ?? 1,
        maxHeightRows: c['maxRows'] as int? ?? 6,
      ),
      subscription: json['subscription'] != null
          ? WidgetSubscriptionConfig.fromJson(
              json['subscription'] as Map<String, dynamic>)
          : null,
      dataSource: json['dataSource'] != null
          ? HttpDataSourceConfig.fromJson(
              json['dataSource'] as Map<String, dynamic>)
          : null,
      navigateTo: json['navigateTo'] as String?,
      icon: json['icon'] as String?,
      iconColor: json['iconColor'] as String?,
      headerBadge: json['headerBadge'], // String | Map | null
      headerExtra: json['headerExtra'], // String | Map | null
      template: json['template'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert to [WidgetSpec] for the dashboard grid system.
  WidgetSpec toWidgetSpec() {
    return WidgetSpec(
      id: widgetId,
      displayName: displayName,
      description: description,
      constraints: {DisplayMode.normal: constraints},
      defaultConstraints: constraints,
      canHide: true,
    );
  }

  @override
  List<Object?> get props => [
        widgetId,
        displayName,
        description,
        constraints,
        subscription,
        dataSource,
        navigateTo,
        icon,
        iconColor,
        headerBadge,
        headerExtra,
        template,
      ];
}

/// HTTP/CGI data source configuration from widget JSON.
///
/// Used by package widgets that fetch data from router CGI endpoints
/// instead of USP. Mutually exclusive with [WidgetSubscriptionConfig].
class HttpDataSourceConfig extends Equatable {
  final String type;
  final String url;
  final String method;
  final Map<String, dynamic>? body;
  final int refreshInterval;
  final Map<String, String> mapping;

  const HttpDataSourceConfig({
    this.type = 'http',
    required this.url,
    this.method = 'POST',
    this.body,
    this.refreshInterval = 0,
    required this.mapping,
  });

  factory HttpDataSourceConfig.fromJson(Map<String, dynamic> json) {
    return HttpDataSourceConfig(
      type: json['type'] as String? ?? 'http',
      url: json['url'] as String,
      method: json['method'] as String? ?? 'POST',
      body: json['body'] as Map<String, dynamic>?,
      refreshInterval: json['refreshInterval'] as int? ?? 0,
      mapping: Map<String, String>.from(json['mapping'] as Map),
    );
  }

  @override
  List<Object?> get props =>
      [type, url, method, body, refreshInterval, mapping];
}

/// SSE subscription configuration from widget JSON.
class WidgetSubscriptionConfig extends Equatable {
  final List<String> paths;
  final String notifType;

  const WidgetSubscriptionConfig({
    required this.paths,
    required this.notifType,
  });

  factory WidgetSubscriptionConfig.fromJson(Map<String, dynamic> json) {
    return WidgetSubscriptionConfig(
      paths: (json['paths'] as List<dynamic>).cast<String>(),
      notifType: json['notifType'] as String? ?? 'ValueChange',
    );
  }

  @override
  List<Object?> get props => [paths, notifType];
}
