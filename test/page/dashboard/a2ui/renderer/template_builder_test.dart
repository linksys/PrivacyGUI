import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_template.dart';
import 'package:privacy_gui/page/dashboard/a2ui/renderer/template_builder.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/data_path_resolver.dart';

/// Mock DataPathResolver for testing
class MockDataPathResolver implements DataPathResolver {
  final Map<String, dynamic> _values;

  MockDataPathResolver([Map<String, dynamic>? values]) : _values = values ?? {};

  @override
  dynamic resolve(String path) => _values[path];

  @override
  ProviderListenable<dynamic>? watch(String path) => null;
}

void main() {
  group('TemplateBuilder', () {
    late MockDataPathResolver resolver;

    setUp(() {
      resolver = MockDataPathResolver({
        'router.deviceCount': 5,
        'router.nodeCount': 3,
        'wifi.ssid': 'TestNetwork',
      });
    });

    testWidgets('builds Column widget', (tester) async {
      final template = A2UIContainerNode(
        type: 'Column',
        properties: const {'mainAxisAlignment': 'center'},
        children: const [
          A2UILeafNode(type: 'SizedBox', properties: {'height': 10.0}),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('builds Row widget', (tester) async {
      final template = A2UIContainerNode(
        type: 'Row',
        properties: const {'mainAxisAlignment': 'spaceBetween'},
        children: const [
          A2UILeafNode(type: 'SizedBox', properties: {'width': 10.0}),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('builds Text with static value', (tester) async {
      const template = A2UILeafNode(
        type: 'AppText',
        properties: {'text': 'Hello World'},
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('builds Text with bound value', (tester) async {
      const template = A2UILeafNode(
        type: 'AppText',
        properties: {
          'text': {r'$bind': 'router.deviceCount'},
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('builds Icon widget', (tester) async {
      const template = A2UILeafNode(
        type: 'AppIcon',
        properties: {'icon': 'devices', 'size': 24.0},
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byIcon(Icons.devices), findsOneWidget);
    });

    testWidgets('builds SizedBox widget', (tester) async {
      const template = A2UILeafNode(
        type: 'SizedBox',
        properties: {'width': 100.0, 'height': 50.0},
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 100.0);
      expect(sizedBox.height, 50.0);
    });

    testWidgets('builds Center widget', (tester) async {
      final template = A2UIContainerNode(
        type: 'Center',
        children: const [
          A2UILeafNode(type: 'AppText', properties: {'text': 'Centered'}),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
      expect(find.text('Centered'), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink for unknown type', (tester) async {
      const template = A2UILeafNode(type: 'UnknownWidget');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      // SizedBox.shrink creates a SizedBox with 0x0 size
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, 0.0);
      expect(sizedBox.height, 0.0);
    });

    testWidgets('handles missing bound value gracefully', (tester) async {
      const template = A2UILeafNode(
        type: 'AppText',
        properties: {
          'text': {r'$bind': 'nonexistent.path'},
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => TemplateBuilder.build(
                template: template,
                resolver: resolver,
                ref: ref,
              ),
            ),
          ),
        ),
      );

      // Should display empty string for missing bound value
      expect(find.text(''), findsOneWidget);
    });
  });
}
