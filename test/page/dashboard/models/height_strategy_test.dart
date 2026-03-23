import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/models/height_strategy.dart';

void main() {
  group('IntrinsicHeightStrategy', () {
    test('factory constructor creates IntrinsicHeightStrategy', () {
      final strategy = HeightStrategy.intrinsic();
      expect(strategy, isA<IntrinsicHeightStrategy>());
    });

    test('equality returns true for same type', () {
      final a = HeightStrategy.intrinsic();
      final b = HeightStrategy.intrinsic();
      expect(a, equals(b));
    });

    test('hashCode is consistent across instances', () {
      final a = HeightStrategy.intrinsic();
      final b = HeightStrategy.intrinsic();
      expect(a.hashCode, equals(b.hashCode));
    });

    test('is not equal to other strategy types', () {
      final intrinsic = HeightStrategy.intrinsic();
      final columnBased = HeightStrategy.columnBased(1.0);
      expect(intrinsic, isNot(equals(columnBased)));
    });
  });

  group('ColumnBasedHeightStrategy', () {
    test('factory constructor stores multiplier', () {
      final strategy = HeightStrategy.columnBased(2.5);
      expect(strategy, isA<ColumnBasedHeightStrategy>());
      expect((strategy as ColumnBasedHeightStrategy).multiplier, 2.5);
    });

    test('strict factory is alias for ColumnBased', () {
      final strategy = HeightStrategy.strict(3);
      expect(strategy, isA<ColumnBasedHeightStrategy>());
      expect((strategy as ColumnBasedHeightStrategy).multiplier, 3.0);
    });

    test('equality returns true for same multiplier', () {
      final a = HeightStrategy.columnBased(2.0);
      final b = HeightStrategy.columnBased(2.0);
      expect(a, equals(b));
    });

    test('inequality for different multipliers', () {
      final a = HeightStrategy.columnBased(2.0);
      final b = HeightStrategy.columnBased(2.5);
      expect(a, isNot(equals(b)));
    });

    test('hashCode differs for different multipliers', () {
      final a = HeightStrategy.columnBased(2.0);
      final b = HeightStrategy.columnBased(3.0);
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('AspectRatioHeightStrategy', () {
    test('factory constructor stores ratio', () {
      final strategy = HeightStrategy.aspectRatio(1.78);
      expect(strategy, isA<AspectRatioHeightStrategy>());
      expect((strategy as AspectRatioHeightStrategy).ratio, 1.78);
    });

    test('equality returns true for same ratio', () {
      final a = HeightStrategy.aspectRatio(1.78);
      final b = HeightStrategy.aspectRatio(1.78);
      expect(a, equals(b));
    });

    test('inequality for different ratios', () {
      final a = HeightStrategy.aspectRatio(16 / 9);
      final b = HeightStrategy.aspectRatio(4 / 3);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent for same ratio', () {
      final a = HeightStrategy.aspectRatio(1.5);
      final b = HeightStrategy.aspectRatio(1.5);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('Cross-type comparison', () {
    test('ColumnBased is not equal to AspectRatio', () {
      final columnBased = HeightStrategy.columnBased(1.0);
      final aspectRatio = HeightStrategy.aspectRatio(1.0);
      expect(columnBased, isNot(equals(aspectRatio)));
    });

    test('pattern matching distinguishes all types', () {
      final strategies = <HeightStrategy>[
        HeightStrategy.intrinsic(),
        HeightStrategy.columnBased(2.0),
        HeightStrategy.aspectRatio(1.5),
      ];

      final types = strategies.map((s) => switch (s) {
            IntrinsicHeightStrategy() => 'intrinsic',
            ColumnBasedHeightStrategy() => 'columnBased',
            AspectRatioHeightStrategy() => 'aspectRatio',
          });

      expect(types, ['intrinsic', 'columnBased', 'aspectRatio']);
    });
  });
}
