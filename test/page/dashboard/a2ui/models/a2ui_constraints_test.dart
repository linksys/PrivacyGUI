import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_constraints.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';

void main() {
  group('A2UIConstraints', () {
    test('creates from constructor', () {
      const constraints = A2UIConstraints(
        minColumns: 2,
        maxColumns: 6,
        preferredColumns: 4,
        minRows: 1,
        maxRows: 3,
        preferredRows: 2,
      );

      expect(constraints.minColumns, 2);
      expect(constraints.maxColumns, 6);
      expect(constraints.preferredColumns, 4);
      expect(constraints.minRows, 1);
      expect(constraints.maxRows, 3);
      expect(constraints.preferredRows, 2);
    });

    test('creates from JSON', () {
      final json = {
        'minColumns': 3,
        'maxColumns': 8,
        'preferredColumns': 5,
        'minRows': 2,
        'maxRows': 4,
        'preferredRows': 3,
      };

      final constraints = A2UIConstraints.fromJson(json);

      expect(constraints.minColumns, 3);
      expect(constraints.maxColumns, 8);
      expect(constraints.preferredColumns, 5);
      expect(constraints.minRows, 2);
      expect(constraints.maxRows, 4);
      expect(constraints.preferredRows, 3);
    });

    test('uses default values when JSON is incomplete', () {
      final constraints = A2UIConstraints.fromJson({});

      expect(constraints.minColumns, 2);
      expect(constraints.maxColumns, 12);
      expect(constraints.preferredColumns, 4);
      expect(constraints.minRows, 1);
      expect(constraints.maxRows, 12);
      expect(constraints.preferredRows, 2);
    });

    test('converts to WidgetGridConstraints', () {
      const constraints = A2UIConstraints(
        minColumns: 2,
        maxColumns: 6,
        preferredColumns: 4,
        minRows: 1,
        maxRows: 3,
        preferredRows: 2,
      );

      final gridConstraints = constraints.toGridConstraints();

      expect(gridConstraints.minColumns, 2);
      expect(gridConstraints.maxColumns, 6);
      expect(gridConstraints.preferredColumns, 4);
      expect(gridConstraints.minHeightRows, 1);
      expect(gridConstraints.maxHeightRows, 3);
    });

    test('converts to JSON', () {
      const constraints = A2UIConstraints(
        minColumns: 2,
        maxColumns: 6,
        preferredColumns: 4,
        minRows: 1,
        maxRows: 3,
        preferredRows: 2,
      );

      final json = constraints.toJson();

      expect(json['minColumns'], 2);
      expect(json['maxColumns'], 6);
      expect(json['preferredColumns'], 4);
      expect(json['minRows'], 1);
      expect(json['maxRows'], 3);
      expect(json['preferredRows'], 2);
    });

    test('equality works correctly', () {
      const a = A2UIConstraints(
        minColumns: 2,
        maxColumns: 6,
        preferredColumns: 4,
        minRows: 1,
        maxRows: 3,
        preferredRows: 2,
      );
      const b = A2UIConstraints(
        minColumns: 2,
        maxColumns: 6,
        preferredColumns: 4,
        minRows: 1,
        maxRows: 3,
        preferredRows: 2,
      );
      const c = A2UIConstraints(
        minColumns: 3,
        maxColumns: 6,
        preferredColumns: 4,
        minRows: 1,
        maxRows: 3,
        preferredRows: 2,
      );

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
