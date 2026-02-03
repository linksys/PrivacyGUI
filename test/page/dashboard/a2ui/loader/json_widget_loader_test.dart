import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/loader/json_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';

void main() {
  // Initialize Flutter testing binding
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JsonWidgetLoader', () {
    late JsonWidgetLoader loader;
    late List<String> loadedAssets;

    setUp(() {
      loader = JsonWidgetLoader();
      loadedAssets = [];
    });

    tearDown(() {
      // Evict all known assets to ensure clean state, regardless of tracking
      final knownAssets = [
        'AssetManifest.json',
        'assets/a2ui/widgets/device_count.json',
        'assets/a2ui/widgets/node_count.json',
        'assets/a2ui/widgets/wan_status.json',
        'assets/a2ui/widgets/custom_widget.json',
      ];

      for (final asset in knownAssets) {
        rootBundle.evict(asset);
      }

      // Also evict tracked assets just in case
      for (final asset in loadedAssets) {
        rootBundle.evict(asset);
      }

      // Reset the asset bundle behavior
      _resetAssetBundle();
    });

    group('loadAll', () {
      test('uses fallback when AssetManifest.json is not available', () async {
        // Setup: AssetManifest.json will throw error, but fallback works
        _setupFallbackScenario(loadedAssets);

        final widgets = await loader.loadAll();

        expect(widgets.length, 3);
        expect(widgets.any((w) => w.widgetId == 'a2ui_device_count'), isTrue);
        expect(widgets.any((w) => w.widgetId == 'a2ui_node_count'), isTrue);
        expect(widgets.any((w) => w.widgetId == 'a2ui_wan_status'), isTrue);

        print('DEBUG: loadedAssets: $loadedAssets');
        print('DEBUG: widgets: ${widgets.map((w) => w.widgetId).toList()}');

        // Verify fallback files were loaded
        expect(loadedAssets, contains('assets/a2ui/widgets/device_count.json'));
        expect(loadedAssets, contains('assets/a2ui/widgets/node_count.json'));
        expect(loadedAssets, contains('assets/a2ui/widgets/wan_status.json'));
      });

      test('uses dynamic discovery when AssetManifest.json is available',
          () async {
        // Setup: AssetManifest.json available with additional widgets
        _setupDynamicDiscoveryScenario(loadedAssets);

        final widgets = await loader.loadAll();

        expect(widgets.length, 4); // 3 standard + 1 extra
        expect(widgets.any((w) => w.widgetId == 'a2ui_device_count'), isTrue);
        expect(widgets.any((w) => w.widgetId == 'a2ui_node_count'), isTrue);
        expect(widgets.any((w) => w.widgetId == 'a2ui_wan_status'), isTrue);
        expect(widgets.any((w) => w.widgetId == 'a2ui_custom_widget'), isTrue);

        // Verify AssetManifest was loaded
        expect(loadedAssets, contains('AssetManifest.json'));
      });

      test('handles partial loading failures gracefully', () async {
        // Setup: One file missing, others valid
        _setupPartialFailureScenario(loadedAssets);

        final widgets = await loader.loadAll();

        expect(widgets.length, 2); // Only 2 successful loads
        expect(widgets.any((w) => w.widgetId == 'a2ui_device_count'), isTrue);
        expect(widgets.any((w) => w.widgetId == 'a2ui_wan_status'), isTrue);
        expect(widgets.any((w) => w.widgetId == 'a2ui_node_count'), isFalse);
      });

      test('handles malformed JSON gracefully', () async {
        _setupMalformedJsonScenario(loadedAssets);

        final widgets = await loader.loadAll();

        expect(widgets.length, 1); // Only 1 valid JSON
        expect(widgets.first.widgetId, 'a2ui_device_count');
      });

      test('handles empty JSON gracefully', () async {
        _setupEmptyJsonScenario(loadedAssets);

        final widgets = await loader.loadAll();

        expect(widgets, isEmpty);
      });

      test('handles missing required fields in JSON', () async {
        _setupIncompleteJsonScenario(loadedAssets);

        final widgets = await loader.loadAll();

        expect(widgets.length, 1); // Only complete widget loads
        expect(widgets.first.widgetId, 'a2ui_device_count');
      });

      test('loads widgets in sorted order', () async {
        _setupAssetManifestWithUnsortedWidgets(loadedAssets);
        _setupValidWidgetAssets(loadedAssets);
        _setupExtraWidgetAssets(loadedAssets);

        final widgets = await loader.loadAll();

        // Verify loading order matches sorted filenames
        expect(widgets.length, 4);
        // Files should be loaded in alphabetical order
        final expectedOrder = [
          'a2ui_custom_widget', // custom_widget.json comes first alphabetically
          'a2ui_device_count', // device_count.json
          'a2ui_node_count', // node_count.json
          'a2ui_wan_status', // wan_status.json
        ];

        for (int i = 0; i < expectedOrder.length; i++) {
          expect(widgets[i].widgetId, expectedOrder[i]);
        }
      });
    });

    group('getDiscoveredFiles', () {
      test('returns dynamic files when manifest available', () async {
        _setupAssetManifestWithExtraWidgets();

        final files = await loader.getDiscoveredFiles();

        expect(files.length, 4);
        expect(files, contains('device_count.json'));
        expect(files, contains('node_count.json'));
        expect(files, contains('wan_status.json'));
        expect(files, contains('custom_widget.json'));
      });

      test('returns fallback files when manifest unavailable', () async {
        _setupAssetManifestUnavailable();

        final files = await loader.getDiscoveredFiles();

        expect(files.length, 3);
        expect(files, contains('device_count.json'));
        expect(files, contains('node_count.json'));
        expect(files, contains('wan_status.json'));
      });

      test('handles discovery errors gracefully', () async {
        _setupAssetManifestWithInvalidContent();

        final files = await loader.getDiscoveredFiles();

        // Should fall back to hardcoded list
        expect(files.length, 3);
        expect(files, contains('device_count.json'));
        expect(files, contains('node_count.json'));
        expect(files, contains('wan_status.json'));
      });
    });

    group('validateAssetStructure', () {
      test('reports manifest available when accessible', () async {
        _setupManifestAndValidAssets();

        final info = await loader.validateAssetStructure();

        expect(info.manifestAvailable, isTrue);
        expect(info.discoveredFiles.length, 4);
        expect(info.hasAvailableAssets, isTrue);
        expect(info.availableFileCount, 4);
      });

      test('reports manifest unavailable when not accessible', () async {
        _setupAssetManifestUnavailable();
        _setupValidWidgetAssets();

        final info = await loader.validateAssetStructure();

        expect(info.manifestAvailable, isFalse);
        expect(info.discoveredFiles, isEmpty);
        expect(info.hasAvailableAssets, isTrue); // Fallback files available
        expect(info.availableFileCount, 3); // All fallback files accessible
      });

      test('reports partial fallback availability', () async {
        _setupAssetManifestUnavailable();
        _setupPartiallyValidWidgetAssets();

        final info = await loader.validateAssetStructure();

        expect(info.manifestAvailable, isFalse);
        expect(info.hasAvailableAssets, isTrue);
        expect(info.availableFileCount, 2); // Only 2 fallback files available
        expect(info.fallbackAvailability['device_count.json'], isTrue);
        expect(info.fallbackAvailability['node_count.json'], isFalse);
        expect(info.fallbackAvailability['wan_status.json'], isTrue);
      });

      test('generates informative summary', () async {
        _setupAssetManifestUnavailable();
        _setupValidWidgetAssets();

        final info = await loader.validateAssetStructure();

        final summary = info.summary;
        expect(summary, contains('AssetManifest available: false'));
        expect(summary, contains('Discovered files: 0'));
        expect(summary, contains('Fallback files available: 3/3'));
        expect(summary, contains('Total available: 3'));
      });
    });

    group('error handling and resilience', () {
      test('continues loading when one file fails', () async {
        _setupAssetManifestUnavailable();
        // Setup where middle file throws exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) {
          final String key = _decodeMessage(message);

          if (key == 'assets/a2ui/widgets/device_count.json') {
            return Future.value(_createAssetResponse(_validDeviceCountJson));
          } else if (key == 'assets/a2ui/widgets/node_count.json') {
            return Future.error(PlatformException(
                code: 'asset_not_found', message: 'Asset not found'));
          } else if (key == 'assets/a2ui/widgets/wan_status.json') {
            return Future.value(_createAssetResponse(_validWanStatusJson));
          }
          return Future.error(PlatformException(
              code: 'asset_not_found', message: 'Asset not found'));
        });

        final widgets = await loader.loadAll();

        expect(widgets.length, 2);
        expect(widgets.any((w) => w.widgetId == 'a2ui_device_count'), isTrue);
        expect(widgets.any((w) => w.widgetId == 'a2ui_wan_status'), isTrue);
      });

      test('handles completely unavailable assets', () async {
        _setupAssetManifestUnavailable();
        _setupNoAssets();

        final widgets = await loader.loadAll();

        expect(widgets, isEmpty);
      });

      test('handles network timeout-like errors', () async {
        _setupAssetManifestUnavailable();
        // Simulate network timeout
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', (message) {
          return Future.error(PlatformException(
              code: 'network_error', message: 'Connection timeout'));
        });

        final widgets = await loader.loadAll();

        expect(widgets, isEmpty);
      });
    });
  });
}

