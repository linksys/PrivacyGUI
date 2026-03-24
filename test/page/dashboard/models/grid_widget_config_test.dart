import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/grid_widget_config.dart';

void main() {
  const base = GridWidgetConfig(
    widgetId: 'device_info',
    order: 1,
    visible: true,
    displayMode: DisplayMode.normal,
    columnSpan: 6,
  );

  group('copyWith', () {
    test('updates widgetId', () {
      final result = base.copyWith(widgetId: 'topology');
      expect(result.widgetId, 'topology');
    });

    test('updates order', () {
      final result = base.copyWith(order: 5);
      expect(result.order, 5);
    });

    test('updates visible', () {
      final result = base.copyWith(visible: false);
      expect(result.visible, isFalse);
    });

    test('updates displayMode', () {
      final result = base.copyWith(displayMode: DisplayMode.compact);
      expect(result.displayMode, DisplayMode.compact);
    });

    test('updates columnSpan', () {
      final noSpan = GridWidgetConfig(widgetId: 'a', order: 0);
      final result = noSpan.copyWith(columnSpan: 8);
      expect(result.columnSpan, 8);
    });

    test('clearColumnSpan=true sets null', () {
      final result = base.copyWith(clearColumnSpan: true);
      expect(result.columnSpan, isNull);
    });

    test('preserves existing columnSpan when clearColumnSpan=false', () {
      final result = base.copyWith(clearColumnSpan: false);
      expect(result.columnSpan, 6);
    });

    test('preserves unspecified fields', () {
      final result = base.copyWith(visible: false);
      expect(result.widgetId, 'device_info');
      expect(result.order, 1);
      expect(result.displayMode, DisplayMode.normal);
      expect(result.columnSpan, 6);
    });
  });

  group('toJson', () {
    test('includes all base fields', () {
      final json = base.toJson();
      expect(json['widgetId'], 'device_info');
      expect(json['order'], 1);
      expect(json['visible'], true);
      expect(json['displayMode'], 'normal');
    });

    test('includes columnSpan when not null', () {
      final json = base.toJson();
      expect(json.containsKey('columnSpan'), isTrue);
      expect(json['columnSpan'], 6);
    });

    test('excludes columnSpan when null', () {
      const noSpan = GridWidgetConfig(widgetId: 'a', order: 0);
      final json = noSpan.toJson();
      expect(json.containsKey('columnSpan'), isFalse);
    });
  });

  group('fromJson', () {
    test('deserializes complete object', () {
      final json = {
        'widgetId': 'topology',
        'order': 3,
        'visible': false,
        'displayMode': 'compact',
        'columnSpan': 8,
      };
      final result = GridWidgetConfig.fromJson(json);
      expect(result.widgetId, 'topology');
      expect(result.order, 3);
      expect(result.visible, isFalse);
      expect(result.displayMode, DisplayMode.compact);
      expect(result.columnSpan, 8);
    });

    test('defaults order=0 when missing', () {
      final json = {'widgetId': 'a'};
      final result = GridWidgetConfig.fromJson(json);
      expect(result.order, 0);
    });

    test('defaults visible=true when missing', () {
      final json = {'widgetId': 'a'};
      final result = GridWidgetConfig.fromJson(json);
      expect(result.visible, isTrue);
    });

    test('defaults displayMode=normal when missing', () {
      final json = {'widgetId': 'a'};
      final result = GridWidgetConfig.fromJson(json);
      expect(result.displayMode, DisplayMode.normal);
    });

    test('JSON round-trip preserves data', () {
      final json = base.toJson();
      final restored = GridWidgetConfig.fromJson(json);
      expect(restored, equals(base));
    });
  });
}
