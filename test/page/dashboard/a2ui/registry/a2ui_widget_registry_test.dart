import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_constraints.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_template.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';
import 'package:privacy_gui/page/dashboard/a2ui/registry/a2ui_widget_registry.dart';

void main() {
  group('A2UIWidgetRegistry', () {
    late A2UIWidgetRegistry registry;

    setUp(() {
      registry = A2UIWidgetRegistry();
    });

    test('starts empty', () {
      expect(registry.length, 0);
      expect(registry.widgetIds, isEmpty);
    });

    test('register adds widget', () {
      final definition = A2UIWidgetDefinition(
        widgetId: 'test_widget',
        displayName: 'Test',
        constraints: const A2UIConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          minRows: 1,
          maxRows: 2,
          preferredRows: 1,
        ),
        template: const A2UILeafNode(type: 'Container'),
      );

      registry.register(definition);

      expect(registry.length, 1);
      expect(registry.contains('test_widget'), isTrue);
    });

    test('get returns registered widget', () {
      final definition = A2UIWidgetDefinition(
        widgetId: 'test_widget',
        displayName: 'Test',
        constraints: const A2UIConstraints(
          minColumns: 2,
          maxColumns: 4,
          preferredColumns: 3,
          minRows: 1,
          maxRows: 2,
          preferredRows: 1,
        ),
        template: const A2UILeafNode(type: 'Container'),
      );

      registry.register(definition);

      expect(registry.get('test_widget'), equals(definition));
    });

    test('get returns null for unregistered widget', () {
      expect(registry.get('nonexistent'), isNull);
    });

    test('contains returns false for unregistered widget', () {
      expect(registry.contains('nonexistent'), isFalse);
    });

    test('registerFromJson adds widget from JSON', () {
      final json = {
        'widgetId': 'json_widget',
        'displayName': 'JSON Widget',
        'constraints': {'minColumns': 2, 'maxColumns': 4},
        'template': {'type': 'Container'},
      };

      registry.registerFromJson(json);

      expect(registry.contains('json_widget'), isTrue);
      expect(registry.get('json_widget')?.displayName, 'JSON Widget');
    });

    test('registerAllFromJson adds multiple widgets', () {
      final jsonList = [
        {
          'widgetId': 'widget_1',
          'template': {'type': 'A'}
        },
        {
          'widgetId': 'widget_2',
          'template': {'type': 'B'}
        },
        {
          'widgetId': 'widget_3',
          'template': {'type': 'C'}
        },
      ];

      registry.registerAllFromJson(jsonList);

      expect(registry.length, 3);
      expect(registry.contains('widget_1'), isTrue);
      expect(registry.contains('widget_2'), isTrue);
      expect(registry.contains('widget_3'), isTrue);
    });

    test('widgetSpecs returns WidgetSpec for each registered widget', () {
      registry.registerFromJson({
        'widgetId': 'widget_1',
        'displayName': 'Widget 1',
        'template': {'type': 'A'},
      });
      registry.registerFromJson({
        'widgetId': 'widget_2',
        'displayName': 'Widget 2',
        'template': {'type': 'B'},
      });

      final specs = registry.widgetSpecs;

      expect(specs.length, 2);
      expect(specs.map((s) => s.id), containsAll(['widget_1', 'widget_2']));
    });

    test('clear removes all widgets', () {
      registry.registerFromJson({
        'widgetId': 'w1',
        'template': {'type': 'A'}
      });
      registry.registerFromJson({
        'widgetId': 'w2',
        'template': {'type': 'B'}
      });

      registry.clear();

      expect(registry.length, 0);
      expect(registry.widgetIds, isEmpty);
    });

    test('later registration overwrites earlier', () {
      registry.registerFromJson({
        'widgetId': 'widget',
        'displayName': 'Version 1',
        'template': {'type': 'A'},
      });
      registry.registerFromJson({
        'widgetId': 'widget',
        'displayName': 'Version 2',
        'template': {'type': 'B'},
      });

      expect(registry.length, 1);
      expect(registry.get('widget')?.displayName, 'Version 2');
    });
  });
}