// Test data constants
const String _validDeviceCountJson = '''
{
  "widgetId": "a2ui_device_count",
  "displayName": "Connected Devices",
  "constraints": {
    "minColumns": 2,
    "maxColumns": 4,
    "preferredColumns": 3,
    "minRows": 2,
    "maxRows": 3,
    "preferredRows": 2
  },
  "template": {
    "type": "Column",
    "properties": {"mainAxisAlignment": "center"},
    "children": []
  }
}
''';

const String _validNodeCountJson = '''
{
  "widgetId": "a2ui_node_count",
  "displayName": "Mesh Nodes",
  "constraints": {
    "minColumns": 2,
    "maxColumns": 4,
    "preferredColumns": 3,
    "minRows": 2,
    "maxRows": 3,
    "preferredRows": 2
  },
  "template": {
    "type": "Column",
    "properties": {"mainAxisAlignment": "center"},
    "children": []
  }
}
''';

const String _validWanStatusJson = '''
{
  "widgetId": "a2ui_wan_status",
  "displayName": "WAN Status",
  "constraints": {
    "minColumns": 2,
    "maxColumns": 4,
    "preferredColumns": 3,
    "minRows": 1,
    "maxRows": 2,
    "preferredRows": 1
  },
  "template": {
    "type": "Row",
    "properties": {"mainAxisAlignment": "center"},
    "children": []
  }
}
''';

