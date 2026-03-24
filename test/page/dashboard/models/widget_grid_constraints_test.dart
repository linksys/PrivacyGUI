import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';
import 'package:privacy_gui/page/dashboard/models/widget_grid_constraints.dart';

/// Helper to create a valid constraint with sensible defaults.
WidgetGridConstraints _make({
  int minColumns = 3,
  int maxColumns = 8,
  int preferredColumns = 6,
  HeightStrategy heightStrategy = const HeightStrategy.strict(3),
  int minHeightRows = 1,
  int maxHeightRows = 12,
}) {
  return WidgetGridConstraints(
    minColumns: minColumns,
    maxColumns: maxColumns,
    preferredColumns: preferredColumns,
    heightStrategy: heightStrategy,
    minHeightRows: minHeightRows,
    maxHeightRows: maxHeightRows,
  );
}

void main() {
  group('Constructor assertions', () {
    test('rejects minColumns < 1', () {
      expect(
        () => _make(minColumns: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects minColumns > 12', () {
      expect(
        () => _make(minColumns: 13, maxColumns: 13, preferredColumns: 13),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects maxColumns < minColumns', () {
      expect(
        () => _make(minColumns: 5, maxColumns: 4, preferredColumns: 4),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects maxColumns > 12', () {
      expect(
        () => _make(maxColumns: 13, preferredColumns: 6),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects preferredColumns < minColumns', () {
      expect(
        () => _make(minColumns: 4, preferredColumns: 3),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects preferredColumns > maxColumns', () {
      expect(
        () => _make(maxColumns: 8, preferredColumns: 9),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects maxHeightRows < minHeightRows', () {
      expect(
        () => _make(minHeightRows: 5, maxHeightRows: 3),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts valid constraint set', () {
      expect(
        () => _make(
          minColumns: 3,
          maxColumns: 8,
          preferredColumns: 6,
          minHeightRows: 2,
          maxHeightRows: 8,
        ),
        returnsNormally,
      );
    });
  });

  group('scaleToMaxColumns', () {
    test('preferred=6 on 12 scales to 4 on 8', () {
      final c = _make(preferredColumns: 6);
      expect(c.scaleToMaxColumns(8), 4);
    });

    test('preferred=12 on 12 scales to 8 on 8', () {
      final c = _make(
        minColumns: 6,
        maxColumns: 12,
        preferredColumns: 12,
      );
      expect(c.scaleToMaxColumns(8), 8);
    });

    test('preferred=6 on 12 scales to 2 on 4', () {
      final c = _make(preferredColumns: 6);
      expect(c.scaleToMaxColumns(4), 2);
    });

    test('clamps to minimum 1', () {
      final c = _make(minColumns: 1, preferredColumns: 1, maxColumns: 12);
      final result = c.scaleToMaxColumns(4);
      expect(result, greaterThanOrEqualTo(1));
    });
  });

  group('scaleMinToMaxColumns', () {
    test('min=3 on 12 scales to 2 on 8', () {
      final c = _make(minColumns: 3);
      expect(c.scaleMinToMaxColumns(8), 2);
    });

    test('min=1 on 12 stays 1 on 4', () {
      final c = _make(minColumns: 1, preferredColumns: 1, maxColumns: 8);
      expect(c.scaleMinToMaxColumns(4), greaterThanOrEqualTo(1));
    });

    test('min=6 on 12 scales to 2 on 4', () {
      final c = _make(minColumns: 6, preferredColumns: 6);
      expect(c.scaleMinToMaxColumns(4), 2);
    });
  });

  group('scaleMaxToMaxColumns', () {
    test('max=8 on 12 scales proportionally to 8', () {
      final c = _make(maxColumns: 8);
      final result = c.scaleMaxToMaxColumns(8);
      // 8 * 8 / 12 = 5.33 → rounds to 5
      expect(result, 5);
    });

    test('max=12 on 12 scales to 4 on 4', () {
      final c = _make(maxColumns: 12, preferredColumns: 6);
      expect(c.scaleMaxToMaxColumns(4), 4);
    });

    test('clamps to minimum 1', () {
      final c = _make(minColumns: 1, maxColumns: 1, preferredColumns: 1);
      final result = c.scaleMaxToMaxColumns(4);
      expect(result, greaterThanOrEqualTo(1));
    });
  });

  group('getPreferredHeightCells', () {
    test('ColumnBased multiplier=2.3 returns 3', () {
      final c = _make(heightStrategy: HeightStrategy.columnBased(2.3));
      expect(c.getPreferredHeightCells(), 3);
    });

    test('ColumnBased multiplier=5.0 returns 5', () {
      final c = _make(heightStrategy: HeightStrategy.columnBased(5.0));
      expect(c.getPreferredHeightCells(), 5);
    });

    test('AspectRatio with columns parameter', () {
      final c = _make(heightStrategy: HeightStrategy.aspectRatio(16 / 9));
      // 6 / (16/9) = 3.375 → ceil = 4
      final result = c.getPreferredHeightCells(columns: 6);
      expect(result, 4);
    });

    test('AspectRatio clamps to min 1 for very wide ratio', () {
      final c = _make(heightStrategy: HeightStrategy.aspectRatio(100.0));
      // 6 / 100 = 0.06 → ceil = 1, clamp(1,12) = 1
      expect(c.getPreferredHeightCells(), 1);
    });

    test('AspectRatio clamps to max 12 for very tall ratio', () {
      final c = _make(heightStrategy: HeightStrategy.aspectRatio(0.01));
      // 6 / 0.01 = 600 → ceil = 600, clamp(1,12) = 12
      expect(c.getPreferredHeightCells(), 12);
    });

    test('Intrinsic clamps minHeightRows=1 to 2', () {
      final c = _make(
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 1,
      );
      expect(c.getPreferredHeightCells(), 2);
    });

    test('Intrinsic with minHeightRows=3 returns 3', () {
      final c = _make(
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 3,
      );
      expect(c.getPreferredHeightCells(), 3);
    });

    test('Intrinsic clamps minHeightRows=8 to 6', () {
      final c = _make(
        heightStrategy: HeightStrategy.intrinsic(),
        minHeightRows: 8,
        maxHeightRows: 12,
      );
      expect(c.getPreferredHeightCells(), 6);
    });
  });

  group('getHeightRange', () {
    test('returns minHeightRows as double', () {
      final c = _make(minHeightRows: 2, maxHeightRows: 8);
      final (min, _) = c.getHeightRange();
      expect(min, 2.0);
    });

    test('returns maxHeightRows as double', () {
      final c = _make(minHeightRows: 2, maxHeightRows: 8);
      final (_, max) = c.getHeightRange();
      expect(max, 8.0);
    });
  });

  group('Equality and hashCode', () {
    test('equal constraints are equal', () {
      final a = _make();
      final b = _make();
      expect(a, equals(b));
    });

    test('different minColumns are not equal', () {
      final a = _make(minColumns: 3);
      final b = _make(minColumns: 4);
      expect(a, isNot(equals(b)));
    });

    test('different maxColumns are not equal', () {
      final a = _make(maxColumns: 8);
      final b = _make(maxColumns: 10);
      expect(a, isNot(equals(b)));
    });

    test('different preferredColumns are not equal', () {
      final a = _make(preferredColumns: 6);
      final b = _make(preferredColumns: 7);
      expect(a, isNot(equals(b)));
    });

    test('different heightStrategy are not equal', () {
      final a = _make(heightStrategy: HeightStrategy.strict(3));
      final b = _make(heightStrategy: HeightStrategy.intrinsic());
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      final a = _make();
      final b = _make();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('default minHeightRows=1 and maxHeightRows=12', () {
      final c = WidgetGridConstraints(
        minColumns: 3,
        maxColumns: 8,
        preferredColumns: 6,
        heightStrategy: HeightStrategy.strict(3),
      );
      expect(c.minHeightRows, 1);
      expect(c.maxHeightRows, 12);
    });

    test('accepts valid full constraint set with all params', () {
      expect(
        () => WidgetGridConstraints(
          minColumns: 2,
          maxColumns: 10,
          preferredColumns: 6,
          heightStrategy: HeightStrategy.aspectRatio(1.5),
          minHeightRows: 2,
          maxHeightRows: 8,
        ),
        returnsNormally,
      );
    });
  });
}
