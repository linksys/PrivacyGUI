import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';
import 'package:privacy_gui/page/dashboard/models/widget_grid_constraints.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';
import 'package:privacy_gui/page/dashboard/providers/layout_item_factory.dart';

void main() {
  group('LayoutItemFactory', () {
    const testConstraints = WidgetGridConstraints(
      minColumns: 2,
      maxColumns: 6,
      preferredColumns: 4,
      heightStrategy: HeightStrategy.intrinsic(),
      minHeightRows: 2,
      maxHeightRows: 8,
    );

    const testSpec = WidgetSpec(
      id: 'test_widget',
      displayName: 'Test Widget',
      constraints: {
        DisplayMode.normal: testConstraints,
      },
    );

    test('fromSpec converts WidgetSpec to LayoutItem correctly', () {
      final item = LayoutItemFactory.fromSpec(
        testSpec,
        x: 0,
        y: 1,
        displayMode: DisplayMode.normal,
      );

      expect(item.id, 'test_widget');
      expect(item.x, 0);
      expect(item.y, 1);

      // Defaults to preferredColumns (4) and preferredHeight (intrinsic -> minHeightRows 2 clipped to [2,4] -> 2)
      // wait intrinsic default logic in WidgetGridConstraints.getPreferredHeightCells was minHeightRows.clamp(2,6) -> 2.clamp(2,6) = 2
      expect(item.w, 4);
      expect(item.h, 2);

      expect(item.minW, 2);
      expect(item.maxW, 6.0);
      expect(item.minH, 2);
      expect(item.maxH, 8.0);
    });

    test('fromSpec allows overriding w/h (Scenario A - Manual Override)', () {
      final item = LayoutItemFactory.fromSpec(
        testSpec,
        x: 0,
        y: 1,
        w: 6,
        h: 5,
        displayMode: DisplayMode.normal,
      );

      expect(item.w, 6);
      expect(item.h, 5);

      // Constraints remain from spec
      expect(item.minW, 2);
      expect(item.maxW, 6.0);
    });

    test('fromSpec falls back to default if constraints missing', () {
      const missingConstraintsSpec = WidgetSpec(
        id: 'missing',
        displayName: 'Missing',
        constraints: {}, // No constraints for normal mode
      );

      final item = LayoutItemFactory.fromSpec(missingConstraintsSpec,
          x: 0, y: 0, displayMode: DisplayMode.normal);

      expect(item.w, 4); // Fallback default
      expect(item.h, 2); // Fallback default
    });

    group('Default Layout Generation', () {
      // Since createDefaultLayout uses hardcoded DashboardWidgetSpecs keys,
      // we can mainly verify the structure and presence of key items.
      // We can also test the resolver injection.

      test('createDefaultLayout returns items with correct override logic', () {
        // We just want to ensure it runs without error and returns non-empty list
        // And check specific overrides where we know they happen (e.g. InternetStatus h=2)

        final layout = LayoutItemFactory.createDefaultLayout();
        expect(layout, isNotEmpty);

        // Internet Status Check (Row 0, Col 0, W4, H2)
        final internet =
            layout.firstWhere((i) => i.id == 'internet_status_only');
        expect(internet.x, 0);
        expect(internet.y, 0);
        expect(internet.w, 4);
        expect(internet.h, 2,
            reason: "Designer override should force height 2");

        // Master Node (Row 0, Col 4, W4, H4)
        final master = layout.firstWhere((i) => i.id == 'master_node_info');
        expect(master.x, 4);
        expect(master.y, 0);
        expect(master.h, 4);
      });

      test('createDefaultLayout uses specResolver for injection', () {
        // Mock a resolver that changes constraints for one widget
        // We'll mimic the Ports widget dynamic change case

        const modifiedConstraints = WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 12,
          preferredColumns: 8, // Force wider
          heightStrategy: HeightStrategy.intrinsic(),
        );

        WidgetSpec myResolver(WidgetSpec spec) {
          if (spec.id == 'ports') {
            return WidgetSpec(
                id: spec.id,
                displayName: spec.displayName,
                constraints: {DisplayMode.normal: modifiedConstraints});
          }
          return spec;
        }

        final layout =
            LayoutItemFactory.createDefaultLayout(specResolver: myResolver);
        final ports = layout.firstWhere((i) => i.id == 'ports');

        // It should use our injected constraint's preferredColumns
        expect(ports.w, 8);
      });
    });
  });
}