const String _validCustomWidgetJson = '''
{
  "widgetId": "a2ui_custom_widget",
  "displayName": "Custom Widget",
  "constraints": {
    "minColumns": 1,
    "maxColumns": 6,
    "preferredColumns": 3,
    "minRows": 1,
    "maxRows": 4,
    "preferredRows": 2
  },
  "template": {
    "type": "Container",
    "properties": {},
    "children": []
  }
}
''';

const String _malformedJson = '''
{
  "widgetId": "malformed",
  "displayName": "Malformed Widget"
  // Missing closing brace and constraints
''';

const String _incompleteJson = '''
{
  "displayName": "Incomplete Widget"
  // Missing widgetId and other required fields
}
''';

// Helper functions for test setup
void _mockAssetBundle([List<String>? loadedAssets]) {
  // This function now just initializes the tracking list
  // Actual mock setup is done in individual test setup functions
  loadedAssets?.clear();
}

void _resetAssetBundle() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', null);
}

ByteData _createAssetResponse(String content) {
  final bytes = utf8.encode(content);
  final byteData = ByteData(bytes.length);
  for (int i = 0; i < bytes.length; i++) {
    byteData.setUint8(i, bytes[i]);
  }
  return byteData;
}

String _decodeMessage(ByteData? message) {
  if (message == null) return '';
  final bytes =
      message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes);
  return utf8.decode(bytes);
}

