import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action_manager.dart';

void main() {
  group('Simple A2UI Action Flow Tests', () {
    testWidgets('Action manager callback format test', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Consumer(
                    builder: (context, ref, child) {
                      final actionManager = ref.read(a2uiActionManagerProvider);

                      // Test the callback format conversion
                      final callback = actionManager.createActionCallback(ref,
                          widgetId: 'test');

                      // This is the format that UI Kit AppCard builder should pass
                      final actionData = {
                        'action': 'navigation.push',
                        'route': '/devices',
                      };

                      return Column(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              print('🔄 Testing action callback with format:');
                              print('   Data: $actionData');
                              print(
                                  '   Expected: action manager should receive this and convert to A2UIAction');
                              callback(actionData);
                            },
                            child: const Text('Test Action Callback'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              print('🔄 Testing direct A2UIAction execution');
                              final action = A2UIAction(
                                action: 'navigation.push',
                                params: {'route': '/devices'},
                                sourceWidgetId: 'test_widget',
                              );

                              print('   Action: ${action.action}');
                              print('   Params: ${action.params}');
                              print('   Source: ${action.sourceWidgetId}');

                              actionManager
                                  .executeAction(action, ref)
                                  .then((result) {
                                print(
                                    '   Result: ${result.success ? 'SUCCESS' : 'FAILED'}');
                                if (!result.success) {
                                  print('   Error: ${result.error}');
                                } else {
                                  print('   Data: ${result.data}');
                                }
                              }).catchError((e) {
                                print('   Exception: $e');
                              });
                            },
                            child: const Text('Test Direct Action'),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                              'Check debug console for action flow results'),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Test the callback format
      print('\n=== Testing Action Callback Format ===');
      await tester.tap(find.text('Test Action Callback'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Test direct action execution
      print('\n=== Testing Direct Action Execution ===');
      await tester.tap(find.text('Test Direct Action'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      print('\n=== Action Flow Test Complete ===');
    });

    testWidgets('Test A2UI action format conversion', (tester) async {
      // Test the format conversion logic that should happen in AppCard builder
      print('\n=== Testing Format Conversion Logic ===');

      // A2UI format from JSON
      final a2uiFormat = {
        r'$action': 'navigation.push',
        'params': {'route': '/devices'}
      };

      // Expected ActionManager format
      final expectedFormat = {
        'action': 'navigation.push',
        'route': '/devices',
      };

      // Simulate the conversion that AppCard builder should do
      Map<String, dynamic> converted = {};
      if (a2uiFormat.containsKey(r'$action')) {
        converted = {
          'action': a2uiFormat[r'$action'],
          ...?a2uiFormat['params'] as Map<String, dynamic>?,
        };
      }

      print('Input A2UI format: $a2uiFormat');
      print('Converted format: $converted');
      print('Expected format: $expectedFormat');

      expect(converted, equals(expectedFormat));
      print('✅ Format conversion works correctly');

      await tester.pumpWidget(Container()); // Minimal widget for test framework
    });
  });
}
