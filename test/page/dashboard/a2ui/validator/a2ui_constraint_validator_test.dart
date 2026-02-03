import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_constraints.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';
import 'package:privacy_gui/page/dashboard/a2ui/registry/a2ui_widget_registry.dart';
import 'package:privacy_gui/page/dashboard/a2ui/validator/a2ui_constraint_validator.dart';

void main() {
  group('A2UIConstraintValidator', () {
    late A2UIWidgetRegistry registry;
    late A2UIConstraintValidator validator;

    setUp(() {
      registry = A2UIWidgetRegistry();
      validator = A2UIConstraintValidator(registry);

      // Register test widgets with different constraints
      _registerTestWidgets(registry);
    });

    group('validateResize', () {
      test('returns success for valid dimensions', () {
        final result = validator.validateResize(
          widgetId: 'test_widget_normal',
          newColumns: 3,
          newRows: 2,
        );

        expect(result.isValid, isTrue);
        expect(result.type, ValidationResultType.success);
        expect(result.messages, isEmpty);
      });

      test('reports minimum width violation', () {
        final result = validator.validateResize(
          widgetId: 'test_widget_normal',
          newColumns: 1, // Below minColumns: 2
          newRows: 2,
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, 1);
        expect(result.messages.first, contains('Minimum width violation'));
        expect(result.messages.first, contains('requires 2 columns'));
        expect(
            result.messages.first, contains('attempting to set to 1 columns'));
      });

      test('reports maximum width violation', () {
        final result = validator.validateResize(
          widgetId: 'test_widget_normal',
          newColumns: 7, // Above maxColumns: 6
          newRows: 2,
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, 1);
        expect(result.messages.first, contains('Maximum width violation'));
        expect(result.messages.first, contains('maximum 6 columns'));
        expect(
            result.messages.first, contains('attempting to set to 7 columns'));
      });

      test('reports minimum height violation', () {
        final result = validator.validateResize(
          widgetId: 'test_widget_normal',
          newColumns: 3,
          newRows: 0, // Below minRows: 1
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, 1);
        expect(result.messages.first, contains('Minimum height violation'));
        expect(result.messages.first, contains('requires 1 rows'));
        expect(result.messages.first, contains('attempting to set to 0 rows'));
      });

      test('reports maximum height violation', () {
        final result = validator.validateResize(
          widgetId: 'test_widget_normal',
          newColumns: 3,
          newRows: 4, // Above maxRows: 3
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, 1);
        expect(result.messages.first, contains('Maximum height violation'));
        expect(result.messages.first, contains('maximum 3 rows'));
        expect(result.messages.first, contains('attempting to set to 4 rows'));
      });

      test('reports multiple violations', () {
        final result = validator.validateResize(
          widgetId: 'test_widget_normal',
          newColumns: 1, // Below minColumns: 2
          newRows: 4, // Above maxRows: 3
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, 2);
        expect(
            result.messages
                .any((msg) => msg.contains('Minimum width violation')),
            isTrue);
        expect(
            result.messages
                .any((msg) => msg.contains('Maximum height violation')),
            isTrue);
      });

      test('returns error for unknown widget', () {
        final result = validator.validateResize(
          widgetId: 'unknown_widget',
          newColumns: 3,
          newRows: 2,
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.error);
        expect(result.primaryMessage,
            contains('Widget definition not found: unknown_widget'));
      });

      test('handles edge case constraints', () {
        final result = validator.validateResize(
          widgetId: 'test_widget_strict',
          newColumns: 2, // Exactly at min/max
          newRows: 1, // Exactly at min/max
        );

        expect(result.isValid, isTrue);
        expect(result.type, ValidationResultType.success);
      });

      test('validates large widget dimensions', () {
        final result = validator.validateResize(
          widgetId: 'test_widget_large',
          newColumns: 12,
          newRows: 8,
        );

        expect(result.isValid, isTrue);
        expect(result.type, ValidationResultType.success);
      });
    });

    group('validatePlacement', () {
      test('returns success for valid placement', () {
        final result = validator.validatePlacement(
          widgetId: 'test_widget_normal',
          column: 1,
          row: 1,
          columns: 3,
          rows: 2,
          gridColumns: 12,
          existingPlacements: [],
        );

        expect(result.isValid, isTrue);
        expect(result.type, ValidationResultType.success);
        expect(result.messages, isEmpty);
      });

      test('reports negative position violation', () {
        final result = validator.validatePlacement(
          widgetId: 'test_widget_normal',
          column: -1,
          row: 0,
          columns: 3,
          rows: 2,
          gridColumns: 12,
          existingPlacements: [],
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, 1);
        expect(result.messages.first,
            contains('Position cannot be negative: (-1, 0)'));
      });

      test('reports grid boundary violation', () {
        final result = validator.validatePlacement(
          widgetId: 'test_widget_normal',
          column: 10,
          row: 1,
          columns: 4, // 10 + 4 = 14 > 12 grid columns
          rows: 2,
          gridColumns: 12,
          existingPlacements: [],
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, 1);
        expect(result.messages.first, contains('Width exceeds grid boundary'));
        expect(result.messages.first,
            contains('position 10 + width 4 = 14 > grid width 12'));
      });

      test('detects overlap with existing widget', () {
        final existingPlacements = [
          WidgetPlacement(
            widgetId: 'existing_widget',
            column: 2,
            row: 1,
            columns: 3,
            rows: 2,
          ),
        ];

        final result = validator.validatePlacement(
          widgetId: 'test_widget_normal',
          column: 1,
          row: 1,
          columns: 3, // 1-4 overlaps with 2-5
          rows: 2, // 1-3 overlaps with 1-3
          gridColumns: 12,
          existingPlacements: existingPlacements,
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, 1);
        expect(
            result.messages.first, contains('Overlaps with existing widget'));
        expect(result.messages.first,
            contains('"test_widget_normal" overlaps with "existing_widget"'));
      });

      test('allows adjacent widgets without overlap', () {
        final existingPlacements = [
          WidgetPlacement(
            widgetId: 'existing_widget',
            column: 4,
            row: 1,
            columns: 3,
            rows: 2,
          ),
        ];

        final result = validator.validatePlacement(
          widgetId: 'test_widget_normal',
          column: 1,
          row: 1,
          columns: 3, // 1-4, adjacent to 4-7
          rows: 2,
          gridColumns: 12,
          existingPlacements: existingPlacements,
        );

        expect(result.isValid, isTrue);
        expect(result.type, ValidationResultType.success);
      });

      test('ignores self in overlap detection', () {
        final existingPlacements = [
          WidgetPlacement(
            widgetId: 'test_widget_normal', // Same widget ID
            column: 1,
            row: 1,
            columns: 3,
            rows: 2,
          ),
        ];

        final result = validator.validatePlacement(
          widgetId: 'test_widget_normal',
          column: 1,
          row: 1,
          columns: 3,
          rows: 2,
          gridColumns: 12,
          existingPlacements: existingPlacements,
        );

        expect(result.isValid, isTrue);
        expect(result.type, ValidationResultType.success);
      });

      test('handles multiple existing widgets', () {
        final existingPlacements = [
          WidgetPlacement(
            widgetId: 'widget1',
            column: 0,
            row: 0,
            columns: 2,
            rows: 2,
          ),
          WidgetPlacement(
            widgetId: 'widget2',
            column: 4,
            row: 0,
            columns: 2,
            rows: 2,
          ),
        ];

        final result = validator.validatePlacement(
          widgetId: 'test_widget_normal',
          column: 2,
          row: 0,
          columns: 2, // Fits between existing widgets
          rows: 2,
          gridColumns: 12,
          existingPlacements: existingPlacements,
        );

        expect(result.isValid, isTrue);
        expect(result.type, ValidationResultType.success);
      });

      test('reports multiple violations', () {
        final existingPlacements = [
          WidgetPlacement(
            widgetId: 'existing_widget',
            column: 0,
            row: 0,
            columns: 3,
            rows: 2,
          ),
        ];

        final result = validator.validatePlacement(
          widgetId: 'test_widget_normal',
          column: -1, // Negative position
          row: 0,
          columns: 15, // Exceeds grid boundary (even if position were valid)
          rows: 2,
          gridColumns: 12,
          existingPlacements: existingPlacements,
        );

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages.length, greaterThan(1));
      });
    });

    group('suggestValidResize', () {
      test('returns original size when valid', () {
        final suggestion = validator.suggestValidResize(
          widgetId: 'test_widget_normal',
          requestedColumns: 3,
          requestedRows: 2,
        );

        expect(suggestion.columns, 3);
        expect(suggestion.rows, 2);
        expect(suggestion.adjusted, isFalse);
        expect(suggestion.reason, isNull);
      });

      test('clamps columns to minimum', () {
        final suggestion = validator.suggestValidResize(
          widgetId: 'test_widget_normal',
          requestedColumns: 1, // Below minColumns: 2
          requestedRows: 2,
        );

        expect(suggestion.columns, 2);
        expect(suggestion.rows, 2);
        expect(suggestion.adjusted, isTrue);
        expect(suggestion.reason, 'Adjusted to meet constraints');
      });

      test('clamps columns to maximum', () {
        final suggestion = validator.suggestValidResize(
          widgetId: 'test_widget_normal',
          requestedColumns: 8, // Above maxColumns: 6
          requestedRows: 2,
        );

        expect(suggestion.columns, 6);
        expect(suggestion.rows, 2);
        expect(suggestion.adjusted, isTrue);
        expect(suggestion.reason, 'Adjusted to meet constraints');
      });

      test('clamps rows to minimum', () {
        final suggestion = validator.suggestValidResize(
          widgetId: 'test_widget_normal',
          requestedColumns: 3,
          requestedRows: 0, // Below minRows: 1
        );

        expect(suggestion.columns, 3);
        expect(suggestion.rows, 1);
        expect(suggestion.adjusted, isTrue);
        expect(suggestion.reason, 'Adjusted to meet constraints');
      });

      test('clamps rows to maximum', () {
        final suggestion = validator.suggestValidResize(
          widgetId: 'test_widget_normal',
          requestedColumns: 3,
          requestedRows: 5, // Above maxRows: 3
        );

        expect(suggestion.columns, 3);
        expect(suggestion.rows, 3);
        expect(suggestion.adjusted, isTrue);
        expect(suggestion.reason, 'Adjusted to meet constraints');
      });

      test('clamps both dimensions', () {
        final suggestion = validator.suggestValidResize(
          widgetId: 'test_widget_normal',
          requestedColumns: 1, // Below minColumns: 2
          requestedRows: 5, // Above maxRows: 3
        );

        expect(suggestion.columns, 2);
        expect(suggestion.rows, 3);
        expect(suggestion.adjusted, isTrue);
        expect(suggestion.reason, 'Adjusted to meet constraints');
      });

      test('handles unknown widget gracefully', () {
        final suggestion = validator.suggestValidResize(
          widgetId: 'unknown_widget',
          requestedColumns: 3,
          requestedRows: 2,
        );

        expect(suggestion.columns, 3);
        expect(suggestion.rows, 2);
        expect(suggestion.adjusted, isFalse);
        expect(suggestion.reason, 'Widget definition not found');
      });

      test('handles strict constraints', () {
        final suggestion = validator.suggestValidResize(
          widgetId: 'test_widget_strict',
          requestedColumns: 5, // Will be clamped to 2
          requestedRows: 3, // Will be clamped to 1
        );

        expect(suggestion.columns, 2);
        expect(suggestion.rows, 1);
        expect(suggestion.adjusted, isTrue);
        expect(suggestion.reason, 'Adjusted to meet constraints');
      });
    });

    group('ValidationResult', () {
      test('success factory creates valid result', () {
        final result = ValidationResult.success();

        expect(result.isValid, isTrue);
        expect(result.type, ValidationResultType.success);
        expect(result.messages, isEmpty);
        expect(result.primaryMessage, isEmpty);
        expect(result.allMessages, isEmpty);
      });

      test('violation factory creates invalid result', () {
        final violations = ['Error 1', 'Error 2'];
        final result = ValidationResult.violation(violations);

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.violation);
        expect(result.messages, violations);
        expect(result.primaryMessage, 'Error 1');
        expect(result.allMessages, 'Error 1\nError 2');
      });

      test('error factory creates error result', () {
        const error = 'Test error';
        final result = ValidationResult.error(error);

        expect(result.isValid, isFalse);
        expect(result.type, ValidationResultType.error);
        expect(result.messages, [error]);
        expect(result.primaryMessage, error);
        expect(result.allMessages, error);
      });
    });

    group('WidgetPlacement', () {
      test('creates placement correctly', () {
        const placement = WidgetPlacement(
          widgetId: 'test',
          column: 1,
          row: 2,
          columns: 3,
          rows: 4,
        );

        expect(placement.widgetId, 'test');
        expect(placement.column, 1);
        expect(placement.row, 2);
        expect(placement.columns, 3);
        expect(placement.rows, 4);
        expect(placement.toString(), contains('test'));
        expect(placement.toString(), contains('(1,2)'));
        expect(placement.toString(), contains('3x4'));
      });
    });

    group('ResizeSuggestion', () {
      test('creates suggestion correctly', () {
        const suggestion = ResizeSuggestion(
          columns: 3,
          rows: 2,
          adjusted: true,
          reason: 'Test reason',
        );

        expect(suggestion.columns, 3);
        expect(suggestion.rows, 2);
        expect(suggestion.adjusted, isTrue);
        expect(suggestion.reason, 'Test reason');
        expect(suggestion.toString(), contains('3x2'));
        expect(suggestion.toString(), contains('adjusted: true'));
        expect(suggestion.toString(), contains('Test reason'));
      });

      test('creates suggestion without reason', () {
        const suggestion = ResizeSuggestion(
          columns: 4,
          rows: 1,
          adjusted: false,
        );

        expect(suggestion.reason, isNull);
        expect(suggestion.toString(), contains('4x1'));
        expect(suggestion.toString(), contains('adjusted: false'));
        expect(suggestion.toString(), isNot(contains('reason:')));
      });
    });
  });
}

