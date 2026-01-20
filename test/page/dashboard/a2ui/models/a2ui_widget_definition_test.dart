import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';

void main() {
  group('A2UIWidgetDefinition', () {
    test('creates from JSON', () {
      final json = {
        'widgetId': 'test_widget',
        'displayName': 'Test Widget',
        'description': 'A test widget',
        'constraints': {
          'minColumns': 2,
          'maxColumns': 4,
          'preferredColumns': 3,
          'minRows': 1,
          'maxRows': 2,
          'preferredRows': 1,
        },
        'template': {
          'type': 'Column',
          'children': [
            {
              'type': 'AppText',
              'props': {'text': 'Hello'}
            },
          ],
        },
      };

      final definition = A2UIWidgetDefinition.fromJson(json);

      expect(definition.widgetId, 'test_widget');
      expect(definition.displayName, 'Test Widget');
      expect(definition.description, 'A test widget');
      expect(definition.constraints.minColumns, 2);
      expect(definition.constraints.maxColumns, 4);
      expect(definition.template.type, 'Column');
    });

    test('uses widgetId as displayName when not provided', () {
      final json = {
        'widgetId': 'my_widget',
        'template': {'type': 'Container'},
      };

      final definition = A2UIWidgetDefinition.fromJson(json);

      expect(definition.displayName, 'my_widget');
    });

    test('uses default constraints when not provided', () {
      final json = {
        'widgetId': 'my_widget',
        'template': {'type': 'Container'},
      };

      final definition = A2UIWidgetDefinition.fromJson(json);

      expect(definition.constraints.minColumns, 2);
      expect(definition.constraints.preferredColumns, 4);
    });

    test('converts to WidgetSpec', () {
      final json = {
        'widgetId': 'test_widget',
        'displayName': 'Test Widget',
        'description': 'A test widget',
        'constraints': {
          'minColumns': 2,
          'maxColumns': 4,
          'preferredColumns': 3,
          'minRows': 1,
          'maxRows': 2,
          'preferredRows': 1,
        },
        'template': {'type': 'Container'},
      };

      final definition = A2UIWidgetDefinition.fromJson(json);
      final spec = definition.toWidgetSpec();

      expect(spec.id, 'test_widget');
      expect(spec.displayName, 'Test Widget');
      expect(spec.description, 'A test widget');

      final constraints = spec.getConstraints(DisplayMode.normal);
      expect(constraints.minColumns, 2);
      expect(constraints.maxColumns, 4);
    });

    test('toWidgetSpec sets defaultConstraints', () {
      final json = {
        'widgetId': 'test_widget',
        'constraints': {
          'minColumns': 3,
          'maxColumns': 6,
          'preferredColumns': 4,
        },
        'template': {'type': 'Container'},
      };

      final definition = A2UIWidgetDefinition.fromJson(json);
      final spec = definition.toWidgetSpec();

      expect(spec.defaultConstraints, isNotNull);
      expect(spec.defaultConstraints!.minColumns, 3);
    });

    test('throws assertions error when widgetId is empty', () {
      expect(
        () => A2UIWidgetDefinition.fromJson(const {
          'widgetId': '',
          'displayName': 'Test Widget',
          'template': {'type': 'Container'},
        }),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws assertions error when displayName is empty', () {
      expect(
        () => A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'test_widget',
          'displayName': '',
          'template': {'type': 'Container'},
        }),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
