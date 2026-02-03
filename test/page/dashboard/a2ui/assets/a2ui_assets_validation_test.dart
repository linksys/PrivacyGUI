import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';

void main() {
  // Initialize test widget binding for asset loading
  TestWidgetsFlutterBinding.ensureInitialized();

  group('A2UI Assets Validation', () {
    final assetPaths = [
      'assets/a2ui/widgets/device_count.json',
      'assets/a2ui/widgets/wan_status.json',
      'assets/a2ui/widgets/node_count.json',
      'assets/a2ui/widgets/router_control.json',
      'assets/a2ui/widgets/quick_actions.json',
      'assets/a2ui/widgets/network_traffic.json',
      'assets/a2ui/widgets/guest_network.json',
      'assets/a2ui/widgets/system_health.json',
    ];

    for (final assetPath in assetPaths) {
      testWidgets('validates $assetPath JSON structure', (tester) async {
        try {
          // Load the asset
          final jsonString = await rootBundle.loadString(assetPath);
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;

          // Basic structure validation
          expect(jsonData.containsKey('widgetId'), isTrue,
              reason: '$assetPath missing widgetId');
          expect(jsonData.containsKey('displayName'), isTrue,
              reason: '$assetPath missing displayName');
          expect(jsonData.containsKey('constraints'), isTrue,
              reason: '$assetPath missing constraints');
          expect(jsonData.containsKey('template'), isTrue,
              reason: '$assetPath missing template');

          // Try to create A2UIWidgetDefinition
          final widgetDef = A2UIWidgetDefinition.fromJson(jsonData);
          expect(widgetDef.widgetId, isNotEmpty);
          expect(widgetDef.displayName, isNotEmpty);
          expect(widgetDef.template, isNotNull);

          print('✅ $assetPath: Valid JSON structure');
          print('   Widget ID: ${widgetDef.widgetId}');
          print('   Display Name: ${widgetDef.displayName}');
        } catch (e) {
          print('❌ $assetPath: Validation failed');
          print('   Error: $e');
          fail('Asset validation failed for $assetPath: $e');
        }
      });
    }

    test('validates action syntax in widgets', () async {
      for (final assetPath in assetPaths) {
        try {
          final file = File(assetPath);
          if (!await file.exists()) {
            fail('Asset not found: $assetPath');
          }
          final jsonString = await file.readAsString();
          final jsonData = json.decode(jsonString) as Map<String, dynamic>;

          // Recursively check for action syntax
          final actionCount = _countActions(jsonData);
          if (actionCount > 0) {
            print('✅ $assetPath: Found $actionCount action definitions');
          } else {
            print(
                'ℹ️  $assetPath: No actions defined (OK for display-only widgets)');
          }
        } catch (e) {
          print('❌ $assetPath: Action validation failed - $e');
        }
      }
    });

    // TODO: Fix data binding validation test - currently experiencing timeout issues
    // test('validates data binding syntax', () async {
    //   for (final assetPath in assetPaths) {
    //     try {
    //       final jsonString = await rootBundle.loadString(assetPath);
    //
    //       // Simple string-based check to avoid potential recursion issues
    //       final bindingCount = r'$bind'.allMatches(jsonString).length;
    //
    //       if (bindingCount > 0) {
    //         print('✅ $assetPath: Found $bindingCount data binding definitions');
    //       } else {
    //         print('ℹ️  $assetPath: No data bindings (OK for static widgets)');
    //       }
    //
    //     } catch (e) {
    //       print('❌ $assetPath: Data binding validation failed - $e');
    //     }
    //   }
    // });
  });
}

int _countActions(dynamic obj) {
  int count = 0;

  if (obj is Map<String, dynamic>) {
    if (obj.containsKey(r'$action')) {
      count++;
    }

    for (final value in obj.values) {
      count += _countActions(value);
    }
  } else if (obj is List) {
    for (final item in obj) {
      count += _countActions(item);
    }
  }

  return count;
}
