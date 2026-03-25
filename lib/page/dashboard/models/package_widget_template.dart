import 'package:equatable/equatable.dart';

import 'display_mode.dart';
import 'height_strategy.dart';
import 'widget_grid_constraints.dart';
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
  final Map<String, dynamic> template;

  const PackageWidgetTemplate({
    required this.widgetId,
    required this.displayName,
    this.description,
    required this.constraints,
    this.subscription,
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
  List<Object?> get props =>
      [widgetId, displayName, description, constraints, subscription, template];
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
