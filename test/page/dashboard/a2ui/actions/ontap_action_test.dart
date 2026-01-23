import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/actions/a2ui_action.dart';

void main() {
  group('OnTap Action Format Conversion Tests', () {
    test('A2UI action format should convert to action manager format', () {
      // This tests the conceptual conversion logic used in AppCard builder

      // Input: A2UI action format from JSON
      final a2uiActionData = {
        r'$action': 'navigation.push',
        'params': {
          'route': '/devices'
        }
      };

      // Expected output: Action manager format
      final expectedActionData = {
        'action': 'navigation.push',
        'route': '/devices',
      };

      // Simulate the conversion logic from AppCard builder
      Map<String, dynamic> convertedData = {};
      if (a2uiActionData.containsKey(r'$action')) {
        convertedData = {
          'action': a2uiActionData[r'$action'],
          ...?a2uiActionData['params'] as Map<String, dynamic>?,
        };
      }

      // Verify conversion
      expect(convertedData['action'], equals('navigation.push'));
      expect(convertedData['route'], equals('/devices'));
      expect(convertedData, equals(expectedActionData));

      print('✅ A2UI action format conversion verified:');
      print('   Input:  ${a2uiActionData}');
      print('   Output: ${convertedData}');
    });

    test('A2UIAction can be created from converted data', () {
      // Simulate action manager receiving converted data
      final actionData = {
        'action': 'navigation.push',
        'route': '/devices',
      };

      // Create A2UIAction (simulating action manager logic)
      final action = A2UIAction(
        action: actionData['action'] as String,
        params: Map<String, dynamic>.from(actionData)..remove('action'),
        sourceWidgetId: 'a2ui_device_count',
      );

      expect(action.action, equals('navigation.push'));
      expect(action.params['route'], equals('/devices'));
      expect(action.sourceWidgetId, equals('a2ui_device_count'));

      print('✅ A2UIAction creation verified:');
      print('   Action: ${action.action}');
      print('   Params: ${action.params}');
      print('   Source: ${action.sourceWidgetId}');
    });

    test('Handle missing params gracefully', () {
      // Test action without params
      final a2uiActionData = {
        r'$action': 'router.restart',
        // No params
      };

      Map<String, dynamic> convertedData = {};
      if (a2uiActionData.containsKey(r'$action')) {
        convertedData = {
          'action': a2uiActionData[r'$action'],
          ...?a2uiActionData['params'] as Map<String, dynamic>?,
        };
      }

      expect(convertedData['action'], equals('router.restart'));
      expect(convertedData.keys, hasLength(1)); // Only 'action' key

      print('✅ Missing params handled gracefully:');
      print('   Input:  ${a2uiActionData}');
      print('   Output: ${convertedData}');
    });

    test('Multiple navigation actions format correctly', () {
      final testCases = [
        {
          'input': {r'$action': 'navigation.push', 'params': {'route': '/devices'}},
          'expected': {'action': 'navigation.push', 'route': '/devices'},
        },
        {
          'input': {r'$action': 'navigation.push', 'params': {'route': '/network-settings'}},
          'expected': {'action': 'navigation.push', 'route': '/network-settings'},
        },
        {
          'input': {r'$action': 'navigation.push', 'params': {'route': '/mesh-network'}},
          'expected': {'action': 'navigation.push', 'route': '/mesh-network'},
        },
      ];

      for (final testCase in testCases) {
        final input = testCase['input'] as Map<String, dynamic>;
        final expected = testCase['expected'] as Map<String, dynamic>;

        Map<String, dynamic> converted = {};
        if (input.containsKey(r'$action')) {
          converted = {
            'action': input[r'$action'],
            ...?input['params'] as Map<String, dynamic>?,
          };
        }

        expect(converted, equals(expected));
      }

      print('✅ All navigation actions format correctly');
    });
  });
}