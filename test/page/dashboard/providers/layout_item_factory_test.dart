import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';
import 'package:privacy_gui/page/dashboard/models/widget_grid_constraints.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';

const _normalConstraints = WidgetGridConstraints(
  minColumns: 3,
  maxColumns: 8,
  preferredColumns: 6,
  heightStrategy: HeightStrategy.strict(3),
  minHeightRows: 2,
  maxHeightRows: 8,
);

const _testSpec = WidgetSpec(
  id: 'test_widget',
  displayName: 'Test Widget',
  constraints: {DisplayMode.normal: _normalConstraints},
);

void main() {
  group('fromSpec — valid constraints', () {
    test('LayoutItem.id matches spec.id', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0);
      expect(item.id, 'test_widget');
    });

    test('uses provided x and y', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 5, y: 10);
      expect(item.x, 5);
      expect(item.y, 10);
    });

    test('uses provided w override', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0, w: 8);
      expect(item.w, 8);
    });

    test('uses provided h override', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0, h: 4);
      expect(item.h, 4);
    });

    test('defaults w to preferredColumns', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0);
      expect(item.w, _normalConstraints.preferredColumns);
    });

    test('defaults h from HeightStrategy', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0);
      final expectedH = _normalConstraints.getPreferredHeightCells(
        columns: _normalConstraints.preferredColumns,
      );
      expect(item.h, expectedH);
    });

    test('sets minW from spec minColumns', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0);
      expect(item.minW, _normalConstraints.minColumns);
    });

    test('sets maxW from spec maxColumns as double', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0);
      expect(item.maxW, _normalConstraints.maxColumns.toDouble());
    });

    test('sets minH from spec minHeightRows', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0);
      expect(item.minH, _normalConstraints.minHeightRows);
    });

    test('sets maxH from spec maxHeightRows as double', () {
      final item = LayoutItemFactory.fromSpec(_testSpec, x: 0, y: 0);
      expect(item.maxH, _normalConstraints.maxHeightRows.toDouble());
    });
  });

  group('fromSpec — null constraints fallback', () {
    const specNoConstraints = WidgetSpec(
      id: 'no_constraints',
      displayName: 'No Constraints',
      constraints: {},
    );

    test('returns fallback w=4 h=2', () {
      final item = LayoutItemFactory.fromSpec(
        specNoConstraints,
        x: 0,
        y: 0,
        displayMode: DisplayMode.compact,
      );
      expect(item.w, 4);
      expect(item.h, 2);
    });

    test('fallback uses provided x and y', () {
      final item = LayoutItemFactory.fromSpec(
        specNoConstraints,
        x: 3,
        y: 7,
        displayMode: DisplayMode.compact,
      );
      expect(item.x, 3);
      expect(item.y, 7);
    });
  });
}
