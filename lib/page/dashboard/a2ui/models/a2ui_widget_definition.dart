import 'package:equatable/equatable.dart';

import '../../models/display_mode.dart';
import '../../models/widget_spec.dart';
import 'a2ui_constraints.dart';
import 'a2ui_template.dart';

/// Complete definition of an A2UI widget.
///
/// Contains all information needed to register and render an A2UI widget:
/// - Identification (widgetId, displayName)
/// - Grid constraints
/// - UI template
class A2UIWidgetDefinition extends Equatable {
  /// Unique identifier for the widget.
  final String widgetId;

  /// Human-readable display name.
  final String displayName;

  /// Optional description.
  final String? description;

  /// Grid constraints for this widget.
  final A2UIConstraints constraints;

  /// UI template defining the widget structure.
  final A2UITemplateNode template;

  const A2UIWidgetDefinition({
    required this.widgetId,
    required this.displayName,
    this.description,
    required this.constraints,
    required this.template,
  });

  /// Creates a widget definition from JSON.
  ///
  /// Expected format:
  /// ```json
  /// {
  ///   "widgetId": "custom_device_count",
  ///   "displayName": "Device Count",
  ///   "description": "Shows connected device count",
  ///   "constraints": { ... },
  ///   "template": { ... }
  /// }
  /// ```
  factory A2UIWidgetDefinition.fromJson(Map<String, dynamic> json) {
    return A2UIWidgetDefinition(
      widgetId: json['widgetId'] as String,
      displayName: json['displayName'] as String? ?? json['widgetId'] as String,
      description: json['description'] as String?,
      constraints: A2UIConstraints.fromJson(
        json['constraints'] as Map<String, dynamic>? ?? {},
      ),
      template: A2UITemplateNode.fromJson(
        json['template'] as Map<String, dynamic>? ?? {'type': 'Container'},
      ),
    );
  }

  /// Converts to [WidgetSpec] for use with the dashboard grid.
  ///
  /// Since A2UI widgets use a single constraint set (no DisplayMode variants),
  /// this creates a WidgetSpec with [defaultConstraints] set.
  WidgetSpec toWidgetSpec() {
    return WidgetSpec(
      id: widgetId,
      displayName: displayName,
      description: description ?? '',
      defaultConstraints: constraints.toGridConstraints(),
      // No per-mode constraints for A2UI widgets
      constraints: {
        DisplayMode.normal: constraints.toGridConstraints(),
      },
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'widgetId': widgetId,
        'displayName': displayName,
        if (description != null) 'description': description,
        'constraints': constraints.toJson(),
        // Note: template serialization would need additional implementation
      };

  @override
  List<Object?> get props =>
      [widgetId, displayName, description, constraints, template];
}