/// Helper function to register test widgets with various constraints
void _registerTestWidgets(A2UIWidgetRegistry registry) {
  // Normal widget with typical constraints
  final normalWidget = A2UIWidgetDefinition.fromJson(const {
    'widgetId': 'test_widget_normal',
    'displayName': 'Test Normal Widget',
    'constraints': {
      'minColumns': 2,
      'maxColumns': 6,
      'preferredColumns': 4,
      'minRows': 1,
      'maxRows': 3,
      'preferredRows': 2,
    },
    'template': {
      'type': 'Container',
      'children': [],
    },
  });

  // Strict widget with same min/max values
  final strictWidget = A2UIWidgetDefinition.fromJson(const {
    'widgetId': 'test_widget_strict',
    'displayName': 'Test Strict Widget',
    'constraints': {
      'minColumns': 2,
      'maxColumns': 2,
      'preferredColumns': 2,
      'minRows': 1,
      'maxRows': 1,
      'preferredRows': 1,
    },
    'template': {
      'type': 'Container',
      'children': [],
    },
  });

  // Large widget with wide constraints
  final largeWidget = A2UIWidgetDefinition.fromJson(const {
    'widgetId': 'test_widget_large',
    'displayName': 'Test Large Widget',
    'constraints': {
      'minColumns': 4,
      'maxColumns': 12,
      'preferredColumns': 8,
      'minRows': 2,
      'maxRows': 8,
      'preferredRows': 4,
    },
    'template': {
      'type': 'Container',
      'children': [],
    },
  });

  registry.register(normalWidget);
  registry.register(strictWidget);
  registry.register(largeWidget);
}
