import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_template.dart';

void main() {
  group('A2UITemplateNode', () {
    test('creates leaf node from JSON', () {
      final json = {
        'type': 'AppText',
        'props': {'text': 'Hello', 'variant': 'headline'},
      };

      final node = A2UITemplateNode.fromJson(json);

      expect(node, isA<A2UILeafNode>());
      expect(node.type, 'AppText');
      expect(node.properties['text'], 'Hello');
      expect(node.properties['variant'], 'headline');
    });

    test('creates container node from JSON with children', () {
      final json = {
        'type': 'Column',
        'props': {'mainAxisAlignment': 'center'},
        'children': [
          {
            'type': 'AppText',
            'props': {'text': 'Child 1'}
          },
          {
            'type': 'AppText',
            'props': {'text': 'Child 2'}
          },
        ],
      };

      final node = A2UITemplateNode.fromJson(json);

      expect(node, isA<A2UIContainerNode>());
      expect(node.type, 'Column');
      expect(node.properties['mainAxisAlignment'], 'center');

      final container = node as A2UIContainerNode;
      expect(container.children.length, 2);
      expect(container.children[0].properties['text'], 'Child 1');
      expect(container.children[1].properties['text'], 'Child 2');
    });

    test('handles empty props', () {
      final json = {'type': 'SizedBox'};

      final node = A2UITemplateNode.fromJson(json);

      expect(node.type, 'SizedBox');
      expect(node.properties, isEmpty);
    });

    test('defaults to Container type when type is missing', () {
      final node = A2UITemplateNode.fromJson({});

      expect(node.type, 'Container');
    });
  });

  group('A2UIPropValue', () {
    test('creates static value from primitive', () {
      final value = A2UIPropValue.fromJson('Hello');

      expect(value, isA<A2UIStaticValue>());
      expect((value as A2UIStaticValue).value, 'Hello');
    });

    test('creates static value from number', () {
      final value = A2UIPropValue.fromJson(42);

      expect(value, isA<A2UIStaticValue>());
      expect((value as A2UIStaticValue).value, 42);
    });

    test('creates bound value from \$bind syntax', () {
      final value = A2UIPropValue.fromJson({r'$bind': 'router.deviceCount'});

      expect(value, isA<A2UIBoundValue>());
      expect((value as A2UIBoundValue).path, 'router.deviceCount');
    });

    test('treats maps without \$bind as static values', () {
      final value = A2UIPropValue.fromJson({'key': 'value'});

      expect(value, isA<A2UIStaticValue>());
    });
  });

  group('A2UIContainerNode', () {
    test('equality includes children', () {
      final a = A2UIContainerNode(
        type: 'Column',
        children: const [
          A2UILeafNode(type: 'AppText'),
        ],
      );
      final b = A2UIContainerNode(
        type: 'Column',
        children: const [
          A2UILeafNode(type: 'AppText'),
        ],
      );
      final c = A2UIContainerNode(
        type: 'Column',
        children: const [
          A2UILeafNode(type: 'AppIcon'),
        ],
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
