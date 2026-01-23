import 'package:flutter/foundation.dart';

import '../registry/a2ui_widget_registry.dart';

/// Runtime validator for A2UI widget constraints and placement rules.
///
/// Validates widget resize operations and placement constraints to ensure
/// dashboard layout integrity and prevent invalid configurations.
class A2UIConstraintValidator {
  final A2UIWidgetRegistry _registry;

  const A2UIConstraintValidator(this._registry);

  /// Validates if a widget can be resized to the specified dimensions.
  ///
  /// Returns [ValidationResult] with details about constraint violations.
  ValidationResult validateResize({
    required String widgetId,
    required int newColumns,
    required int newRows,
  }) {
    try {
      final definition = _registry.get(widgetId);
      if (definition == null) {
        return ValidationResult.error(
          'Widget definition not found: $widgetId',
        );
      }

      final constraints = definition.constraints;
      final violations = <String>[];

      // Check column constraints
      if (newColumns < constraints.minColumns) {
        violations.add(
          'Minimum width violation: requires ${constraints.minColumns} columns, but attempting to set to $newColumns columns',
        );
      }

      if (newColumns > constraints.maxColumns) {
        violations.add(
          'Maximum width violation: maximum ${constraints.maxColumns} columns, but attempting to set to $newColumns columns',
        );
      }

      // Check row constraints
      if (newRows < constraints.minRows) {
        violations.add(
          'Minimum height violation: requires ${constraints.minRows} rows, but attempting to set to $newRows rows',
        );
      }

      if (newRows > constraints.maxRows) {
        violations.add(
          'Maximum height violation: maximum ${constraints.maxRows} rows, but attempting to set to $newRows rows',
        );
      }

      if (violations.isEmpty) {
        return ValidationResult.success();
      } else {
        return ValidationResult.violation(violations);
      }
    } catch (e, stackTrace) {
      debugPrint('Error validating resize for widget "$widgetId": $e');
      debugPrint('Stack trace: $stackTrace');
      return ValidationResult.error(
        'Validation error: $e',
      );
    }
  }

  /// Validates if a widget can be placed at the specified grid position.
  ///
  /// Checks for overlaps with existing widgets and grid boundary violations.
  ValidationResult validatePlacement({
    required String widgetId,
    required int column,
    required int row,
    required int columns,
    required int rows,
    required int gridColumns,
    required List<WidgetPlacement> existingPlacements,
  }) {
    try {
      final violations = <String>[];

      // Check grid boundary constraints
      if (column < 0 || row < 0) {
        violations.add('Position cannot be negative: ($column, $row)');
      }

      if (column + columns > gridColumns) {
        violations.add(
          'Width exceeds grid boundary: position $column + width $columns = ${column + columns} > grid width $gridColumns',
        );
      }

      // Check for overlaps with existing widgets
      final newPlacement = WidgetPlacement(
        widgetId: widgetId,
        column: column,
        row: row,
        columns: columns,
        rows: rows,
      );

      for (final existing in existingPlacements) {
        if (existing.widgetId == widgetId) continue; // Skip self

        if (_isOverlapping(newPlacement, existing)) {
          violations.add(
            'Overlaps with existing widget: "$widgetId" overlaps with "${existing.widgetId}"',
          );
        }
      }

      if (violations.isEmpty) {
        return ValidationResult.success();
      } else {
        return ValidationResult.violation(violations);
      }
    } catch (e, stackTrace) {
      debugPrint('Error validating placement for widget "$widgetId": $e');
      debugPrint('Stack trace: $stackTrace');
      return ValidationResult.error(
        'Placement validation error: $e',
      );
    }
  }

  /// Suggests valid resize dimensions based on constraints.
  ///
  /// Returns the closest valid dimensions to the requested size.
  ResizeSuggestion suggestValidResize({
    required String widgetId,
    required int requestedColumns,
    required int requestedRows,
  }) {
    final definition = _registry.get(widgetId);
    if (definition == null) {
      return ResizeSuggestion(
        columns: requestedColumns,
        rows: requestedRows,
        adjusted: false,
        reason: 'Widget definition not found',
      );
    }

    final constraints = definition.constraints;

    // Clamp to valid ranges
    final validColumns = requestedColumns.clamp(
      constraints.minColumns,
      constraints.maxColumns,
    );

    final validRows = requestedRows.clamp(
      constraints.minRows,
      constraints.maxRows,
    );

    final wasAdjusted = validColumns != requestedColumns || validRows != requestedRows;

    return ResizeSuggestion(
      columns: validColumns,
      rows: validRows,
      adjusted: wasAdjusted,
      reason: wasAdjusted ? 'Adjusted to meet constraints' : null,
    );
  }

  /// Checks if two widget placements overlap.
  bool _isOverlapping(WidgetPlacement a, WidgetPlacement b) {
    // Check if rectangles overlap
    final aRight = a.column + a.columns;
    final aBottom = a.row + a.rows;
    final bRight = b.column + b.columns;
    final bBottom = b.row + b.rows;

    return !(a.column >= bRight ||
             b.column >= aRight ||
             a.row >= bBottom ||
             b.row >= aBottom);
  }
}

/// Result of constraint validation operation.
class ValidationResult {
  final bool isValid;
  final ValidationResultType type;
  final List<String> messages;

  const ValidationResult._({
    required this.isValid,
    required this.type,
    required this.messages,
  });

  /// Creates a successful validation result.
  factory ValidationResult.success() {
    return const ValidationResult._(
      isValid: true,
      type: ValidationResultType.success,
      messages: [],
    );
  }

  /// Creates a validation result with constraint violations.
  factory ValidationResult.violation(List<String> violations) {
    return ValidationResult._(
      isValid: false,
      type: ValidationResultType.violation,
      messages: violations,
    );
  }

  /// Creates a validation result with an error.
  factory ValidationResult.error(String error) {
    return ValidationResult._(
      isValid: false,
      type: ValidationResultType.error,
      messages: [error],
    );
  }

  /// Gets the primary message for display.
  String get primaryMessage => messages.isNotEmpty ? messages.first : '';

  /// Gets all messages joined with line breaks.
  String get allMessages => messages.join('\n');
}

/// Type of validation result.
enum ValidationResultType {
  success,
  violation,
  error,
}

/// Represents a widget placement in the dashboard grid.
class WidgetPlacement {
  final String widgetId;
  final int column;
  final int row;
  final int columns;
  final int rows;

  const WidgetPlacement({
    required this.widgetId,
    required this.column,
    required this.row,
    required this.columns,
    required this.rows,
  });

  @override
  String toString() {
    return 'WidgetPlacement(id: $widgetId, pos: ($column,$row), size: ${columns}x$rows)';
  }
}

/// Suggestion for valid resize dimensions.
class ResizeSuggestion {
  final int columns;
  final int rows;
  final bool adjusted;
  final String? reason;

  const ResizeSuggestion({
    required this.columns,
    required this.rows,
    required this.adjusted,
    this.reason,
  });

  @override
  String toString() {
    return 'ResizeSuggestion(${columns}x$rows, adjusted: $adjusted${reason != null ? ', reason: $reason' : ''})';
  }
}