void _setupAssetManifestUnavailable([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.error(PlatformException(
          code: 'asset_not_found', message: 'AssetManifest.json not found'));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupValidWidgetAssets([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.value(_createAssetResponse(_validNodeCountJson));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_validWanStatusJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupManifestAndValidAssets() {
  final manifest = {
    'assets/a2ui/widgets/device_count.json': [
      'assets/a2ui/widgets/device_count.json'
    ],
    'assets/a2ui/widgets/node_count.json': [
      'assets/a2ui/widgets/node_count.json'
    ],
    'assets/a2ui/widgets/wan_status.json': [
      'assets/a2ui/widgets/wan_status.json'
    ],
    'assets/a2ui/widgets/custom_widget.json': [
      'assets/a2ui/widgets/custom_widget.json'
    ],
  };

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);

    if (key == 'AssetManifest.json') {
      return Future.value(_createAssetResponse(jsonEncode(manifest)));
    }

    if (key.endsWith('device_count.json')) {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    }
    if (key.endsWith('node_count.json')) {
      return Future.value(_createAssetResponse(_validNodeCountJson));
    }
    if (key.endsWith('wan_status.json')) {
      return Future.value(_createAssetResponse(_validWanStatusJson));
    }
    if (key.endsWith('custom_widget.json')) {
      return Future.value(_createAssetResponse(
          '{ "id": "custom_widget", "type": "overview_tile" }'));
    }

    return Future.error(PlatformException(
        code: 'asset_not_found', message: 'Asset not found: $key'));
  });
}

void _setupAssetManifestWithExtraWidgets([List<String>? loadedAssets]) {
  final manifest = {
    'assets/a2ui/widgets/device_count.json': [
      'assets/a2ui/widgets/device_count.json'
    ],
    'assets/a2ui/widgets/node_count.json': [
      'assets/a2ui/widgets/node_count.json'
    ],
    'assets/a2ui/widgets/wan_status.json': [
      'assets/a2ui/widgets/wan_status.json'
    ],
    'assets/a2ui/widgets/custom_widget.json': [
      'assets/a2ui/widgets/custom_widget.json'
    ],
  };

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.value(_createAssetResponse(jsonEncode(manifest)));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupExtraWidgetAssets([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      final manifest = {
        'assets/a2ui/widgets/device_count.json': [
          'assets/a2ui/widgets/device_count.json'
        ],
        'assets/a2ui/widgets/node_count.json': [
          'assets/a2ui/widgets/node_count.json'
        ],
        'assets/a2ui/widgets/wan_status.json': [
          'assets/a2ui/widgets/wan_status.json'
        ],
        'assets/a2ui/widgets/custom_widget.json': [
          'assets/a2ui/widgets/custom_widget.json'
        ],
      };
      return Future.value(_createAssetResponse(jsonEncode(manifest)));
    } else if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.value(_createAssetResponse(_validNodeCountJson));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_validWanStatusJson));
    } else if (key == 'assets/a2ui/widgets/custom_widget.json') {
      return Future.value(_createAssetResponse(_validCustomWidgetJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupPartiallyValidWidgetAssets([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.error(PlatformException(
          code: 'asset_not_found', message: 'Asset not found'));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_validWanStatusJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupMalformedWidgetAssets([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.value(_createAssetResponse(_malformedJson));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_malformedJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupEmptyWidgetAssets([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key.startsWith('assets/a2ui/widgets/')) {
      return Future.value(_createAssetResponse('')); // Empty content
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupIncompleteWidgetAssets([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.value(_createAssetResponse(_incompleteJson));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_incompleteJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupAssetManifestWithUnsortedWidgets([List<String>? loadedAssets]) {
  final manifest = {
    // Intentionally unsorted to test sorting behavior
    'assets/a2ui/widgets/wan_status.json': [
      'assets/a2ui/widgets/wan_status.json'
    ],
    'assets/a2ui/widgets/device_count.json': [
      'assets/a2ui/widgets/device_count.json'
    ],
    'assets/a2ui/widgets/custom_widget.json': [
      'assets/a2ui/widgets/custom_widget.json'
    ],
    'assets/a2ui/widgets/node_count.json': [
      'assets/a2ui/widgets/node_count.json'
    ],
  };

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.value(_createAssetResponse(jsonEncode(manifest)));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupAssetManifestWithInvalidContent([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.value(_createAssetResponse('invalid json content'));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupNoAssets([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    return Future.error(PlatformException(
        code: 'asset_not_found', message: 'No assets available'));
  });
}

// Comprehensive setup functions for complete test scenarios
void _setupFallbackScenario([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.error(PlatformException(
          code: 'asset_not_found', message: 'AssetManifest.json not found'));
    } else if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.value(_createAssetResponse(_validNodeCountJson));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_validWanStatusJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupDynamicDiscoveryScenario([List<String>? loadedAssets]) {
  final manifest = {
    'assets/a2ui/widgets/device_count.json': [
      'assets/a2ui/widgets/device_count.json'
    ],
    'assets/a2ui/widgets/node_count.json': [
      'assets/a2ui/widgets/node_count.json'
    ],
    'assets/a2ui/widgets/wan_status.json': [
      'assets/a2ui/widgets/wan_status.json'
    ],
    'assets/a2ui/widgets/custom_widget.json': [
      'assets/a2ui/widgets/custom_widget.json'
    ],
  };

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.value(_createAssetResponse(jsonEncode(manifest)));
    } else if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.value(_createAssetResponse(_validNodeCountJson));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_validWanStatusJson));
    } else if (key == 'assets/a2ui/widgets/custom_widget.json') {
      return Future.value(_createAssetResponse(_validCustomWidgetJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupPartialFailureScenario([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.error(PlatformException(
          code: 'asset_not_found', message: 'AssetManifest.json not found'));
    } else if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.error(PlatformException(
          code: 'asset_not_found', message: 'Asset not found'));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_validWanStatusJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupMalformedJsonScenario([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.error(PlatformException(
          code: 'asset_not_found', message: 'AssetManifest.json not found'));
    } else if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.value(_createAssetResponse(_malformedJson));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_malformedJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupEmptyJsonScenario([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.error(PlatformException(
          code: 'asset_not_found', message: 'AssetManifest.json not found'));
    } else if (key.startsWith('assets/a2ui/widgets/')) {
      return Future.value(_createAssetResponse('')); // Empty content
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}

void _setupIncompleteJsonScenario([List<String>? loadedAssets]) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) {
    final String key = _decodeMessage(message);
    loadedAssets?.add(key);

    if (key == 'AssetManifest.json') {
      return Future.error(PlatformException(
          code: 'asset_not_found', message: 'AssetManifest.json not found'));
    } else if (key == 'assets/a2ui/widgets/device_count.json') {
      return Future.value(_createAssetResponse(_validDeviceCountJson));
    } else if (key == 'assets/a2ui/widgets/node_count.json') {
      return Future.value(_createAssetResponse(_incompleteJson));
    } else if (key == 'assets/a2ui/widgets/wan_status.json') {
      return Future.value(_createAssetResponse(_incompleteJson));
    }

    return Future.error(
        PlatformException(code: 'asset_not_found', message: 'Asset not found'));
  });
}
