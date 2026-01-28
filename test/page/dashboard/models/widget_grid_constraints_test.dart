import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';
import 'package:privacy_gui/page/dashboard/models/widget_grid_constraints.dart';

void main() {
  group('WidgetGridConstraints', () {
    test('Constructor assertions enforce 12-column limits', () {
      expect(
        () => WidgetGridConstraints(
            minColumns: 0,
            maxColumns: 12,
            preferredColumns: 4,
            heightStrategy: const HeightStrategy.intrinsic()),
        throwsAssertionError,
        reason: 'minColumns cannot be < 1',
      );
      expect(
        () => WidgetGridConstraints(
            minColumns: 13,
            maxColumns: 12,
            preferredColumns: 4,
            heightStrategy: const HeightStrategy.intrinsic()),
        throwsAssertionError,
        reason: 'minColumns cannot be > 12',
      );
      expect(
        () => WidgetGridConstraints(
            minColumns: 4,
            maxColumns: 2,
            preferredColumns: 4,
            heightStrategy: const HeightStrategy.intrinsic()),
        throwsAssertionError,
        reason: 'maxColumns cannot be less than minColumns',
      );
      expect(
        () => WidgetGridConstraints(
            minColumns: 2,
            maxColumns: 4,
            preferredColumns: 6,
            heightStrategy: const HeightStrategy.intrinsic()),
        throwsAssertionError,
        reason: 'preferredColumns must be within min/max range',
      );
    });

    group('Scaling logic (Based on 12-column system)', () {
      final constraints = WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 6,
        preferredColumns: 4,
        heightStrategy: const HeightStrategy.intrinsic(),
      );

      test('scaleToMaxColumns translates preferred width correctly', () {
        // Desktop (12 cols) -> Should remain 4
        expect(constraints.scaleToMaxColumns(12), 4);
        // Tablet (8 cols) -> 4 * 8 / 12 = 2.66 -> round to 3
        expect(constraints.scaleToMaxColumns(8), 3);
        // Mobile (4 cols) -> 4 * 4 / 12 = 1.33 -> round to 1
        expect(constraints.scaleToMaxColumns(4), 1);
      });

      test('scaleMinToMaxColumns translates minimum width correctly', () {
        // Desktop (12 cols) -> min 3
        expect(constraints.scaleMinToMaxColumns(12), 3);
        // Tablet (8 cols) -> 3 * 8 / 12 = 2
        expect(constraints.scaleMinToMaxColumns(8), 2);
        // Mobile (4 cols) -> 3 * 4 / 12 = 1
        expect(constraints.scaleMinToMaxColumns(4), 1);
      });

      test('scaleMaxToMaxColumns translates maximum width correctly', () {
        // Desktop (12 cols) -> max 6
        expect(constraints.scaleMaxToMaxColumns(12), 6);
        // Tablet (8 cols) -> 6 * 8 / 12 = 4
        expect(constraints.scaleMaxToMaxColumns(8), 4);
        // Mobile (4 cols) -> 6 * 4 / 12 = 2
        expect(constraints.scaleMaxToMaxColumns(4), 2);
      });

      test('Scaling should clamp to 1 at minimum', () {
        final smallConstraints = WidgetGridConstraints(
          minColumns: 1,
          maxColumns: 2,
          preferredColumns: 1,
          heightStrategy: const HeightStrategy.intrinsic(),
        );
        // Scale 1 to 4 cols: 1 * 4 / 12 = 0.33 -> round to 0 -> clamp to 1
        expect(smallConstraints.scaleToMaxColumns(4), 1);
      });
    });

    group('HeightStrategy calculations via getPreferredHeightCells', () {
      test('Strict (ColumnBased) Strategy returns fixed rows', () {
        const strictStrategy = HeightStrategy.strict(4); // multiplier 4
        final constr = WidgetGridConstraints(
          minColumns: 1,
          maxColumns: 4,
          preferredColumns: 2,
          heightStrategy: strictStrategy,
        );

        // ColumnBasedHeightStrategy logic: multiplier.ceil()
        // Wait, looking at the code:
        // ColumnBasedHeightStrategy(:final multiplier) => multiplier.ceil()
        // It seems the strategy implementation in getPreferredHeightCells ignores 'columns' input
        // and strictly uses the multiplier as the height in cells?
        // Let's verify source code behavior.
        // Source: `return switch (heightStrategy) { ColumnBasedHeightStrategy(:final multiplier) => multiplier.ceil(), ... }`
        // Yes, it returns multiplier.ceil().

        expect(constr.getPreferredHeightCells(), 4);
      });

      test('AspectRatio Strategy calculates height based on columns', () {
        const ratioStrategy =
            HeightStrategy.aspectRatio(2.0); // W/H = 2, so H = W/2
        final constr = WidgetGridConstraints(
          minColumns: 1,
          maxColumns: 12,
          preferredColumns: 4,
          heightStrategy: ratioStrategy,
        );

        // AspectRatio logic: (cols / ratio).ceil().clamp(1, 12)
        // With default preferredColumns = 4:
        // H = ceil(4 / 2.0) = 2
        expect(constr.getPreferredHeightCells(), 2);

        // With explicit columns input (e.g. resized width to 6)
        // H = ceil(6 / 2.0) = 3
        expect(constr.getPreferredHeightCells(columns: 6), 3);

        // With explicit columns input (e.g. resized width to 9)
        // H = ceil(9 / 2.0) = ceil(4.5) = 5
        expect(constr.getPreferredHeightCells(columns: 9), 5);
      });

      test('Intrinsic Strategy returns clamped default range', () {
        const intrinsic = HeightStrategy.intrinsic();
        final constr = WidgetGridConstraints(
          minColumns: 1,
          maxColumns: 4,
          preferredColumns: 2,
          heightStrategy: intrinsic,
          minHeightRows: 1,
        );

        // Source logic: minHeightRows.clamp(2, 6)
        // If minHeightRows is 1, it clamps to 2.
        expect(constr.getPreferredHeightCells(), 2);
      });

      test('Intrinsic Strategy respects minHeightRows if > 2', () {
        const intrinsic = HeightStrategy.intrinsic();
        final constr = WidgetGridConstraints(
          minColumns: 1,
          maxColumns: 4,
          preferredColumns: 2,
          heightStrategy: intrinsic,
          minHeightRows: 4,
        );
        // minHeightRows is 4, so it should return 4
        expect(constr.getPreferredHeightCells(), 4);
      });
    });

    test('getHeightRange returns correct min/max logic', () {
      final constr = WidgetGridConstraints(
        minColumns: 1,
        maxColumns: 4,
        preferredColumns: 2,
        heightStrategy: const HeightStrategy.intrinsic(),
        minHeightRows: 3,
        maxHeightRows: 8,
      );

      final (minH, maxH) = constr.getHeightRange();
      expect(minH, 3.0);
      expect(maxH, 8.0);
    });

    test('Equality and HashCode', () {
      final c1 = WidgetGridConstraints(
        minColumns: 2,
        maxColumns: 4,
        preferredColumns: 3,
        heightStrategy: const HeightStrategy.intrinsic(),
      );
      final c2 = WidgetGridConstraints(
        minColumns: 2,
        maxColumns: 4,
        preferredColumns: 3,
        heightStrategy: const HeightStrategy.intrinsic(),
      );
      final c3 = WidgetGridConstraints(
        minColumns: 2,
        maxColumns: 4,
        preferredColumns: 3,
        heightStrategy: const HeightStrategy.strict(4),
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });
}
