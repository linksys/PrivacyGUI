import 'package:equatable/equatable.dart';
import 'display_mode.dart';

/// Configuration for a single dashboard widget in the custom grid layout.
///
/// This class stores all user-configurable properties for a widget:
/// - Order: Position in the widget list
/// - Visibility: Whether the widget is shown
/// - DisplayMode: Compact, normal, or expanded
/// - Column span: Width in columns (1-12 based on UI Kit column system)
class GridWidgetConfig extends Equatable {
  /// Unique widget identifier
  final String widgetId;

  /// Sort order (0-based index)
  final int order;

  /// Whether this widget is visible
  final bool visible;

  /// Display mode for this widget
  final DisplayMode displayMode;

  /// Column span (1-12, null = use default from WidgetSpec)
  final int? columnSpan;

  const GridWidgetConfig({
    required this.widgetId,
    required this.order,
    this.visible = true,
    this.displayMode = DisplayMode.normal,
    this.columnSpan,
  });

  GridWidgetConfig copyWith({
    String? widgetId,
    int? order,
    bool? visible,
    DisplayMode? displayMode,
    int? columnSpan,
    bool clearColumnSpan = false,
  }) {
    return GridWidgetConfig(
      widgetId: widgetId ?? this.widgetId,
      order: order ?? this.order,
      visible: visible ?? this.visible,
      displayMode: displayMode ?? this.displayMode,
      columnSpan: clearColumnSpan ? null : (columnSpan ?? this.columnSpan),
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => {
        'widgetId': widgetId,
        'order': order,
        'visible': visible,
        'displayMode': displayMode.name,
        if (columnSpan != null) 'columnSpan': columnSpan,
      };

  /// JSON deserialization
  factory GridWidgetConfig.fromJson(Map<String, dynamic> json) {
    return GridWidgetConfig(
      widgetId: json['widgetId'] as String,
      order: json['order'] as int? ?? 0,
      visible: json['visible'] as bool? ?? true,
      displayMode: DisplayMode.values.byName(
        json['displayMode'] as String? ?? 'normal',
      ),
      columnSpan: json['columnSpan'] as int?,
    );
  }

  @override
  List<Object?> get props =>
      [widgetId, order, visible, displayMode, columnSpan];
}
