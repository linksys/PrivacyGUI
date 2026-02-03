import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';

void main() {
  test('Validate all A2UI JSON files', () async {
    final dir = Directory('assets/a2ui/widgets');
    final files =
        dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'));

    for (final file in files) {
      print('Validating ${file.path}...');
      final content = await file.readAsString();
      final json = jsonDecode(content);

      // Verify parsing
      try {
        final def = A2UIWidgetDefinition.fromJson(json);
        expect(def.widgetId, isNotEmpty);
      } catch (e) {
        fail('Failed to parse ${file.path}: $e');
      }
    }
  });
}
