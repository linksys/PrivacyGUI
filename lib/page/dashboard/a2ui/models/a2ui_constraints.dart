import 'package:equatable/equatable.dart';

import '../../models/height_strategy.dart';
import '../../models/widget_grid_constraints.dart';

/// Grid constraints for A2UI widgets.
///
/// Defines the size limits for an A2UI widget within the 12-column grid.
/// Unlike native widgets, A2UI widgets use a single constraint set
/// (DisplayMode is optional).
class A2UIConstraints extends Equatable {
  /// Minimum width in grid columns (1-12).
  final int minColumns;

  /// Maximum width in grid columns (1-12).
  final int maxColumns;

  /// Preferred/default width in grid columns.
  final int preferredColumns;

  /// Minimum height in grid rows.
  final int minRows;

  /// Maximum height in grid rows.
  final int maxRows;

  /// Preferred/default height in grid rows.
  final int preferredRows;

  const A2UIConstraints({
    required this.minColumns,
    required this.maxColumns,
    required this.preferredColumns,
    required this.minRows,
    required this.maxRows,
    required this.preferredRows,
  })  : assert(minColumns > 0, 'minColumns must be positive'),
        assert(maxColumns >= minColumns, 'maxColumns must be >= minColumns'),
        assert(maxColumns <= 12, 'maxColumns must be <= 12'),
        assert(preferredColumns >= minColumns && preferredColumns <= maxColumns,
            'preferredColumns must be between min and max'),
        assert(minRows > 0, 'minRows must be positive'),
        assert(maxRows >= minRows, 'maxRows must be >= minRows'),
        assert(preferredRows >= minRows && preferredRows <= maxRows,
            'preferredRows must be between min and max');

  /// Creates constraints from JSON.
  factory A2UIConstraints.fromJson(Map<String, dynamic> json) {
    return A2UIConstraints(
      minColumns: json['minColumns'] as int? ?? 2,
      maxColumns: json['maxColumns'] as int? ?? 12,
      preferredColumns: json['preferredColumns'] as int? ?? 4,
      minRows: json['minRows'] as int? ?? 1,
      maxRows: json['maxRows'] as int? ?? 12,
      preferredRows: json['preferredRows'] as int? ?? 2,
    );
  }

  /// Converts to [WidgetGridConstraints] for use with the dashboard grid.
  WidgetGridConstraints toGridConstraints() {
    return WidgetGridConstraints(
      minColumns: minColumns,
      maxColumns: maxColumns,
      preferredColumns: preferredColumns,
      minHeightRows: minRows,
      maxHeightRows: maxRows,
      heightStrategy: HeightStrategy.strict(preferredRows.toDouble()),
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
        'minColumns': minColumns,
        'maxColumns': maxColumns,
        'preferredColumns': preferredColumns,
        'minRows': minRows,
        'maxRows': maxRows,
        'preferredRows': preferredRows,
      };

  @override
  List<Object?> get props => [
        minColumns,
        maxColumns,
        preferredColumns,
        minRows,
        maxRows,
        preferredRows,
      ];
}
